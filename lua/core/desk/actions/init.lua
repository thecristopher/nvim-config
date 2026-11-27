-- Pure pieces of the desk: config merge, the inbox the work session fills, the status line and the
-- implement and review targets.
local M = {}

M.DEFAULT_CONFIG_PATH = "~/.claude/skills/desk/config.json"

-- the scripts behind the work sessions live with the skill
M.SCRIPTS_DIR = "~/.claude/skills/desk-sync/scripts"

M.LAUNCH_AGENTS = {
  "~/Library/LaunchAgents/com.cristopher.desk-work.plist",
}

M.DEFAULTS = {
  artifact_url = "",
  -- the Desk installed as an app of the Claude desktop app, the only place its buttons reach this Mac
  app_name = "KTLO Desk",
  repos_dir = "~/Documents/GitHub",
  -- empty means nvim's own state folder, the scripts fall back to the same one
  state_dir = "",
  sync = {
    work_model = "opus",
  },
}

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
  -- the id names the outbox file, so it can never hold a path
  local id = type(raw.queue_id) == "string" and raw.queue_id:match("^[%w_-]+$") or nil
  return { kind = raw.kind, key = raw.key, repo = repo, queue_id = id }
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
---@param s { installed: boolean, work_age_min: integer|nil, work_finished_at: string|nil, inbox: integer }
---@return string[]
function M.status_lines(s)
  if not s.installed then
    return { "The desk agent is not installed. Run " .. M.SCRIPTS_DIR .. "/install.sh" }
  end
  local lines = { work_line(s) }
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

---Where the Claude desktop app installs the Desk app.
---@param name string app name, the page's title
---@return string
function M.app_path(name)
  return ("~/Applications/Claude Apps/%s.app"):format(name)
end

---Command line that opens the Desk: its app when installed, else the artifact in the browser.
---@param cfg table merged desk config
---@param app_exists fun(path: string): boolean
---@return string[]
function M.open_argv(cfg, app_exists)
  local app = cfg.app_name ~= "" and vim.fn.expand(M.app_path(cfg.app_name)) or ""
  if app ~= "" and app_exists(app) then
    return { "open", app }
  end
  return { "open", cfg.artifact_url }
end

---Shell command that lists the local and remote branches of every clone whose name holds the key.
---@param repos_dir string expanded folder holding the clones
---@param key string ticket key
---@return string[] prints one "repo<TAB>branch" line per hit
function M.branch_scan_argv(repos_dir, key)
  local script = [[for d in "$1"/*/; do
  r=$(basename "$d")
  git -C "$d" branch -a --list "*$2*" --format='%(refname:short)' 2>/dev/null | sed "s|^|$r	|"
done]]
  return { "sh", "-c", script, "sh", repos_dir, key }
end

---Turns branch scan output into unique repo and branch pairs, remote names dropped.
---@param stdout string output of branch_scan_argv
---@return { repo: string, branch: string }[]
function M.branch_hits(stdout)
  local out, seen = {}, {}
  for line in (stdout or ""):gmatch("[^\n]+") do
    local repo, branch = line:match("^([^\t]+)\t(.+)$")
    branch = branch and branch:gsub("^origin/", "")
    local id = repo and (repo .. "\t" .. branch)
    if id and branch ~= "HEAD" and branch ~= "origin" and not seen[id] then
      seen[id] = true
      table.insert(out, { repo = repo, branch = branch })
    end
  end
  return out
end

---Command line that finds the open PR of a branch in one repo.
---@param org string GitHub org or user that owns the repos
---@param hit { repo: string, branch: string }
---@return string[]
function M.pr_by_branch_argv(org, hit)
  return {
    "gh",
    "pr",
    "list",
    "-R",
    org .. "/" .. hit.repo,
    "--head",
    hit.branch,
    "--state",
    "open",
    "--json",
    "number,title,url",
  }
end

---Gives gh pr list results the repository field gh search returns, so both feed review_targets.
---@param prs table[] decoded output of pr_by_branch_argv
---@param repo string repo the list ran in
---@return table[]
function M.with_repo(prs, repo)
  local out = {}
  for _, pr in ipairs(prs or {}) do
    table.insert(out, vim.tbl_extend("force", pr, { repository = { name = repo } }))
  end
  return out
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
