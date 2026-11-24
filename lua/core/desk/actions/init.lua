-- Pure pieces of the desk: config merge, the inbox the listener fills, the status line and the
-- implement and review targets.
local M = {}

M.DEFAULT_CONFIG_PATH = "~/.claude/skills/desk/config.json"

-- the scripts behind the listener and the work sessions live with the skill
M.SCRIPTS_DIR = "~/.claude/skills/desk-sync/scripts"

M.LAUNCH_AGENTS = {
  "~/Library/LaunchAgents/com.cristopher.desk-listener.plist",
  "~/Library/LaunchAgents/com.cristopher.desk-work.plist",
}

M.DEFAULTS = {
  artifact_url = "",
  repos_dir = "~/Documents/GitHub",
  -- empty means nvim's own state folder, the scripts fall back to the same one
  state_dir = "",
  sync = {
    listen_model = "haiku",
    work_model = "opus",
  },
}

-- the listener ticks every minute, so this long without one means it is gone
local LISTENER_QUIET_MIN = 5

---Merges a decoded config over the defaults, so a partial file still works.
---@param raw table|nil decoded config file
---@return table config with every key the desk reads
function M.merge_config(raw)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.DEFAULTS), raw or {})
end

---Turns a decoded inbox file into an item nvim can act on.
---@param raw any decoded `<state>/inbox/<id>.json`
---@return { kind: "implement"|"review", key: string, repo: string|nil, queue_id: string|nil }|nil item nil when the file is not usable
function M.inbox_item(raw)
  if type(raw) ~= "table" then
    return nil
  end
  if raw.kind ~= "implement" and raw.kind ~= "review" then
    return nil
  end
  if type(raw.key) ~= "string" or raw.key == "" then
    return nil
  end
  local repo = type(raw.repo) == "string" and raw.repo ~= "" and raw.repo or nil
  return { kind = raw.kind, key = raw.key, repo = repo, queue_id = raw.queue_id }
end

---Describes the listener from its id file and transcript.
---@param s { paused: boolean, listener_age_min: integer|nil, listener_quiet_min: integer|nil }
---@return string
local function listener_line(s)
  if s.paused then
    return "Listener: paused. :Desk resume starts it again"
  end
  if not s.listener_age_min then
    return "Listener: not running. Opening the desk with :Desk starts it"
  end
  if (s.listener_quiet_min or 0) >= LISTENER_QUIET_MIN then
    return ("Listener: silent for %d min, launchd restarts it shortly"):format(s.listener_quiet_min)
  end
  return ("Listener: up for %d min, checking the queue every minute while the desk is open"):format(
    s.listener_age_min
  )
end

---Describes the work session from its lock and result files.
---@param s { work_age_min: integer|nil, work_finished_at: string|nil }
---@return string
local function work_line(s)
  if s.work_age_min then
    return ("Work: running for %d min"):format(s.work_age_min)
  end
  return ("Work: idle, last finished %s"):format(s.work_finished_at or "never")
end

---Builds the lines :Desk status shows.
---@param s { installed: boolean, paused: boolean, listener_age_min: integer|nil, listener_quiet_min: integer|nil, work_age_min: integer|nil, work_finished_at: string|nil, inbox: integer }
---@return string[]
function M.status_lines(s)
  if not s.installed then
    return { "The desk agents are not installed. Run " .. M.SCRIPTS_DIR .. "/install.sh" }
  end
  local lines = { listener_line(s), work_line(s) }
  if s.inbox > 0 then
    table.insert(lines, ("Inbox: %d waiting to open"):format(s.inbox))
  end
  return lines
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
