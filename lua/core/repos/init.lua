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
  if not ok then return {} end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (decoded_ok and type(decoded) == "table") and decoded or {}
end

local function write_json_list(path, list)
  pcall(vim.fn.writefile, { vim.json.encode(list) }, path)
end

local function git_root(path)
  if not path or path == "" then return nil end
  local marker = vim.fs.find(".git", { path = path, upward = true })[1]
  return marker and vim.fs.dirname(marker) or nil
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
    if not git_path then return nil end
  end
  return actions.branch_from_head(first_line(git_path .. "/HEAD"))
end

function M.record_visit(dir)
  local root = git_root(dir)
  if not root then return end
  write_json_list(visits_file, actions.remember(read_json_list(visits_file), root, 30))
end

function M.list(limit)
  local still_there = function(path) return vim.fn.isdirectory(path) == 1 end
  local visited = vim.tbl_filter(still_there, read_json_list(visits_file))
  local scanned = vim.tbl_filter(still_there, read_json_list(scan_file))

  local activity = {}
  for _, repo in ipairs(scanned) do activity[repo] = last_activity(repo) end

  return actions.rank(visited, scanned, activity, limit)
end

function M.dashboard_items(limit)
  local items = {}
  for index, repo in ipairs(M.list(limit)) do
    local branch = M.branch(repo)
    table.insert(items, {
      key    = tostring(index),
      icon   = "󰊢 ",
      title  = vim.fs.basename(repo),
      desc   = branch and ("  " .. branch) or "",
      action = function() M.open(repo) end,
    })
  end
  return items
end

function M.roots()
  return actions.expand_roots(vim.g.eldentree_repo_roots or actions.DEFAULT_ROOTS)
end

function M.scan(on_done)
  local roots = M.roots()
  if #roots == 0 then return end

  -- vim.fn is off limits inside the process callback, so hop back to the main loop first
  vim.system(actions.scan_command(roots), { text = true }, vim.schedule_wrap(function(result)
    local repos = actions.parse_scan_output(result.stdout)
    write_json_list(scan_file, repos)
    if on_done then on_done(repos) end
  end))
end

-- the lua api skips the command parser, so Windows paths with spaces survive
local function show_tree(dir, focus)
  require("neo-tree.command").execute({ action = focus and "focus" or "show", source = "filesystem", dir = dir })
end

function M.open(repo)
  local first_visit = not vim.tbl_contains(read_json_list(visits_file), repo)
  vim.fn.chdir(repo)
  M.record_visit(repo)
  if first_visit then require("core.banner").show("grace", { subtitle = vim.fs.basename(repo) }) end
  show_tree(repo)
  Snacks.picker.files({ cwd = repo })
end

function M.open_folder()
  vim.ui.input({ prompt = "  Open folder: ", default = vim.uv.cwd(), completion = "dir" }, function(input)
    local dir = actions.folder_from_input(input)
    if not dir then return end
    if vim.fn.isdirectory(dir) == 0 then
      vim.notify("No such folder: " .. dir, vim.log.levels.WARN)
      return
    end
    vim.fn.chdir(dir)
    show_tree(dir, true)
  end)
end

function M.pick()
  local items = {}
  for index, repo in ipairs(M.list()) do
    table.insert(items, {
      idx = index,
      text = repo,
      file = repo,
      dir = true,
      name = vim.fs.basename(repo),
      branch = M.branch(repo) or "",
      where = actions.display_path(vim.fs.dirname(repo)),
    })
  end

  Snacks.picker({
    title = "Sites of Grace",
    items = items,
    preview = "directory",
    format = function(item)
      return {
        { "󰊢 ", "SnacksPickerIcon" },
        { item.name, "SnacksPickerFile" },
        { "  " .. item.branch, "SnacksPickerGitBranch" },
        { "  " .. item.where, "SnacksPickerDir" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then M.open(item.file) end
    end,
  })
end

local function maybe_change_root(buf)
  if vim.g.eldentree_autoroot == false then return end
  if vim.bo[buf].buftype ~= "" then return end

  local file = vim.api.nvim_buf_get_name(buf)
  local ignored_dirs = { vim.fn.stdpath("data"), vim.fn.stdpath("cache"), vim.fn.stdpath("state") }
  if actions.is_ignored(file, ignored_dirs) then return end

  local cwd = vim.uv.cwd()
  local root = git_root(vim.fs.dirname(file))
  if actions.should_change_root(file, cwd, root) then
    vim.fn.chdir(root)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_repos", { clear = true })

  vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
    group = group,
    callback = function() M.record_visit(vim.uv.cwd()) end,
  })

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(ev) maybe_change_root(ev.buf) end,
  })

  -- wait until the UI is up so startup time stays snappy
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      M.scan(function()
        if vim.bo.filetype == "snacks_dashboard" then Snacks.dashboard.update() end
      end)
    end,
  })

  vim.api.nvim_create_user_command("Repos", M.pick, { desc = "Pick a repository" })
  vim.api.nvim_create_user_command("OpenFolder", M.open_folder, { desc = "Open a folder with the tree" })
  vim.api.nvim_create_user_command("ReposRescan", function()
    M.scan(function(repos) vim.notify(("Found %d repositories"):format(#repos), vim.log.levels.INFO) end)
  end, { desc = "Rescan repository folders" })
end

return M
