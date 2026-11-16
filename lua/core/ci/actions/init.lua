-- The CI run of the branch you stand on: what gh says about it, how the statusline names it and
-- the moment it finishes. Pure logic only.
local M = {}

-- how often gh is asked while a run is going and while nothing is, in milliseconds
M.RUNNING_POLL_MS = 30000
M.IDLE_POLL_MS = 120000
-- GitHub takes a moment to start the run a push triggers
M.AFTER_PUSH_MS = 15000

M.GLYPHS = { running = "󰑮", passed = "󰄬", failed = "󰅖" }

-- the failing step's last lines are where the error is, the rest of a log is setup noise
M.LOG_LINES = 40
M.FIELDS = "status,conclusion,workflowName,url,headSha,databaseId"

--- Reads the latest run from `gh run list --json` with M.FIELDS.
---@param stdout string|nil
---@return { state: "running"|"passed"|"failed", workflow: string, url: string, sha: string, id: integer|nil }|nil
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
    id = run.databaseId,
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

-- a log line is "job<TAB>step<TAB>2024-05-01T10:00:00.0000000Z text", colored with escapes
local function log_line(line)
  local job, step, rest = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
  if not job then
    return nil
  end
  -- the first line of a job carries a byte order mark before its timestamp
  local text = rest:gsub("^\239\187\191", "")
  text = text:gsub("^%d%d%d%d%-%d%d%-%d%dT[%d:%.]+Z%s?", ""):gsub("\27%[[%d;]*m", "")
  -- the runner's fold markers only group lines in the browser
  if text:match("^##%[(%a+)%]$") or text:match("^##%[endgroup%]") then
    return nil
  end
  text = text:gsub("^##%[group%]", ""):gsub("^##%[error%]", "error: ")
  return { job = job, step = step, text = text }
end

--- Trims `gh run view --log-failed` to the end of the first failing step, where the error lives.
---@param stdout string|nil
---@param max integer|nil lines to keep, M.LOG_LINES by default
---@return { title: string|nil, lines: string[] } title as "job › step", nil when the log is empty
function M.failed_excerpt(stdout, max)
  max = max or M.LOG_LINES
  local first, lines = nil, {}
  for raw in (stdout or ""):gmatch("[^\n]+") do
    local entry = log_line(raw)
    if entry then
      first = first or entry
      if entry.job == first.job and entry.step == first.step then
        table.insert(lines, entry.text)
      end
    end
  end
  if not first then
    return { title = nil, lines = {} }
  end
  -- the runner's cleanup after the error says nothing about it
  for index = #lines, 1, -1 do
    if lines[index]:match("^error: ") then
      lines = vim.list_slice(lines, 1, index)
      break
    end
  end
  -- gh says UNKNOWN STEP when it cannot tell the steps of a job apart
  local named = first.step ~= "" and first.step ~= "UNKNOWN STEP"
  return {
    title = named and ("%s › %s"):format(first.job, first.step) or first.job,
    lines = vim.list_slice(lines, math.max(1, #lines - max + 1), #lines),
  }
end

--- How long to wait before asking gh again.
---@param run { state: string }|nil
---@return integer
function M.poll_ms(run)
  return run and run.state == "running" and M.RUNNING_POLL_MS or M.IDLE_POLL_MS
end

return M
