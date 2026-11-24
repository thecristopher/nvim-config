-- What fills the HUD's slots, gathered from the real workspace: the hub actions, recent files,
-- branches and stashes, ground messages, regions, projects and the rooms of the map.
-- Every item knows how to be used, checked (details for a float) and, where it makes sense, combined.
local background = require("core.hud.background")
local hud_actions = require("core.hud.actions")

local M = {}

local function words()
  return require("core.franchise").current().words
end

-- what the world calls its HUD: hub keys, tabs, kinds of items, trophies, see the lore's hud.lua
local function hud_lore()
  return require("core.franchise").current().hud or {}
end

--- Gives items their kind: the category the world files them under and a line of its lore.
---@param items table[]
---@param kind string one of the lore's hud.kinds
---@return table[] the same items
local function as_kind(items, kind)
  local said = (hud_lore().kinds or {})[kind] or {}
  for _, item in ipairs(items) do
    item.kind = kind
    item.category = item.category or said.name
    item.flavor = item.flavor or said.flavor
  end
  return items
end

local function git(root, args)
  local result =
    vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(3000)
  return result.code == 0 and vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true })
    or {}
end

local function run(action)
  if type(action) == "function" then
    return action()
  end
  vim.cmd((action:gsub("^:", "")))
end

local function file_icon(path)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return "󰈔"
  end
  local icon, hl =
    devicons.get_icon(vim.fs.basename(path), vim.fn.fnamemodify(path, ":e"), { default = true })
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

-- what the Check float adds to the band under the grid: the key, the plain name and the lore
local function action_check(name, plain, desc, flavor, key)
  local lines = { name, "", "Key     " .. key, "Plain   " .. plain, "", desc }
  if flavor then
    vim.list_extend(lines, { "", flavor })
  end
  return lines
end

--- The hub actions, the same keys every layout offers, named in the world's words.
---@return table[]
function M.actions()
  local world = hud_lore().keys or {}
  return as_kind(
    vim.tbl_map(function(key)
      local line, pending = nil, false
      if key.status then
        line, pending = key.status()
      end
      local said = world[key.key] or {}
      local name = said.name or key.desc
      local desc = said.desc or ACTION_DESCRIPTIONS[key.key] or key.desc
      return {
        icon = said.icon or key.icon,
        icon_hl = pending and "DiagnosticWarn" or nil,
        name = name,
        slot = said.slot or key.slot,
        key = key.key,
        desc = line or desc,
        flavor = said.flavor,
        sound = key.sound,
        use = function()
          run(key.action)
        end,
        check = function()
          return action_check(name, key.desc, desc, said.flavor, key.key)
        end,
      }
    end, require("core.hud.keys").keys()),
    "action"
  )
end

-- the last commit that touched a file, read only when Check asks for it
local function last_commit(path)
  local root = vim.fs.root(path, ".git")
  if not root then
    return nil
  end
  local lines = git(root, { "log", "-1", "--format=%ar · %an · %s", "--", path })
  return lines[1]
end

local function file_details(path)
  local stat = vim.uv.fs_stat(path)
  local lines = {
    vim.fs.basename(path),
    "",
    "Path      " .. vim.fn.fnamemodify(path, ":~"),
    "Size      " .. (stat and (math.ceil(stat.size / 1024) .. " KB") or "?"),
    "Modified  " .. (stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "?"),
  }
  local commit = last_commit(path)
  if commit then
    table.insert(lines, "Commit    " .. commit)
  end
  return lines
end

-- the path from where you stand and how long ago it was last written
local function touched(path)
  local stat = vim.uv.fs_stat(path)
  local where = vim.fn.fnamemodify(path, ":~:.")
  if not stat then
    return where
  end
  return ("%s  ·  %s"):format(where, hud_actions.ago(os.time() - stat.mtime.sec))
end

--- Files you had open lately, newest first. Two files with the same name carry their folder, so
--- six init.lua never look alike.
---@param limit integer|nil
---@return table[]
function M.recent(limit)
  local paths = {}
  for _, path in ipairs(vim.v.oldfiles) do
    if #paths >= (limit or 24) then
      break
    end
    if vim.fn.filereadable(path) == 1 then
      table.insert(paths, path)
    end
  end
  local labels = hud_actions.file_labels(paths)
  local items = {}
  for index, path in ipairs(paths) do
    local icon, hl = file_icon(path)
    table.insert(items, {
      icon = icon,
      icon_hl = hl,
      name = labels[index],
      path = path,
      desc = touched(path),
      use = function()
        vim.cmd.edit(vim.fn.fnameescape(path))
      end,
      check = function()
        return file_details(path)
      end,
      combine = function()
        vim.cmd.vsplit(vim.fn.fnameescape(path))
      end,
    })
  end
  return as_kind(items, "recent")
end

local function switch_branch(root, branch)
  vim.system(
    { "git", "-C", root, "switch", branch },
    { text = true },
    vim.schedule_wrap(function(result)
      local ok = result.code == 0
      vim.notify(
        ok and ("Switched to " .. branch) or vim.trim(result.stderr),
        ok and vim.log.levels.INFO or vim.log.levels.WARN,
        { title = "Git" }
      )
      background.forget()
      require("core.hud").refresh(true)
    end)
  )
end

local BRANCH_FORMAT = "%(refname:short)\t%(committerdate:relative)"
local BRANCH_ARGS = { "for-each-ref", "--sort=-committerdate", "--count=12" }

-- one for-each-ref with the ahead count of every branch, instead of a rev-list per branch.
-- %(ahead-behind) arrived in git 2.41, older git gets the list without the counts
local function fetch_branches(root, done)
  local with_counts = vim.list_extend(vim.deepcopy(BRANCH_ARGS), {
    "--format=" .. BRANCH_FORMAT .. "\t%(ahead-behind:HEAD)",
    "refs/heads",
  })
  background.git(root, with_counts, function(lines, ok)
    if ok then
      return done(lines)
    end
    local plain =
      vim.list_extend(vim.deepcopy(BRANCH_ARGS), { "--format=" .. BRANCH_FORMAT, "refs/heads" })
    background.git(root, plain, done)
  end)
end

local function fetch_git(root)
  return function(done)
    fetch_branches(root, function(branches)
      background.git(root, { "stash", "list", "--format=%gd\t%s" }, function(stashes)
        done({ branches = branches, stashes = stashes })
      end)
    end)
  end
end

local function branch_item(root, current, parsed)
  local branch = parsed.branch
  return {
    icon = branch == current and "󰘬" or "󰌆",
    current = branch == current or nil,
    name = branch,
    count = parsed.ahead and parsed.ahead > 0 and parsed.ahead or nil,
    desc = (branch == current and "You stand on this branch. " or "")
      .. "Last commit "
      .. parsed.when
      .. ".",
    use = function()
      switch_branch(root, branch)
    end,
    check = function()
      return vim.list_extend({ branch, "" }, git(root, { "log", "--oneline", "-10", branch }))
    end,
    combine = function()
      return vim.list_extend(
        { "HEAD against " .. branch, "" },
        git(root, { "diff", "--stat", "HEAD..." .. branch })
      )
    end,
  }
end

local function branch_items(root, lines)
  local current = require("core.repos").branch(root)
  local items = {}
  for _, line in ipairs(lines) do
    local parsed = hud_actions.parse_branch(line)
    if parsed then
      table.insert(items, branch_item(root, current, parsed))
    end
  end
  return items
end

local function stash_items(root, lines)
  return vim.tbl_map(function(line)
    local ref, message = line:match("^(.-)\t(.*)$")
    return {
      icon = "󰆓",
      name = message,
      desc = ref .. ", applying it keeps it in the stash.",
      use = function()
        vim.notify(
          table.concat(git(root, { "stash", "apply", ref }), "\n"),
          vim.log.levels.INFO,
          { title = "Git" }
        )
        background.forget()
      end,
      check = function()
        return vim.list_extend({ ref, "" }, git(root, { "stash", "show", "--stat", ref }))
      end,
    }
  end, lines)
end

--- Branches and stashes of the repo you stand in, the key items that open other paths.
---@return table[]
function M.git()
  local root = require("core.repos").root()
  if not root then
    return {}
  end
  local cached = background.get("git:" .. root, fetch_git(root))
  if not cached then
    return {}
  end
  return vim.list_extend(
    as_kind(branch_items(root, cached.branches), "branch"),
    as_kind(stash_items(root, cached.stashes), "stash")
  )
end

--- Messages left on the ground of this repo.
---@return table[]
function M.messages()
  local root = require("core.repos").root()
  if not root then
    return {}
  end
  return as_kind(
    vim.tbl_map(function(entry)
      local path = root .. "/" .. entry.file
      return {
        icon = "󰏫",
        icon_hl = "EldenMessage",
        name = entry.text,
        count = entry.line,
        desc = ("%s, line %d"):format(entry.file, entry.line),
        use = function()
          vim.cmd.edit(vim.fn.fnameescape(path))
          pcall(vim.api.nvim_win_set_cursor, 0, { entry.line, 0 })
        end,
        check = function()
          return { entry.text, "", entry.file .. ":" .. entry.line }
        end,
      }
    end, require("core.messages").entries(root)),
    "message"
  )
end

--- The regions of today's franchise, then every franchise to switch to.
---@return table[]
function M.regions()
  local current = require("core.themes").current().name
  local items = vim.tbl_map(function(region)
    return {
      icon = region.name == current and "󰫢" or "◈",
      name = region.title,
      desc = region.tagline .. ", watched over by " .. region.character .. ".",
      use = function()
        require("core.themes").apply(region.name, { announce = true })
      end,
      check = function()
        return { region.title, "", region.tagline, "", "Champion  " .. region.character }
      end,
    }
  end, require("core.themes.actions").regions())
  as_kind(items, "region")
  local franchise = require("core.franchise.actions")
  for _, name in ipairs(franchise.names()) do
    table.insert(items, {
      icon = "󰈻",
      kind = "franchise",
      category = ((hud_lore().kinds or {}).franchise or {}).name,
      flavor = ((hud_lore().kinds or {}).franchise or {}).flavor,
      name = franchise.lore(name).title,
      desc = require("core.franchise").line(
        "hud.switch_desc",
        { target = franchise.lore(name).title }
      ),
      use = function()
        require("core.franchise").switch(name)
      end,
    })
  end
  return items
end

local changed = {}
local counted_at

-- reading every project's changes means a git call each, so it runs in the background, and at
-- most once every background.TTL_MS
local function count_changes(items)
  if not hud_actions.stale(counted_at, vim.uv.now(), background.TTL_MS) then
    return
  end
  counted_at = vim.uv.now()
  -- a dozen spawns cost ~7 ms, so they wait until the HUD being built is on screen
  vim.schedule(function()
    for _, item in ipairs(items) do
      vim.system(
        { "git", "-C", item.repo, "status", "--porcelain" },
        { text = true },
        vim.schedule_wrap(function(result)
          if result.code ~= 0 then
            return
          end
          -- porcelain lines open with a space for unstaged changes, so only the line ends are trimmed
          local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
          if vim.deep_equal(changed[item.repo], lines) then
            return
          end
          changed[item.repo] = lines
          item.count = #lines > 0 and #lines or nil
          require("core.hud").refresh()
        end)
      )
    end
  end)
end

--- The projects found by the repo scanner, with how many files each one has changed.
---@return table[]
function M.projects()
  local items = {}
  local here = require("core.repos").root()
  for index, repo in ipairs(require("core.repos").list(12)) do
    local branch = require("core.repos").branch(repo) or "?"
    local count = changed[repo] and #changed[repo]
    table.insert(items, {
      repo = repo,
      current = repo == here or nil,
      branch = branch,
      icon = "󰊢",
      name = vim.fs.basename(repo),
      slot = vim.fs.basename(repo),
      key = index <= 9 and tostring(index) or nil,
      count = count and count > 0 and count or nil,
      desc = vim.fn.fnamemodify(repo, ":~") .. " on " .. branch .. ".",
      use = function()
        require("core.repos").open(repo)
      end,
      check = function()
        return vim.list_extend(
          { vim.fs.basename(repo), "", "Branch  " .. branch, "" },
          git(repo, { "status", "--short" })
        )
      end,
    })
  end
  count_changes(items)
  return as_kind(items, "project")
end

--- The work waiting where you stand: the repo, its branch, what changed and the last file touched.
---@return { project?: string, branch?: string, changes?: string[], last_file?: string, filetype?: string }
function M.quest()
  local root = require("core.repos").root()
  -- the quest is the project's, so its last file is the last one touched inside it
  local latest = hud_actions.last_in(vim.v.oldfiles, root)
  local quest = {
    last_path = latest,
    -- whether the last file can be opened, so the views and the walkable items agree on it
    last_ready = latest ~= nil and vim.fn.filereadable(latest) == 1,
    last_file = latest and vim.fn.fnamemodify(latest, ":~:.") or nil,
    -- the HUD's own buffer says nothing about the work, the last file you touched does
    filetype = latest and vim.filetype.match({ filename = latest }) or nil,
  }
  if not root then
    return quest
  end
  quest.root, quest.project, quest.branch, quest.changes =
    root, vim.fs.basename(root), require("core.repos").branch(root), changed[root]
  if not changed[root] then
    count_changes({ { repo = root } })
  end
  return quest
end

local CHANGE_WORDS = {
  M = "Modified",
  A = "Added",
  D = "Deleted",
  R = "Renamed",
  ["?"] = "Untracked",
  U = "Conflicted",
}

local function change_item(root, line)
  local code = vim.trim(line:sub(1, 2))
  -- a rename reads "old -> new", the file to open is the new one
  local path = line:sub(4):match("%-> (.+)$") or line:sub(4)
  local full = root .. "/" .. path
  local label = CHANGE_WORDS[code:sub(1, 1)] or "Changed"
  local said = (hud_lore().kinds or {}).change or {}
  return {
    icon = "󰈔",
    kind = "change",
    category = said.name,
    flavor = said.flavor,
    name = path,
    path = full,
    desc = ("%s, %s."):format(label, path),
    use = function()
      if vim.fn.filereadable(full) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(full))
      end
    end,
    check = function()
      local diff = git(root, { "diff", "--stat", "HEAD", "--", path })
      return vim.list_extend(
        { path, "", label, "" },
        #diff > 0 and diff or { "No diff against HEAD yet." }
      )
    end,
    combine = function()
      if vim.fn.filereadable(full) == 1 then
        vim.cmd.vsplit(vim.fn.fnameescape(full))
      end
    end,
  }
end

--- The quest as items to walk through: the last file you touched, then every changed file.
---@param quest table from M.quest()
---@return table[]
function M.quest_items(quest)
  local list = {}
  if quest.last_ready then
    local said = (hud_lore().kinds or {}).recent or {}
    table.insert(list, {
      icon = "󰘍",
      kind = "recent",
      category = said.name,
      flavor = said.flavor,
      path = quest.last_path,
      name = vim.fs.basename(quest.last_path),
      desc = require("core.franchise").line("hud.resume", { file = quest.last_file }),
      use = function()
        vim.cmd.edit(vim.fn.fnameescape(quest.last_path))
      end,
      check = function()
        return file_details(quest.last_path)
      end,
      combine = function()
        vim.cmd.vsplit(vim.fn.fnameescape(quest.last_path))
      end,
    })
  end
  for _, line in ipairs(quest.root and quest.changes or {}) do
    table.insert(list, change_item(quest.root, line))
  end
  return list
end

--- The rooms of the project you stand in: red while errors or TODOs remain, blue once cleared.
---@return table[]
function M.rooms()
  local root = require("core.repos").root()
  if not root then
    return {}
  end
  local survey = background.get("map:" .. root, function(done)
    require("core.map").survey_async(root, done)
  end)
  if not survey then
    return {}
  end
  local map = require("core.map.actions")
  local marks = require("core.skin").current().tree or {}
  return as_kind(
    vim.tbl_map(function(room)
      local left = room.errors + room.todos
      return {
        icon = room.cleared and (marks.cleared or "■") or (marks.left or "□"),
        icon_hl = room.cleared and "EldenMapCleared" or "EldenMapLeft",
        name = room.name,
        slot = vim.fs.basename(room.key),
        count = left > 0 and left or nil,
        desc = room.key
          .. (room.cleared and ", cleared." or (", " .. map.leftovers(room) .. " left.")),
        use = function()
          Snacks.picker.files({ cwd = root .. "/" .. room.key })
        end,
        check = function()
          return { room.name, "", room.key, map.leftovers(room) }
        end,
        combine = function()
          Snacks.picker.grep({ cwd = root .. "/" .. room.key, search = "TODO|FIXME", regex = true })
        end,
      }
    end, require("core.map").rooms_from(root, survey)),
    "room"
  )
end

--- The way out: back to work, the last session, or leave for good.
---@return table[]
function M.exit()
  local say = require("core.franchise").line
  return as_kind({
    {
      icon = "󰆔",
      name = say("hud.restore"),
      slot = "Session",
      desc = say("hud.restore_desc"),
      use = function()
        require("persistence").load()
      end,
    },
    {
      icon = "󰝒",
      name = say("hud.back"),
      slot = "Work",
      desc = say("hud.back_desc"),
      use = function()
        vim.cmd.enew()
      end,
    },
    {
      icon = "󰐥",
      name = say("hud.leave"),
      slot = "Leave",
      desc = say("hud.leave_desc"),
      use = function()
        vim.cmd.qall()
      end,
    },
  }, "exit")
end

--- The back-to-basics lessons fought so far, empty when the plugin is not around.
---@return table[]
function M.lessons()
  local ok, btb = pcall(require, "core.btb")
  return as_kind(ok and btb.hud_items() or {}, "lesson")
end

local function read_state_json(name)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("state") .. "/" .. name)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

M.TROPHY_ICON = "󰔸"

-- a trophy names itself on its tile and shows its number in the corner, the description says where
-- the number comes from, so it never seems to disagree with the Bestiary or the Chronicle
local function trophy(icon, name, value, scope, open)
  return {
    icon = icon,
    name = name,
    slot = name,
    count = value,
    desc = ("%s: %s, %s."):format(name, tostring(value), scope),
    use = function()
      vim.cmd(open)
    end,
    check = function()
      return { name, "", tostring(value), "", scope }
    end,
  }
end

local function trophy_icon(key)
  return (hud_lore().trophy_icons or {})[key] or M.TROPHY_ICON
end

--- The trophies of every run so far: foes felled, the finest rank, the days fought and the longest
--- streak, in the franchise's words.
---@return table[]
function M.trophies()
  local said = require("core.franchise").current().trophies
  local count = require("core.hud.actions.trophies")
  local summary = count.summary(
    read_state_json("eldentree_bestiary.json"),
    read_state_json("eldentree_chronicle.json")
  )
  if count.empty(summary) then
    return as_kind({
      { icon = trophy_icon("title"), name = said.title, slot = said.title, desc = said.empty },
    }, "trophy")
  end
  local ranked = summary.rank and ("earned on " .. summary.rank_date) or "no run ranked yet"
  return as_kind({
    trophy(trophy_icon("felled"), said.felled, summary.felled, "across every repo", "Bestiary"),
    trophy(trophy_icon("rank"), said.rank, summary.rank or "-", ranked, "Chronicle"),
    trophy(trophy_icon("days"), said.days, summary.days, "days with a finished run", "Chronicle"),
    trophy(trophy_icon("streak"), said.streak, summary.streak, "days in a row", "Chronicle"),
  }, "trophy")
end

-- the attaché case gives the important items more room: the main tools and where you stand
local CASE_SIZES = { f = { w = 2, h = 1 }, p = { w = 2, h = 1 } }

local function sized(items)
  for _, item in ipairs(items) do
    if item.current and item.kind == "project" then
      item.size = { w = 2, h = 2 }
    elseif item.current and item.kind == "branch" then
      item.size = { w = 2, h = 1 }
    else
      item.size = item.size or CASE_SIZES[item.key or ""]
    end
  end
  return items
end

--- Builds the tabs a HUD style shows.
---@param style string "roundtable" or "inventory"
---@return table[] tabs, table|nil chest
function M.tabs(style)
  local names, icons = hud_lore().tabs or {}, hud_lore().tab_icons or {}
  if style == "inventory" then
    -- the records sit among the files, like the documents of the old inventories
    local files = vim.list_extend(vim.list_extend(M.recent(18), M.messages()), M.lessons())
    vim.list_extend(files, M.trophies())
    return {
      { title = names.item or "ITEM", items = sized(M.actions()) },
      { title = names.keys or "KEYS", items = sized(M.git()) },
      { title = names.box or "BOX", items = sized(M.projects()) },
      { title = names.file or "FILE", items = files },
      { title = names.map or "MAP", items = M.rooms() },
      { title = names.exit or "EXIT", items = M.exit() },
    },
      nil
  end
  local lore = require("core.franchise").current()
  return {
    { title = names.tools or "Tools", icon = icons.tools or "󱌣", items = M.actions() },
    { title = names.recent or "Recent", icon = icons.recent or "󰋚", items = M.recent() },
    { title = names.keys or "Key Items", icon = icons.keys or "󰌆", items = M.git() },
    { title = names.messages or "Messages", icon = icons.messages or "󰏫", items = M.messages() },
    { title = names.regions or "Regions", icon = icons.regions or "◈", items = M.regions() },
    { title = lore.coach.lessons, icon = icons.lessons or "󰂺", items = M.lessons() },
    { title = lore.trophies.title, icon = icons.trophies or M.TROPHY_ICON, items = M.trophies() },
  }, { title = words().sites, items = M.projects() }
end

return M
