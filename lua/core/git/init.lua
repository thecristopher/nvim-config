-- Quick git shortcuts: new branch, pull, push, sync with the base branch, stash and undo.
-- Network commands run in the background so the editor never freezes on a slow remote.
local actions = require("core.git.actions")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git", id = "eldentree_git" })
end

local function git_ok(args)
  vim.fn.system(vim.list_extend({ "git" }, args))
  return vim.v.shell_error == 0
end

local function git_out(args)
  local out = vim.fn.system(vim.list_extend({ "git" }, args))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(out)
end

local function last_line(text)
  local lines = vim.split(vim.trim(text or ""), "\n", { plain = true })
  return lines[#lines] or ""
end

---Runs git in the background and calls on_ok with stdout when it succeeds.
---@param args string[] git arguments
---@param on_ok fun(stdout: string)
---@param task? EldenProgress the progress bar that reports the failure, a plain notification otherwise
local function run(args, on_ok, task)
  vim.system(
    vim.list_extend({ "git" }, args),
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local output = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
        local message = "git " .. args[1] .. " failed:\n" .. output
        if task then
          return task:fail(message)
        end
        return notify(message, vim.log.levels.ERROR)
      end
      on_ok(result.stdout or "")
    end)
  )
end

-- the network can take a while, so these steps show the moving bar until git answers
local function progress(message)
  return require("core.progress").start({ id = "eldentree_git", title = "Git", message = message })
end

local function in_repo()
  if git_ok({ "rev-parse", "--is-inside-work-tree" }) then
    return true
  end
  notify("Not inside a git repository.", vim.log.levels.WARN)
  return false
end

---Name of the checked out branch.
---@return string|nil
function M.current_branch()
  return git_out({ "rev-parse", "--abbrev-ref", "HEAD" })
end

---Tells whether the current branch already tracks a remote branch.
---@return boolean
function M.has_upstream()
  return git_ok({ "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" })
end

-- `staging` goes before main/master since most of these repos merge feature work there first
local BASE_CANDIDATES = { "staging", "main", "master" }

---Branch that feature work merges into. `git config pr-helper.base <branch>` wins over everything.
---@return string|nil
function M.default_branch()
  local configured = git_out({ "config", "--get", "pr-helper.base" })
  if configured and configured ~= "" then
    return configured
  end

  for _, name in ipairs(BASE_CANDIDATES) do
    if git_ok({ "show-ref", "--verify", "--quiet", "refs/remotes/origin/" .. name }) then
      return name
    end
  end

  local head = git_out({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
  return head and head:gsub("^origin/", "") or nil
end

---Stages every change related to the code: tracked edits, deletions and new files,
---leaving untracked secrets and noise (.env, logs, swap files) out.
---@return string[]|nil staged nil when git add failed
---@return string[] skipped
function M.stage_related()
  -- vim.system keeps the NUL separators that vim.fn.system would mangle
  local status = vim
    .system({ "git", "status", "--porcelain=v1", "-z", "--untracked-files=all" }, { text = true })
    :wait()
  if status.code ~= 0 then
    return nil, {}
  end

  local stage, skipped = actions.related(actions.parse_status(status.stdout))
  if #stage == 0 then
    return stage, skipped
  end
  if not git_ok(vim.list_extend({ "add", "-A", "--" }, stage)) then
    return nil, skipped
  end
  return stage, skipped
end

---Stages related changes and reports what was left out.
function M.stage()
  if not in_repo() then
    return
  end
  local staged, skipped = M.stage_related()
  if not staged then
    return notify("git add failed.", vim.log.levels.ERROR)
  end
  local msg = ("Staged %d file(s)."):format(#staged)
  if #skipped > 0 then
    msg = msg .. "\nLeft out: " .. table.concat(skipped, ", ")
  end
  notify(msg)
end

local function create_branch(prefix)
  vim.ui.input({ prompt = "Branch name: " }, function(name)
    if not name then
      return
    end
    local branch = actions.branch_name(prefix, name)
    if not branch then
      return notify("Branch name is empty.", vim.log.levels.WARN)
    end
    run({ "switch", "-c", branch }, function()
      notify("Switched to new branch " .. branch)
    end)
  end)
end

---Asks for a prefix and a name, then creates and switches to the branch.
function M.new_branch()
  if not in_repo() then
    return
  end
  vim.ui.select(actions.PREFIXES, { prompt = "Branch type" }, function(prefix)
    if prefix then
      create_branch(prefix)
    end
  end)
end

---Pulls the current branch from its upstream.
function M.pull()
  if not in_repo() then
    return
  end
  local task = progress("Pulling…")
  run({ "pull" }, function(out)
    task:done("Pulled: " .. last_line(out))
  end, task)
end

---Pushes the current branch, setting the upstream on the first push. Never forces.
function M.push()
  if not in_repo() then
    return
  end
  local branch = M.current_branch()
  local task = progress("Pushing " .. branch .. "…")
  run(actions.push_args(M.has_upstream()), function()
    task:done("Pushed " .. branch)
  end, task)
end

---Fetches the base branch and merges it into the current one.
function M.sync()
  if not in_repo() then
    return
  end
  local base = M.default_branch()
  if not base then
    return notify("Could not find a base branch.", vim.log.levels.WARN)
  end
  local task = progress("Bringing in origin/" .. base .. "…")
  run({ "fetch", "origin", base }, function()
    task:update("Merging origin/" .. base .. "…")
    run({ "merge", "--no-edit", "origin/" .. base }, function(out)
      task:done("Merged origin/" .. base .. ": " .. last_line(out))
    end, task)
  end, task)
end

---Switches to the base branch and pulls it.
function M.home()
  if not in_repo() then
    return
  end
  local base = M.default_branch()
  if not base then
    return notify("Could not find a base branch.", vim.log.levels.WARN)
  end
  local task = progress("Switching to " .. base .. "…")
  run({ "switch", base }, function()
    task:update("Pulling " .. base .. "…")
    run({ "pull" }, function(out)
      task:done("On " .. base .. ": " .. last_line(out))
    end, task)
  end, task)
end

---Stashes every change, untracked files included.
function M.stash()
  if not in_repo() then
    return
  end
  run({ "stash", "push", "--include-untracked" }, function(out)
    notify(last_line(out))
  end)
end

---Brings back the latest stash.
function M.stash_pop()
  if not in_repo() then
    return
  end
  run({ "stash", "pop" }, function()
    notify("Stash restored.")
  end)
end

local function head_is_pushed()
  return M.has_upstream() and git_ok({ "merge-base", "--is-ancestor", "HEAD", "@{u}" })
end

---Undoes the last commit and keeps its changes staged. Refuses once the commit is pushed.
function M.undo_commit()
  if not in_repo() then
    return
  end
  if head_is_pushed() then
    return notify("Last commit is already pushed, not rewriting it.", vim.log.levels.WARN)
  end
  local subject = git_out({ "log", "-1", "--format=%s" }) or ""
  if
    vim.fn.confirm('Undo commit "' .. subject .. '"? Changes stay staged.', "&Yes\n&Cancel", 2) ~= 1
  then
    return
  end
  run({ "reset", "--soft", "HEAD~1" }, function()
    notify("Undid: " .. subject)
  end)
end

return M
