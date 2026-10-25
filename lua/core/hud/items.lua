-- What fills the HUD's slots, gathered from the real workspace: the hub actions, recent files,
-- branches and stashes, ground messages, regions, projects and the rooms of the map.
-- Every item knows how to be used, checked (details for a float) and, where it makes sense, combined.
local M = {}

local function words() return require("core.franchise").current().words end

local function git(root, args)
  local result = vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(3000)
  return result.code == 0 and vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true }) or {}
end

local function run(action)
  if type(action) == "function" then return action() end
  vim.cmd((action:gsub("^:", "")))
end

local function file_icon(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then return "󰈔" end
  local icon, hl = devicons.get_icon(vim.fs.basename(path), vim.fn.fnamemodify(path, ":e"), { default = true })
  return icon, hl
end

local ACTION_DESCRIPTIONS = {
  f = "Search every file of the project by name.",
  g = "Search every line of the project for a pattern.",
  r = "Reopen something you had in your hands recently.",
  p = "Travel to another project, its session comes back with you.",
  e = "Open the file tree beside the code.",
  o = "Pick any folder on disk and make camp there.",
  n = "Start an empty buffer and write something new.",
  s = "Bring back the windows and buffers of your last visit here.",
  t = "Change the region, its colors and its champion.",
  c = "Look inside this very config.",
  L = "Open lazy.nvim, where every plugin lives.",
  m = "Open Mason, where the language servers come from.",
  q = "Close nvim.",
  a = "See every room of the project, red wherever work remains.",
}

--- The hub actions, the same keys every layout offers.
---@return table[]
function M.actions()
  return vim.tbl_map(function(key)
    return {
      icon = key.icon, name = key.desc, slot = key.slot, key = key.key,
      desc = ACTION_DESCRIPTIONS[key.key] or key.desc,
      use = function() run(key.action) end,
      check = function() return { key.desc, "", ACTION_DESCRIPTIONS[key.key] or "", "", "Key: " .. key.key } end,
    }
  end, require("core.hud.keys").keys())
end

local function file_details(path)
  local stat = vim.uv.fs_stat(path)
  return {
    vim.fs.basename(path), "",
    "Path      " .. vim.fn.fnamemodify(path, ":~"),
    "Size      " .. (stat and (math.ceil(stat.size / 1024) .. " KB") or "?"),
    "Modified  " .. (stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "?"),
  }
end

--- Files you had open lately, newest first.
---@param limit integer|nil
---@return table[]
function M.recent(limit)
  local items = {}
  for _, path in ipairs(vim.v.oldfiles) do
    if #items >= (limit or 24) then break end
    if vim.fn.filereadable(path) == 1 then
      local icon, hl = file_icon(path)
      table.insert(items, {
        icon = icon, icon_hl = hl, name = vim.fs.basename(path),
        desc = vim.fn.fnamemodify(path, ":~:."),
        use = function() vim.cmd.edit(vim.fn.fnameescape(path)) end,
        check = function() return file_details(path) end,
        combine = function() vim.cmd.vsplit(vim.fn.fnameescape(path)) end,
      })
    end
  end
  return items
end

local function switch_branch(root, branch)
  vim.system({ "git", "-C", root, "switch", branch }, { text = true }, vim.schedule_wrap(function(result)
    local ok = result.code == 0
    vim.notify(ok and ("Switched to " .. branch) or vim.trim(result.stderr), ok and vim.log.levels.INFO or vim.log.levels.WARN,
      { title = "Git" })
    require("core.hud").refresh()
  end))
end

local function branch_items(root)
  local current = require("core.repos").branch(root)
  local items = {}
  for _, line in ipairs(git(root, { "for-each-ref", "--sort=-committerdate", "--count=12",
    "--format=%(refname:short)\t%(committerdate:relative)", "refs/heads" })) do
    local branch, when = line:match("^(.-)\t(.*)$")
    local ahead = tonumber(git(root, { "rev-list", "--count", "HEAD.." .. branch })[1])
    table.insert(items, {
      icon = branch == current and "󰘬" or "󰌆", name = branch,
      count = ahead and ahead > 0 and ahead or nil,
      desc = (branch == current and "You stand on this branch. " or "") .. "Last commit " .. when .. ".",
      use = function() switch_branch(root, branch) end,
      check = function() return vim.list_extend({ branch, "" }, git(root, { "log", "--oneline", "-10", branch })) end,
      combine = function()
        return vim.list_extend({ "HEAD against " .. branch, "" }, git(root, { "diff", "--stat", "HEAD..." .. branch }))
      end,
    })
  end
  return items
end

local function stash_items(root)
  return vim.tbl_map(function(line)
    local ref, message = line:match("^(.-)\t(.*)$")
    return {
      icon = "󰆓", name = message, desc = ref .. ", applying it keeps it in the stash.",
      use = function()
        vim.notify(table.concat(git(root, { "stash", "apply", ref }), "\n"), vim.log.levels.INFO, { title = "Git" })
      end,
      check = function() return vim.list_extend({ ref, "" }, git(root, { "stash", "show", "--stat", ref })) end,
    }
  end, git(root, { "stash", "list", "--format=%gd\t%s" }))
end

--- Branches and stashes of the repo you stand in, the key items that open other paths.
---@return table[]
function M.git()
  local root = require("core.repos").root()
  if not root then return {} end
  return vim.list_extend(branch_items(root), stash_items(root))
end

--- Messages left on the ground of this repo.
---@return table[]
function M.messages()
  local root = require("core.repos").root()
  if not root then return {} end
  return vim.tbl_map(function(entry)
    local path = root .. "/" .. entry.file
    return {
      icon = "✎", icon_hl = "EldenMessage", name = entry.text, count = entry.line,
      desc = ("%s, line %d"):format(entry.file, entry.line),
      use = function()
        vim.cmd.edit(vim.fn.fnameescape(path))
        pcall(vim.api.nvim_win_set_cursor, 0, { entry.line, 0 })
      end,
      check = function() return { entry.text, "", entry.file .. ":" .. entry.line } end,
    }
  end, require("core.messages").entries(root))
end

--- The regions of today's franchise, then every franchise to switch to.
---@return table[]
function M.regions()
  local current = require("core.themes").current().name
  local items = vim.tbl_map(function(region)
    return {
      icon = region.name == current and "✦" or "◈", name = region.title,
      desc = region.tagline .. ", watched over by " .. region.character .. ".",
      use = function() require("core.themes").apply(region.name, { announce = true, remember = true }) end,
      check = function() return { region.title, "", region.tagline, "", "Champion  " .. region.character } end,
    }
  end, require("core.themes.actions").regions())
  local franchise = require("core.franchise.actions")
  for _, name in ipairs(franchise.names()) do
    table.insert(items, {
      icon = "⚑", name = franchise.lore(name).title,
      desc = "Wake up in " .. franchise.lore(name).title .. " for the rest of the day.",
      use = function() require("core.franchise").switch(name) end,
    })
  end
  return items
end

local changed = {}

-- reading every project's changes means a git call each, so it runs in the background
local function count_changes(items)
  for _, item in ipairs(items) do
    vim.system({ "git", "-C", item.repo, "status", "--porcelain" }, { text = true }, vim.schedule_wrap(function(result)
      if result.code ~= 0 then return end
      -- porcelain lines open with a space for unstaged changes, so only the line ends are trimmed
      local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
      if vim.deep_equal(changed[item.repo], lines) then return end
      changed[item.repo] = lines
      item.count = #lines > 0 and #lines or nil
      require("core.hud").refresh()
    end))
  end
end

--- The projects found by the repo scanner, with how many files each one has changed.
---@return table[]
function M.projects()
  local items = {}
  for index, repo in ipairs(require("core.repos").list(12)) do
    local branch = require("core.repos").branch(repo) or "?"
    local count = changed[repo] and #changed[repo]
    table.insert(items, {
      repo = repo, branch = branch, icon = "󰊢", name = vim.fs.basename(repo), slot = vim.fs.basename(repo),
      key = index <= 9 and tostring(index) or nil, count = count and count > 0 and count or nil,
      desc = vim.fn.fnamemodify(repo, ":~") .. " on " .. branch .. ".",
      use = function() require("core.repos").open(repo) end,
      check = function() return vim.list_extend({ vim.fs.basename(repo), "", "Branch  " .. branch, "" }, git(repo, { "status", "--short" })) end,
    })
  end
  count_changes(items)
  return items
end

--- The work waiting where you stand: the repo, its branch, what changed and the last file touched.
---@return { project?: string, branch?: string, changes?: string[], last_file?: string, filetype?: string }
function M.quest()
  local latest = vim.v.oldfiles[1]
  local quest = {
    last_path = latest,
    -- whether the last file can be opened, so the views and the walkable items agree on it
    last_ready = latest ~= nil and vim.fn.filereadable(latest) == 1,
    last_file = latest and vim.fn.fnamemodify(latest, ":~:.") or nil,
    -- the HUD's own buffer says nothing about the work, the last file you touched does
    filetype = latest and vim.filetype.match({ filename = latest }) or nil,
  }
  local root = require("core.repos").root()
  if not root then return quest end
  quest.root, quest.project, quest.branch, quest.changes = root, vim.fs.basename(root), require("core.repos").branch(root), changed[root]
  if not changed[root] then count_changes({ { repo = root } }) end
  return quest
end

local CHANGE_WORDS = { M = "Modified", A = "Added", D = "Deleted", R = "Renamed", ["?"] = "Untracked", U = "Conflicted" }

local function change_item(root, line)
  local code = vim.trim(line:sub(1, 2))
  -- a rename reads "old -> new", the file to open is the new one
  local path = line:sub(4):match("%-> (.+)$") or line:sub(4)
  local full = root .. "/" .. path
  local label = CHANGE_WORDS[code:sub(1, 1)] or "Changed"
  return {
    icon = "󰈔", name = path, desc = ("%s, %s."):format(label, path),
    use = function() if vim.fn.filereadable(full) == 1 then vim.cmd.edit(vim.fn.fnameescape(full)) end end,
    check = function()
      local diff = git(root, { "diff", "--stat", "HEAD", "--", path })
      return vim.list_extend({ path, "", label, "" }, #diff > 0 and diff or { "No diff against HEAD yet." })
    end,
    combine = function() if vim.fn.filereadable(full) == 1 then vim.cmd.vsplit(vim.fn.fnameescape(full)) end end,
  }
end

--- The quest as items to walk through: the last file you touched, then every changed file.
---@param quest table from M.quest()
---@return table[]
function M.quest_items(quest)
  local list = {}
  if quest.last_ready then
    table.insert(list, {
      icon = "↳", name = vim.fs.basename(quest.last_path), desc = "Pick up where you left off: " .. quest.last_file .. ".",
      use = function() vim.cmd.edit(vim.fn.fnameescape(quest.last_path)) end,
      check = function() return file_details(quest.last_path) end,
      combine = function() vim.cmd.vsplit(vim.fn.fnameescape(quest.last_path)) end,
    })
  end
  for _, line in ipairs(quest.root and quest.changes or {}) do table.insert(list, change_item(quest.root, line)) end
  return list
end

--- The rooms of the project you stand in: red while errors or TODOs remain, blue once cleared.
---@return table[]
function M.rooms()
  local root = require("core.repos").root()
  if not root then return {} end
  local map = require("core.map.actions")
  return vim.tbl_map(function(room)
    local left = room.errors + room.todos
    return {
      icon = room.cleared and "■" or "□", icon_hl = room.cleared and "EldenMapCleared" or "EldenMapLeft",
      name = room.name, slot = vim.fs.basename(room.key), count = left > 0 and left or nil,
      desc = room.key .. (room.cleared and ", cleared." or (", " .. map.leftovers(room) .. " left.")),
      use = function() Snacks.picker.files({ cwd = root .. "/" .. room.key }) end,
      check = function() return { room.name, "", room.key, map.leftovers(room) } end,
      combine = function() Snacks.picker.grep({ cwd = root .. "/" .. room.key, search = "TODO|FIXME", regex = true }) end,
    }
  end, require("core.map").rooms(root))
end

--- The way out: back to work, the last session, or leave for good.
---@return table[]
function M.exit()
  return {
    { icon = "󰆔", name = "Restore Session", slot = "Session", desc = "Bring back the last visit here.",
      use = function() require("persistence").load() end },
    { icon = "󰝒", name = "Back to work", slot = "Work", desc = "Close the inventory and start an empty buffer.",
      use = function() vim.cmd.enew() end },
    { icon = "󰐥", name = "Leave " .. require("core.franchise").current().title, slot = "Leave", desc = "Close nvim.",
      use = function() vim.cmd.qall() end },
  }
end

--- Builds the tabs a HUD style shows.
---@param style string "roundtable" or "inventory"
---@return table[] tabs, table|nil chest
function M.tabs(style)
  if style == "inventory" then
    local files = vim.list_extend(M.recent(18), M.messages())
    return {
      { title = "ITEM", items = M.actions() },
      { title = "KEYS", items = M.git() },
      { title = "BOX", items = M.projects() },
      { title = "FILE", items = files },
      { title = "MAP", items = M.rooms() },
      { title = "EXIT", items = M.exit() },
    }, nil
  end
  return {
    { title = "Tools", icon = "⚒", items = M.actions() },
    { title = "Recent", icon = "󰋚", items = M.recent() },
    { title = "Key Items", icon = "󰌆", items = M.git() },
    { title = "Messages", icon = "✎", items = M.messages() },
    { title = "Regions", icon = "◈", items = M.regions() },
  }, { title = words().sites, items = M.projects() }
end

return M
