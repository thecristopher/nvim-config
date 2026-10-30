-- The CI run of the branch you stand on: what gh says about it, how the statusline names it and
-- the moment it finishes. Pure logic only.
local M = {}

-- how often gh is asked while a run is going and while nothing is, in milliseconds
M.RUNNING_POLL_MS = 30000
M.IDLE_POLL_MS = 120000
-- GitHub takes a moment to start the run a push triggers
M.AFTER_PUSH_MS = 15000

M.GLYPHS = { running = "󰑮", passed = "󰄬", failed = "󰅖" }

--- Reads the latest run from `gh run list --json status,conclusion,workflowName,url,headSha`.
---@param stdout string|nil
---@return { state: "running"|"passed"|"failed", workflow: string, url: string, sha: string }|nil
function M.parse(stdout)
  local ok, runs = pcall(vim.json.decode, stdout or "")
  if not ok or type(runs) ~= "table" or not runs[1] then
    return nil
  end
  local run = runs[1]
  local state = "running"
  if run.status == "completed" then
    state = run.conclusion == "success" and "passed" or "failed"
  end
  return {
    state = state,
    workflow = run.workflowName or "",
    url = run.url or "",
    sha = run.headSha or "",
  }
end

--- The statusline text for a run, empty when there is none.
---@param run { state: string }|nil
---@param words { running: string, passed: string, failed: string }
---@return string
function M.label(run, words)
  if not run then
    return ""
  end
  return ("%s %s"):format(M.GLYPHS[run.state], words[run.state])
end

--- Tells whether a run just finished, the moment the verdict deserves a banner.
--- A run that was already done when nvim first saw it was announced long ago.
---@param before { state: string, sha: string }|nil
---@param after { state: string, sha: string }|nil
---@return "passed"|"failed"|nil
function M.finished(before, after)
  if not before or not after or after.state == "running" then
    return nil
  end
  local same_run = before.sha == after.sha
  if same_run and before.state == "running" then
    return after.state
  end
  return nil
end

--- How long to wait before asking gh again.
---@param run { state: string }|nil
---@return integer
function M.poll_ms(run)
  return run and run.state == "running" and M.RUNNING_POLL_MS or M.IDLE_POLL_MS
end

return M
