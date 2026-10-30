-- Pure helpers for finding, ranking and describing git repos.
-- Nothing in here touches the editor UI, so it can be tested headless.
local M = {}

M.DEFAULT_ROOTS = {
  "~/Documents/GitHub",
  "~/Developer",
  "~/code",
  "~/dev",
  "~/projects",
  "~/src",
  "~/work",
}

M.MAX_DEPTH = 4

function M.expand_roots(roots)
  local existing = {}
  for _, root in ipairs(roots or {}) do
    local path = vim.fs.normalize(vim.fn.expand(root))
    if vim.fn.isdirectory(path) == 1 then
      table.insert(existing, path)
    end
  end
  return existing
end

-- fd prints ".../repo/.git/" for folders and ".../repo/.git" for worktree files
function M.parse_scan_output(stdout)
  local repos, seen = {}, {}
  for line in (stdout or ""):gmatch("[^\r\n]+") do
    local repo = line:gsub("/+$", ""):gsub("/%.git$", "")
    if repo ~= line:gsub("/+$", "") and not seen[repo] then
      seen[repo] = true
      table.insert(repos, repo)
    end
  end
  return repos
end

function M.scan_command(roots)
  if vim.fn.executable("fd") == 1 then
    local cmd = {
      "fd",
      "--hidden",
      "--no-ignore",
      "--glob",
      ".git",
      "--type",
      "d",
      "--type",
      "f",
      "--max-depth",
      tostring(M.MAX_DEPTH),
      "--exclude",
      "node_modules",
      "--exclude",
      "vendor",
      "--exclude",
      ".venv",
      "--prune",
    }
    for _, root in ipairs(roots) do
      vim.list_extend(cmd, { "--search-path", root })
    end
    return cmd
  end

  -- find is slower but every unix box has it
  local cmd = { "find" }
  vim.list_extend(cmd, roots)
  vim.list_extend(cmd, {
    "-maxdepth",
    tostring(M.MAX_DEPTH),
    "-name",
    "node_modules",
    "-prune",
    "-o",
    "-name",
    ".git",
    "-print",
  })
  return cmd
end

function M.display_path(path, home)
  home = home or vim.env.HOME or ""
  if home ~= "" and path:sub(1, #home + 1) == home .. "/" then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

function M.branch_from_head(head_contents)
  if not head_contents or head_contents == "" then
    return nil
  end
  local branch = head_contents:match("^ref:%s*refs/heads/(.-)%s*$")
  if branch then
    return branch
  end
  -- detached HEAD is just a sha, show it short like git does
  local sha = head_contents:match("^(%x+)%s*$")
  return sha and sha:sub(1, 7) or nil
end

function M.gitdir_from_file(contents, repo)
  local gitdir = contents and contents:match("^gitdir:%s*(.-)%s*$")
  if not gitdir then
    return nil
  end
  if gitdir:sub(1, 1) == "/" then
    return gitdir
  end
  return repo .. "/" .. gitdir
end

--- Returns the folder of the first .git marker that belongs to a real repo, walking upward.
--- Tools like GitKraken leave bare .git folders behind, those have no HEAD and are skipped.
---@param markers string[] .git paths, nearest first
---@param is_repo fun(dir: string): boolean
---@return string|nil
function M.pick_root(markers, is_repo)
  for _, marker in ipairs(markers or {}) do
    local dir = vim.fs.dirname(marker)
    if is_repo(dir) then
      return dir
    end
  end
  return nil
end

--- Picks the buffers to close when leaving a project: listed files with nothing unsaved.
--- Unsaved work and special buffers like terminals always stay open.
---@param buffers { id: integer, name: string, listed: boolean, modified: boolean, buftype: string }[]
---@return integer[] buffer ids
function M.buffers_to_close(buffers)
  local closing = {}
  for _, buf in ipairs(buffers or {}) do
    if buf.listed and buf.buftype == "" and buf.name ~= "" and not buf.modified then
      table.insert(closing, buf.id)
    end
  end
  return closing
end

--- Tells whether the project you are leaving has any file open, so its session is worth keeping.
---@param buffers { name: string, listed: boolean, buftype: string }[]
---@return boolean
function M.worth_saving(buffers)
  for _, buf in ipairs(buffers or {}) do
    if buf.listed and buf.buftype == "" and buf.name ~= "" then
      return true
    end
  end
  return false
end

-- recently visited repos first, then everything else by last git activity
function M.rank(tracked, scanned, activity, limit)
  local ranked, seen = {}, {}

  local function add(path)
    if seen[path] or (limit and #ranked >= limit) then
      return
    end
    seen[path] = true
    table.insert(ranked, path)
  end

  for _, path in ipairs(tracked or {}) do
    add(path)
  end

  local rest = vim.tbl_filter(function(path)
    return not seen[path]
  end, scanned or {})
  table.sort(rest, function(a, b)
    local a_time, b_time = (activity or {})[a] or 0, (activity or {})[b] or 0
    if a_time ~= b_time then
      return a_time > b_time
    end
    return a < b
  end)
  for _, path in ipairs(rest) do
    add(path)
  end

  return ranked
end

function M.remember(list, path, max)
  local updated = { path }
  for _, existing in ipairs(list or {}) do
    if existing ~= path and #updated < (max or 20) then
      table.insert(updated, existing)
    end
  end
  return updated
end

--- Tells whether a repo was visited before, so opening it continues instead of starting anew.
---@param visits string[]|nil repo roots already visited
---@param root string|nil repo being opened, nil outside of one
---@return boolean
function M.returning(visits, root)
  return root ~= nil and vim.tbl_contains(visits or {}, root)
end

function M.is_inside(path, dir)
  if not path or not dir then
    return false
  end
  return path == dir or path:sub(1, #dir + 1) == dir .. "/"
end

--- Where the folder browser starts: the dev folder you are in, the first one that exists, or home.
---@param roots string[] expanded dev folders
---@param cwd string|nil
---@param home string
---@return string
function M.browse_root(roots, cwd, home)
  for _, root in ipairs(roots or {}) do
    if M.is_inside(cwd, root) then
      return root
    end
  end
  return (roots or {})[1] or home
end

--- The folders worth browsing into, sorted by name, hidden ones left out.
---@param entries { name: string, type: string }[] what vim.fs.dir lists
---@return string[] names
function M.subfolders(entries)
  local names = {}
  for _, entry in ipairs(entries or {}) do
    local is_dir = entry.type == "directory" or entry.type == "link"
    if is_dir and entry.name:sub(1, 1) ~= "." then
      table.insert(names, entry.name)
    end
  end
  table.sort(names, function(a, b)
    return a:lower() < b:lower()
  end)
  return names
end

--- The picker that opens once you arrive at a repo: the one you asked for, or the files picker
--- on a first visit so there is something to open.
---@param first_visit boolean
---@param chosen? "files"|"grep"|"recent"
---@return string|nil
function M.after_travel(first_visit, chosen)
  if chosen then
    return chosen
  end
  return first_visit and "files" or nil
end

-- jumping into a plugin or dependency source should not drag the cwd along
function M.is_ignored(file, ignored_dirs)
  if file:find("/node_modules/", 1, true) then
    return true
  end
  for _, dir in ipairs(ignored_dirs or {}) do
    if M.is_inside(file, dir) then
      return true
    end
  end
  return false
end

-- only hop when the file lives in a different repo than where we stand
function M.should_change_root(file, cwd, root)
  if not file or file == "" or not root then
    return false
  end
  if root == cwd then
    return false
  end
  return not M.is_inside(file, cwd)
end

return M
