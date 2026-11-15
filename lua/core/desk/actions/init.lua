-- Pure pieces of the desk: config merge, schedule, the claude command lines and what the
-- background sessions leave behind.
local M = {}

M.DEFAULT_CONFIG_PATH = "~/.claude/skills/desk/config.json"

M.DEFAULT_HASH_FILES = {
  "~/.claude/skills/ticket-analyze/team.tsv",
  "~/.claude/skills/ticket-analyze/contacts.tsv",
  "~/.config/nvim/.claude/commands/my-style.md",
}

M.DEFAULTS = {
  artifact_url = "",
  repos_dir = "~/Documents/GitHub",
  sync = {
    every_minutes = 15,
    work_hours = { 8, 19 },
    weekdays_only = true,
    check_model = "haiku",
    work_model = "opus",
  },
}

M.CHECK_TOOLS = {
  "Skill",
  "ToolSearch",
  "ArtifactData",
  "Read",
  "Bash(date *)",
}

M.CHECK_MCP = { "mcp__claude_ai_Atlassian_MCP__searchJiraIssuesUsingJql" }

M.WORK_TOOLS = {
  "Skill",
  "ToolSearch",
  "ArtifactData",
  "Read",
  "Grep",
  "Glob",
}

M.WORK_BASH = {
  "Bash(date *)",
  "Bash(git *)",
  "Bash(gh *)",
  "Bash(jq *)",
  "Bash(python3 -I *)",
  "Bash(~/.claude/skills/ticket-analyze/scripts/*)",
  "Bash(aws sts get-caller-identity*)",
  "Bash(aws logs filter-log-events*)",
  "Bash(aws lambda get-*)",
  "Bash(aws cloudfront get-*)",
  "Bash(aws cloudwatch get-metric-statistics*)",
}

M.WORK_MCP = {
  "mcp__claude_ai_Atlassian_MCP__searchJiraIssuesUsingJql",
  "mcp__claude_ai_Atlassian_MCP__getJiraIssue",
  "mcp__claude_ai_Atlassian_MCP__listJiraIssueComments",
  "mcp__claude_ai_Atlassian_MCP__executeRead",
  "mcp__claude_ai_Atlassian_MCP__discover",
}

---Merges a decoded config over the defaults, so a partial file still works.
---@param raw table|nil decoded config file
---@return table config with every key the desk reads
function M.merge_config(raw)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.DEFAULTS), raw or {})
end

---Tells whether a moment falls inside the configured work hours.
---@param now { hour: integer, wday: integer } os.date("*t") shape, wday 1 is Sunday
---@param cfg table merged config
---@return boolean
function M.in_work_hours(now, cfg)
  local sync = cfg.sync
  if sync.weekdays_only and (now.wday == 1 or now.wday == 7) then
    return false
  end
  local hours = sync.work_hours
  return now.hour >= hours[1] and now.hour < hours[2]
end

---Reads the session id `claude --bg` prints in its stop hint.
---@param stdout string
---@return string|nil id hex id, nil when the output has none
function M.parse_session_id(stdout)
  return (stdout or ""):match("claude stop (%x+)")
end

local function joined(...)
  local out = {}
  for _, list in ipairs({ ... }) do
    vim.list_extend(out, list)
  end
  return table.concat(out, " ")
end

---Permission rule letting a session write inside a folder. Edit rules cover Write too, and
---absolute paths take a leading "//" in permission rules.
---@param dir string absolute folder
---@return string
function M.edit_rule(dir)
  return ("Edit(/%s/**)"):format(dir)
end

local function bg_argv(model, name, dirs, tools, prompt)
  local argv = { "claude", "--bg", "--model", model, "--permission-mode", "dontAsk", "-n", name }
  for _, dir in ipairs(dirs) do
    vim.list_extend(argv, { "--add-dir", dir })
  end
  -- --add-dir and --allowedTools are variadic, so "--" keeps them from swallowing the prompt
  vim.list_extend(argv, { "--allowedTools", tools, "--", prompt })
  return argv
end

---Builds the command line of the cheap check session.
---@param cfg table merged config
---@param paths { state: string, skills: string }
---@param hash string inputs hash the check compares against the artifact
---@return string[]
function M.build_check_argv(cfg, paths, hash)
  local tools = joined(M.CHECK_TOOLS, { M.edit_rule(paths.state) }, M.CHECK_MCP)
  local prompt = ("/desk-sync check state_dir=%s inputs_hash=%s"):format(paths.state, hash)
  return bg_argv(cfg.sync.check_model, "desk-check", { paths.state, paths.skills }, tools, prompt)
end

---Builds the command line of the session that does the heavy work.
---@param cfg table merged config
---@param paths { state: string, skills: string, repos: string }
---@return string[]
function M.build_work_argv(cfg, paths)
  local tools = joined(M.WORK_TOOLS, { M.edit_rule(paths.state) }, M.WORK_BASH, M.WORK_MCP)
  local prompt = ("/desk-sync work state_dir=%s"):format(paths.state)
  local dirs = { paths.state, paths.skills, paths.repos }
  return bg_argv(cfg.sync.work_model, "desk-work", dirs, tools, prompt)
end

---Picks the folder a ticket gets implemented from.
---@param item { key: string, repo?: string }
---@param repos_dir string expanded folder holding the clones
---@param isdir fun(path: string): boolean
---@return string
function M.implement_target(item, repos_dir, isdir)
  if item.repo and item.repo ~= "" then
    local dir = repos_dir .. "/" .. item.repo
    if isdir(dir) then
      return dir
    end
  end
  return repos_dir
end

---Builds the command the implement terminal runs.
---@param key string ticket key
---@return string[]
function M.implement_cmd(key)
  return { "claude", ("/ticket-implement %s"):format(key) }
end

---Says in one line what the work session did.
---@param work table|nil decoded work.json
---@return string message
---@return boolean ok false when something failed or the file is missing
function M.work_summary(work)
  if not work then
    return "The work session left no result", false
  end
  local done, failed = work.done or {}, work.failed or {}
  local parts = {}
  if #done > 0 then
    table.insert(parts, "Ready: " .. table.concat(done, ", "))
  end
  for _, f in ipairs(failed) do
    table.insert(parts, ("%s failed: %s"):format(f.key, f.reason or "unknown"))
  end
  if #parts == 0 then
    return "Nothing to do", true
  end
  return table.concat(parts, "\n"), #failed == 0
end

---Joins the files the inputs hash covers, skipping missing ones.
---@param contents (string|nil)[] file contents in order, nil for a missing file
---@param count integer how many files were read, since nil holes hide the length
---@return string
function M.hash_input(contents, count)
  local present = {}
  for i = 1, count do
    if contents[i] then
      table.insert(present, contents[i])
    end
  end
  return table.concat(present, "\n\0\n")
end

---Minutes until the next scheduled check.
---@param last_ms number|nil uv time of the last check
---@param now_ms number
---@param every_minutes number
---@return integer
function M.minutes_left(last_ms, now_ms, every_minutes)
  if not last_ms then
    return 0
  end
  local left = every_minutes - (now_ms - last_ms) / 60000
  return math.max(0, math.ceil(left))
end

---Command line that finds the open PRs mentioning a ticket in the org.
---@param key string ticket key
---@param org string GitHub org or user that owns the repos
---@return string[]
function M.pr_search_argv(key, org)
  return {
    "gh",
    "search",
    "prs",
    key,
    "--owner",
    org,
    "--state",
    "open",
    "--json",
    "number,title,url,repository",
  }
end

---Turns gh search results into review targets, each with the local clone it runs from.
---@param prs table[] decoded output of pr_search_argv
---@param repos_dir string expanded folder holding the clones
---@param isdir fun(path: string): boolean
---@return { number: integer, title: string, url: string, repo: string, dir: string|nil }[]
function M.review_targets(prs, repos_dir, isdir)
  local out = {}
  for _, pr in ipairs(prs or {}) do
    local repo = pr.repository and pr.repository.name or ""
    local dir = repos_dir .. "/" .. repo
    table.insert(out, {
      number = pr.number,
      title = pr.title or "",
      url = pr.url or "",
      repo = repo,
      dir = repo ~= "" and isdir(dir) and dir or nil,
    })
  end
  return out
end

return M
