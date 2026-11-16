-- :Map opens the project map in a float: every top folder is a wing and every room a box in it, red
-- while errors or TODOs hide inside, blue once cleared, the room you stand in marked. Tab steps
-- between rooms and <CR> walks into one with the file picker.
local actions = require("core.map.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_map")

local function define_highlights()
  local p = require("core.themes").palette()
  local groups = {
    EldenMapLeft = { fg = p.red },
    EldenMapLeftName = { fg = p.red, bold = true },
    EldenMapCleared = { fg = p.sapphire },
    EldenMapClearedName = { fg = p.text, bold = true },
    EldenMapHere = { fg = p.yellow },
    EldenMapHereName = { fg = p.yellow, bold = true },
    EldenMapPath = { fg = p.overlay1, italic = true },
    EldenMapWing = { fg = p.subtext0, bold = true },
  }
  for name, attrs in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

local function git_lines(root, args)
  local result =
    vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(5000)
  return result.code == 0 and result.stdout or ""
end

local function open_errors()
  local errors = {}
  for _, diagnostic in ipairs(vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })) do
    local path = vim.api.nvim_buf_get_name(diagnostic.bufnr)
    errors[path] = (errors[path] or 0) + 1
  end
  return errors
end

local function survey(root)
  local files = vim.split(git_lines(root, { "ls-files" }), "\n", { trimempty = true })
  local todos = actions.parse_counts(git_lines(root, { "grep", "-I", "-c", "-E", "TODO|FIXME" }))
  return actions.rooms(root, files, todos, open_errors())
end

--- Gathers the files and TODO counts of a project in the background.
---@param root string repo root
---@param done fun(survey: { files: string[], todos: table<string, integer> })
function M.survey_async(root, done)
  local background = require("core.hud.background")
  background.git(root, { "ls-files" }, function(files)
    background.git(root, { "grep", "-I", "-c", "-E", "TODO|FIXME" }, function(lines)
      done({ files = files, todos = actions.parse_counts(table.concat(lines, "\n")) })
    end)
  end)
end

--- The rooms of a project from a survey gathered earlier, with the errors open right now.
---@param root string repo root
---@param gathered { files: string[], todos: table<string, integer> }
---@return table[]
function M.rooms_from(root, gathered)
  return actions.rooms(root, gathered.files, gathered.todos, open_errors())
end

-- the zone of the file you were in before opening the map, nil outside the project
local function here(root)
  local file = vim.api.nvim_buf_get_name(0)
  return file ~= "" and require("core.zones.actions").zone_key(vim.fs.normalize(file), root) or nil
end

local function paint(buf, drawn)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, drawn.lines)
  for _, mark in ipairs(drawn.marks) do
    vim.api.nvim_buf_set_extmark(
      buf,
      ns,
      mark.row,
      mark.col,
      { end_col = mark.end_col, hl_group = mark.group }
    )
  end
  vim.bo[buf].modifiable = false
end

-- moves the cursor onto the name of the next (or previous) room
local function step(win, drawn, direction)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local current = actions.room_at(drawn.rooms, cursor[1] - 1, cursor[2])
  local index = 0
  for at, spot in ipairs(drawn.rooms) do
    if spot.key == current then
      index = at
    end
  end
  local target = drawn.rooms[(index - 1 + direction) % #drawn.rooms + 1]
  vim.api.nvim_win_set_cursor(win, { target.row + 1, target.col + 2 })
end

local function map_keys(buf, win, drawn, root)
  local close = function()
    pcall(vim.api.nvim_win_close, win, true)
  end
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("<Tab>", function()
    step(win, drawn, 1)
  end)
  map("<S-Tab>", function()
    step(win, drawn, -1)
  end)
  map("<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local key = actions.room_at(drawn.rooms, cursor[1] - 1, cursor[2])
    if not key then
      return
    end
    close()
    Snacks.picker.files({ cwd = root .. "/" .. key })
  end)
end

local function open_float(rooms, root)
  local glyphs = require("core.skin").current().tree
  local here_key = here(root)
  local drawn = actions.layout(rooms, {
    width = math.max(20, vim.o.columns - 8),
    here = here_key,
    glyphs = { left = glyphs.left, cleared = glyphs.cleared },
  })
  local width = 20
  for _, line in ipairs(drawn.lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  width = math.min(width, vim.o.columns - 4)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  paint(buf, drawn)

  local cleared, total = actions.progress(rooms)
  local words = require("core.franchise").current().words
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = width,
    height = math.max(1, math.min(#drawn.lines, vim.o.lines - 6)),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2) - 1,
    title = " " .. require("core.skin").title(
      ("%s · %s"):format(words.map, require("core.themes").current().title)
    ) .. " ",
    title_pos = "center",
    footer = (" %d of %d rooms cleared "):format(cleared, total),
    footer_pos = "center",
  })
  map_keys(buf, win, drawn, root)
  -- the map opens on the room you stand in, or on the first one
  for _, spot in ipairs(drawn.rooms) do
    if spot.key == here_key then
      vim.api.nvim_win_set_cursor(win, { spot.row + 1, spot.col + 2 })
      return
    end
  end
  step(win, drawn, 1)
end

--- Returns the rooms of a project, red or blue, for anything else that wants to draw them.
---@param root string repo root
---@return table[]
function M.rooms(root)
  return survey(root)
end

--- Opens the map of the project you stand in.
function M.open()
  local root = require("core.repos").root()
  if not root then
    return vim.notify(
      "No map here, this folder is not in a repo",
      vim.log.levels.INFO,
      { title = "Map" }
    )
  end
  local rooms = survey(root)
  if #rooms == 0 then
    return vim.notify(
      "This project has no rooms yet, only files at its root",
      vim.log.levels.INFO,
      { title = "Map" }
    )
  end
  open_float(rooms, root)
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_map", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_user_command("Map", M.open, { desc = "Open the project map" })
end

return M
