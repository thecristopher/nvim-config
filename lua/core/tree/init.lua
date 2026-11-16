-- The explorer dressed by the franchise: neo-tree's guides and folders come from skin.tree, a
-- folder that is a room of :Map with errors or TODOs left inside carries the skin's mark, files
-- carry their open review threads and ground messages, and the file just saved glows and fades.
-- bufferline's offset over the tree is its one title. Everything slow (the map survey) is
-- gathered in the background, rendering only reads what is cached.
local actions = require("core.tree.actions")

local M = {}

-- how long a survey stays fresh before a render asks for another one
local SURVEY_TTL_MS = 10000
local DIAGNOSTICS_DEBOUNCE_MS = 500
local FRESH_MS = 1200

-- repo root -> { gathered, rooms, surveyed_at, surveying, messages }
local repos = {}
-- folder path -> repo root, false when the folder is outside any repo
local roots = {}
local fresh = { path = nil, base = nil }
local diagnostics_timer

local function skin_tree()
  return require("core.skin").current().tree
end

local function define_highlights()
  local p = require("core.themes").palette()
  local groups = {
    EldenTreeLeft = { fg = p.red, bold = true },
    EldenTreeThread = { fg = p.sapphire, italic = true },
    EldenTreeMessage = { fg = p.peach },
    -- bufferline's offset over the tree, its one title
    EldenTreeTitle = { fg = p.yellow, bg = p.base, bold = true },
    EldenTreeFresh = { fg = p.yellow, bold = true },
  }
  for name, attrs in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

--- Redraws every filesystem tree, without reading the disk again.
function M.redraw()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok then
    pcall(manager.redraw, "filesystem")
  end
end

local function root_of(path)
  if roots[path] == nil then
    local root = vim.fs.root(path, ".git")
    roots[path] = root and vim.fs.normalize(root) or false
  end
  return roots[path] or nil
end

local function repo(root)
  repos[root] = repos[root] or {}
  return repos[root]
end

local function read_messages(root)
  local ok, entries = pcall(require("core.messages").entries, root)
  repo(root).messages = actions.count_by_file(ok and entries or {}, "file")
end

local function survey(root)
  local entry = repo(root)
  if entry.surveying then
    return
  end
  entry.surveying = true
  require("core.map").survey_async(root, function(gathered)
    entry.surveying = false
    entry.surveyed_at = vim.uv.now()
    entry.gathered = gathered
    local rooms = require("core.map").rooms_from(root, gathered)
    if vim.deep_equal(rooms, entry.rooms) then
      return
    end
    entry.rooms = rooms
    M.redraw()
  end)
end

-- a render only reads the cache, and starts a background survey when it went stale
local function known(root)
  local entry = repo(root)
  if not entry.messages then
    read_messages(root)
  end
  local stale = not entry.surveyed_at or vim.uv.now() - entry.surveyed_at > SURVEY_TTL_MS
  if stale then
    survey(root)
  end
  return entry
end

-- errors come and go faster than files, so the rooms are recounted from the survey already held
local function recount_errors()
  local changed = false
  for root, entry in pairs(repos) do
    if entry.gathered then
      local rooms = require("core.map").rooms_from(root, entry.gathered)
      changed = changed or not vim.deep_equal(rooms, entry.rooms)
      entry.rooms = rooms
    end
  end
  if changed then
    M.redraw()
  end
end

local function on_diagnostics()
  diagnostics_timer = diagnostics_timer or vim.uv.new_timer()
  diagnostics_timer:stop()
  diagnostics_timer:start(DIAGNOSTICS_DEBOUNCE_MS, 0, vim.schedule_wrap(recount_errors))
end

local function room_component(_, node, state)
  local root = root_of(state.path)
  if not root or node:get_depth() == 1 then
    return {}
  end
  local relative = actions.relative(root, vim.fs.normalize(node.path))
  local mark = actions.folder_mark(actions.folder_state(known(root).rooms, relative), skin_tree())
  return mark or {}
end

local function marks_component(_, node, state)
  local root = root_of(state.path)
  if not root then
    return {}
  end
  local entry = known(root)
  local threads = actions.count_by_file(require("core.threads").open_threads(root), "path")
  local relative = actions.relative(root, vim.fs.normalize(node.path))
  return actions.file_marks(relative, threads, entry.messages or {}, skin_tree())
end

-- the root shows the project's name, not a full path cut in half by the window edge, and the
-- file just saved wears the glow while it fades
local function name_component(config, node, state)
  local name = require("neo-tree.sources.common.components").name(config, node, state)
  if node:get_depth() == 1 and node.type ~= "message" then
    name.text = vim.fs.basename(node.path)
    return name
  end
  if fresh.path and vim.fs.normalize(node.path) == fresh.path then
    fresh.base = fresh.base or name.highlight
    name.highlight = "EldenTreeFresh"
  end
  return name
end

-- the skin is read on every render, so a franchise switch only needs a redraw. No expanders: the
-- open or closed folder already says it
local function indent_component(config, node, state)
  local tree = skin_tree()
  config.indent_marker = tree.indent
  config.last_indent_marker = tree.last
  return require("neo-tree.sources.common.components").indent(config, node, state)
end

local function icon_component(config, node, state)
  local folder = skin_tree().folder
  config.folder_closed = folder.closed
  config.folder_open = folder.open
  config.folder_empty = folder.empty
  config.folder_empty_open = folder.empty
  return require("neo-tree.sources.common.components").icon(config, node, state)
end

--- The components the filesystem source renders with, see lua/plugins/neo-tree.lua.
---@return table<string, function>
function M.components()
  return {
    name = name_component,
    indent = indent_component,
    icon = icon_component,
    eldentree_room = room_component,
    eldentree_marks = marks_component,
  }
end

--- Lights the file just saved in the tree and fades it back to its own color.
---@param path string absolute path of the saved file
function M.glow(path)
  fresh.path, fresh.base = path, nil
  define_highlights()
  M.redraw()
  -- the redraw remembered which group the name normally wears, the glow fades into it
  local target = vim.api.nvim_get_hl(0, { name = fresh.base or "NeoTreeFileName", link = false })
  require("core.motion").fade_hl("EldenTreeFresh", target, { duration = FRESH_MS })
  local glowing = path
  vim.defer_fn(function()
    if fresh.path == glowing then
      fresh.path, fresh.base = nil, nil
      M.redraw()
    end
  end, FRESH_MS + 100)
end

local function on_save(ev)
  if vim.bo[ev.buf].buftype ~= "" or ev.file == "" then
    return
  end
  local path = vim.fs.normalize(vim.api.nvim_buf_get_name(ev.buf))
  local root = root_of(vim.fs.dirname(path))
  if root then
    repo(root).surveyed_at = nil
  end
  if package.loaded["neo-tree"] then
    M.glow(path)
  end
end

local function on_messages()
  for root in pairs(repos) do
    read_messages(root)
  end
  M.redraw()
end

local function on_franchise()
  define_highlights()
  M.redraw()
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_tree", { clear = true })
  local function on(event, callback, pattern)
    vim.api.nvim_create_autocmd(event, { group = group, pattern = pattern, callback = callback })
  end
  on("ColorScheme", define_highlights)
  on("BufWritePost", on_save)
  on("DiagnosticChanged", on_diagnostics)
  on("DirChanged", function()
    roots = {}
  end)
  on("User", M.redraw, "EldentreeThreads")
  on("User", on_messages, "EldentreeMessages")
  on("User", on_franchise, { "EldentreeFranchise", "EldentreeRegionSettled" })
end

return M
