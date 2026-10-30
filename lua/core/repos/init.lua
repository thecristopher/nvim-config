-- Repo radar: scans your dev folders in the background, remembers where
-- you have been, and feeds the dashboard plus the <leader>fp picker.
--
-- Override the scan folders with vim.g.eldentree_repo_roots = { "~/somewhere" }
-- Turn off auto root hopping with vim.g.eldentree_autoroot = false
local actions = require("core.repos.actions")

local M = {}

local state_dir = vim.fn.stdpath("state")
-- the old dashboard already wrote visits here, so keep reading it
local visits_file = state_dir .. "/eldentree_recent_projects.json"
local scan_file = state_dir .. "/eldentree_scanned_repos.json"

local function read_json_list(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

local function write_json_list(path, list)
  pcall(vim.fn.writefile, { vim.json.encode(list) }, path)
end

local function last_activity(repo)
  -- the index is rewritten on every stage, checkout and commit
  local stat = vim.uv.fs_stat(repo .. "/.git/index") or vim.uv.fs_stat(repo .. "/.git")
  return stat and stat.mtime.sec or 0
end

local function first_line(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  return ok and lines[1] or nil
end

function M.branch(repo)
  local git_path = repo .. "/.git"
  -- worktrees and submodules have a .git file pointing at the real git folder
  if vim.fn.filereadable(git_path) == 1 then
    git_path = actions.gitdir_from_file(first_line(git_path), repo)
    if not git_path then
      return nil
    end
  end
  return actions.branch_from_head(first_line(git_path .. "/HEAD"))
end

--- Tells whether a folder is a real git repo, one whose .git leads to a readable HEAD.
---@param dir string
---@return boolean
function M.is_repo(dir)
  return M.branch(dir) ~= nil
end

local function git_root(path)
  if not path or path == "" then
    return nil
  end
  local markers = vim.fs.find(".git", { path = path, upward = true, limit = math.huge })
  return actions.pick_root(markers, M.is_repo)
end

--- Returns the git repo a path lives in, nil outside of one.
---@param path string|nil defaults to the working directory
---@return string|nil
function M.root(path)
  return git_root(path or vim.uv.cwd())
end

function M.record_visit(dir)
  local root = git_root(dir)
  if not root then
    return
  end
  write_json_list(visits_file, actions.remember(read_json_list(visits_file), root, 30))
end

function M.list(limit)
  local still_there = function(path)
    return vim.fn.isdirectory(path) == 1 and M.is_repo(path)
  end
  local visited = vim.tbl_filter(still_there, read_json_list(visits_file))
  local scanned = vim.tbl_filter(still_there, read_json_list(scan_file))

  local activity = {}
  for _, repo in ipairs(scanned) do
    activity[repo] = last_activity(repo)
  end

  return actions.rank(visited, scanned, activity, limit)
end

function M.dashboard_items(limit)
  local items = {}
  for index, repo in ipairs(M.list(limit)) do
    local branch = M.branch(repo)
    table.insert(items, {
      key = tostring(index),
      icon = "󰊢 ",
      title = vim.fs.basename(repo),
      desc = branch and ("  " .. branch) or "",
      action = function()
        M.open(repo)
      end,
    })
  end
  return items
end

function M.roots()
  return actions.expand_roots(vim.g.eldentree_repo_roots or actions.DEFAULT_ROOTS)
end

function M.scan(on_done)
  local roots = M.roots()
  if #roots == 0 then
    -- whoever waits on the scan still hears back, so a progress bar never spins forever
    if on_done then
      on_done({})
    end
    return
  end

  -- vim.fn is off limits inside the process callback, so hop back to the main loop first
  vim.system(
    actions.scan_command(roots),
    { text = true },
    vim.schedule_wrap(function(result)
      local repos = actions.parse_scan_output(result.stdout)
      write_json_list(scan_file, repos)
      if on_done then
        on_done(repos)
      end
    end)
  )
end

-- the lua api skips the command parser, so Windows paths with spaces survive
local function show_tree(dir, focus)
  require("neo-tree.command").execute({
    action = focus and "focus" or "show",
    source = "filesystem",
    dir = dir,
  })
end

local PICKERS = {
  files = function(dir)
    Snacks.picker.files({ cwd = dir })
  end,
  grep = function(dir)
    Snacks.picker.grep({ cwd = dir })
  end,
  recent = function()
    require("core.find").recent("repo")
  end,
}

-- the picker closes when another window grabs focus, so wait for the tree to finish drawing
local function picker_after_tree(dir, name)
  local events = require("neo-tree.events")
  local opened = false
  local subscription = { event = events.AFTER_RENDER, id = "eldentree_picker_after_tree" }

  local function open_picker()
    if opened then
      return
    end
    opened = true
    events.unsubscribe(subscription)
    vim.schedule(function()
      PICKERS[name](dir)
    end)
  end

  subscription.handler = function(state)
    if state.name == "filesystem" then
      open_picker()
    end
  end
  events.subscribe(subscription)
  -- in case the tree skips a redraw, the picker still shows up
  vim.defer_fn(open_picker, 800)
end

local function buffer_infos()
  return vim.tbl_map(function(buf)
    return {
      id = buf,
      name = vim.api.nvim_buf_get_name(buf),
      listed = vim.bo[buf].buflisted,
      modified = vim.bo[buf].modified,
      buftype = vim.bo[buf].buftype,
    }
  end, vim.api.nvim_list_bufs())
end

local function has_session()
  local persistence = require("persistence")
  return vim.fn.filereadable(persistence.current()) == 1
    or vim.fn.filereadable(persistence.current({ branch = false })) == 1
end

-- the tree window would come back as an empty husk, so it never goes into a session
local function save_session()
  pcall(vim.cmd, "Neotree close")
  require("persistence").save()
end

local function close_project_buffers(infos)
  for _, buf in ipairs(actions.buffers_to_close(infos)) do
    pcall(Snacks.bufdelete, { buf = buf, force = false })
  end
end

-- keeps the session of the repo you are leaving and clears its files, unsaved work stays open
local function leave_project()
  if not M.root() then
    return
  end
  local infos = buffer_infos()
  if not actions.worth_saving(infos) then
    return
  end
  save_session()
  close_project_buffers(infos)
end

--- Saves the files open on the branch about to be left, when there is anything worth keeping.
function M.save_branch_session()
  if vim.g.eldentree_project_sessions == false then
    return
  end
  if actions.worth_saving(buffer_infos()) then
    save_session()
  end
end

--- Brings back the files saved on the checked out branch, unsaved work stays open.
---@return boolean restored false when the branch has no session of its own
function M.restore_branch_session()
  local persistence = require("persistence")
  if vim.g.eldentree_project_sessions == false then
    return false
  end
  if vim.fn.filereadable(persistence.current()) == 0 then
    return false
  end
  close_project_buffers(buffer_infos())
  persistence.load()
  return true
end

--- Travels to a repo: the fog rolls in, the old project's session is kept, and the new one comes back
--- with the files you had open there. A first visit, or a picker asked for, opens that picker on arrival.
---@param repo string
---@param picker? "files"|"grep"|"recent"
function M.open(repo, picker)
  local first_visit = not actions.returning(read_json_list(visits_file), repo)
  local sessions = vim.g.eldentree_project_sessions ~= false and M.root() ~= repo
  require("core.fog").roll()
  if sessions then
    leave_project()
  end

  vim.fn.chdir(repo)
  M.record_visit(repo)
  if first_visit then
    require("core.banner").show("grace", { subtitle = vim.fs.basename(repo) })
  else
    require("core.sound").play("continue")
  end

  if sessions and has_session() then
    require("persistence").load()
  end
  local arrival = actions.after_travel(first_visit, picker)
  if arrival then
    picker_after_tree(repo, arrival)
  end
  show_tree(repo)
end

-- a repo travels with its session and fog, any other folder just becomes the cwd beside the tree
local function open_dir(dir)
  if M.is_repo(dir) then
    return M.open(dir)
  end
  vim.fn.chdir(dir)
  show_tree(dir, true)
end

local function folder_items(dir)
  local entries = {}
  -- a folder you cannot read lists as empty instead of breaking the browser
  pcall(function()
    for name, kind in vim.fs.dir(dir) do
      table.insert(entries, { name = name, type = kind })
    end
  end)
  return vim.tbl_map(function(name)
    local path = vim.fs.joinpath(dir, name)
    local repo = M.is_repo(path)
    return { text = name, file = path, dir = true, repo = repo, icon = repo and "󰊢 " or "󰉋 " }
  end, actions.subfolders(entries))
end

local function format_folder(item)
  return {
    { item.icon, item.repo and "SnacksPickerGitBranch" or "SnacksPickerDirectory" },
    { item.text, "SnacksPickerFile" },
  }
end

local BROWSE_KEYS = "l enter  h up  o open  . open here  / filter"

--- Browses folders with the keyboard in normal mode, starting at a dev folder. Enter travels to
--- a repo and goes into any other folder, a folder with nothing inside opens right away.
---@param dir? string
function M.browse(dir)
  dir = dir or actions.browse_root(M.roots(), vim.uv.cwd(), vim.uv.os_homedir())
  local items = folder_items(dir)
  if #items == 0 then
    return open_dir(dir)
  end

  local function go(picker, target)
    picker:close()
    vim.schedule(function()
      M.browse(target)
    end)
  end

  Snacks.picker({
    title = actions.display_path(dir) .. "  " .. BROWSE_KEYS,
    items = items,
    focus = "list",
    preview = "directory",
    format = format_folder,
    confirm = function(picker, item)
      if item and item.repo then
        picker:close()
        return open_dir(item.file)
      end
      go(picker, item and item.file or dir)
    end,
    actions = {
      enter = function(picker, item)
        go(picker, item and item.file or dir)
      end,
      up = function(picker)
        go(picker, vim.fs.dirname(dir))
      end,
      open = function(picker, item)
        picker:close()
        open_dir(item and item.file or dir)
      end,
      open_here = function(picker)
        picker:close()
        open_dir(dir)
      end,
    },
    win = {
      list = {
        keys = { l = "enter", h = "up", ["-"] = "up", o = "open", ["."] = "open_here" },
      },
    },
  })
end

local function repo_items()
  local items = {}
  for index, repo in ipairs(M.list()) do
    table.insert(items, {
      idx = index,
      text = repo,
      file = repo,
      dir = true,
      icon = "󰊢 ",
      name = vim.fs.basename(repo),
      branch = M.branch(repo) or "",
      where = actions.display_path(vim.fs.dirname(repo)),
    })
  end
  return items
end

local function format_item(item)
  return {
    { item.icon, "SnacksPickerIcon" },
    { item.name, "SnacksPickerFile" },
    { "  " .. item.branch, "SnacksPickerGitBranch" },
    { "  " .. item.where, "SnacksPickerDir" },
  }
end

-- known repos first so most opens are a few letters and Enter, the browser is the escape hatch
function M.open_folder()
  local items = repo_items()
  if #items == 0 then
    return M.browse()
  end

  table.insert(items, {
    idx = #items + 1,
    text = "browse another folder",
    file = actions.browse_root(M.roots(), vim.uv.cwd(), vim.uv.os_homedir()),
    dir = true,
    browse = true,
    icon = "󰝰 ",
    name = "Browse another folder…",
    branch = "",
    where = "",
  })

  Snacks.picker({
    title = "Open Folder",
    items = items,
    preview = "directory",
    format = format_item,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      if item.browse then
        return M.browse()
      end
      open_dir(item.file)
    end,
  })
end

local function travel_with(name)
  return function(picker, item)
    picker:close()
    if item then
      M.open(item.file, name)
    end
  end
end

local TRAVEL_KEYS = {
  ["<C-f>"] = { "travel_files", mode = { "i", "n" } },
  ["<C-g>"] = { "travel_grep", mode = { "i", "n" } },
  ["<C-o>"] = { "travel_recent", mode = { "i", "n" } },
}

--- Sites of Grace: Enter travels, <C-f> <C-g> <C-o> travel and open files, grep or recent there.
function M.pick()
  Snacks.picker({
    title = require("core.franchise").current().words.sites
      .. "  <C-f> files  <C-g> grep  <C-o> recent",
    items = repo_items(),
    preview = "directory",
    format = format_item,
    confirm = travel_with(nil),
    actions = {
      travel_files = travel_with("files"),
      travel_grep = travel_with("grep"),
      travel_recent = travel_with("recent"),
    },
    win = { input = { keys = TRAVEL_KEYS }, list = { keys = TRAVEL_KEYS } },
  })
end

local function maybe_change_root(buf)
  if vim.g.eldentree_autoroot == false then
    return
  end
  if vim.bo[buf].buftype ~= "" then
    return
  end

  local file = vim.api.nvim_buf_get_name(buf)
  local ignored_dirs = { vim.fn.stdpath("data"), vim.fn.stdpath("cache"), vim.fn.stdpath("state") }
  if actions.is_ignored(file, ignored_dirs) then
    return
  end

  local cwd = vim.uv.cwd()
  local root = git_root(vim.fs.dirname(file))
  if actions.should_change_root(file, cwd, root) then
    vim.fn.chdir(root)
  end
end

-- launching inside a repo you know continues the game, unless the title screen already plays today
local function continue_on_launch()
  local root = M.root()
  local returning = actions.returning(read_json_list(visits_file), root)
  M.record_visit(vim.uv.cwd())
  if returning and not require("core.title").due_today() then
    require("core.sound").play("continue")
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_repos", { clear = true })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = continue_on_launch,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      M.record_visit(vim.uv.cwd())
    end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(ev)
      maybe_change_root(ev.buf)
    end,
  })

  -- wait until the UI is up so startup time stays snappy
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      M.scan(function()
        require("core.hud").refresh(true)
      end)
    end,
  })

  vim.api.nvim_create_user_command("Repos", M.pick, { desc = "Pick a repository" })
  vim.api.nvim_create_user_command(
    "OpenFolder",
    M.open_folder,
    { desc = "Open a folder with the tree" }
  )
  vim.api.nvim_create_user_command("BrowseFolders", function()
    M.browse()
  end, { desc = "Browse folders with hjkl" })
  vim.api.nvim_create_user_command("ReposRescan", function()
    local task = require("core.progress").start({
      id = "eldentree_repos",
      title = "Repos",
      message = "Scanning for repositories…",
    })
    M.scan(function(repos)
      task:done(("Found %d repositories"):format(#repos))
    end)
  end, { desc = "Rescan repository folders" })
end

return M
