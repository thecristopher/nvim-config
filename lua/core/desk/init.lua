-- The manager desk: opens the desk artifact and keeps it fed. A cheap background Claude session
-- checks the artifact's queue and the board every few minutes, and only when there is real work
-- (analyses, replies) a second session does it. Implement requests open a tab here.
local actions = require("core.desk.actions")

local M = {}

local STATE = vim.fn.stdpath("state") .. "/eldentree_desk"
local POLL_MS = 5000
local CHECK_TIMEOUT_MS = 10 * 60 * 1000
local WORK_TIMEOUT_MS = 30 * 60 * 1000

local running = { check = false, work = false }
local last = { check = nil, work = nil, check_at = nil, work_at = nil }
local schedule_timer

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Desk", id = "eldentree_desk_note" })
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded and data or nil
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand(path))
  return ok and table.concat(lines, "\n") or nil
end

---Loads the private config, or nil with the reason the desk stays quiet.
---@return table|nil config
---@return string|nil reason
function M.config()
  if vim.g.eldentree_desk == false then
    return nil, "the desk is off (vim.g.eldentree_desk = false)"
  end
  local path = vim.fn.expand(vim.g.eldentree_desk_config or actions.DEFAULT_CONFIG_PATH)
  if vim.fn.filereadable(path) == 0 then
    return nil, "no desk config at " .. path
  end
  local raw = read_json(path)
  if not raw then
    return nil, "the desk config at " .. path .. " is not valid JSON"
  end
  return actions.merge_config(raw)
end

local function paths(cfg)
  return {
    state = STATE,
    skills = vim.fn.expand("~/.claude/skills"),
    repos = vim.fn.expand(cfg.repos_dir),
  }
end

local function inputs_hash(cfg)
  local files = cfg.hash_files or actions.DEFAULT_HASH_FILES
  local contents = {}
  for i, file in ipairs(files) do
    contents[i] = read_file(file)
  end
  return vim.fn.sha256(actions.hash_input(contents, #files))
end

local function quietly(argv, cb)
  vim.system(argv, { text = true }, cb and vim.schedule_wrap(cb) or nil)
end

local function end_session(id)
  if not id then
    return
  end
  quietly({ "claude", "stop", id }, function()
    quietly({ "claude", "rm", id })
  end)
end

-- polls with a cheap stat, never a claude call, so waiting costs nothing
local function wait_for(file, timeout_ms, cb)
  local timer = vim.uv.new_timer()
  local waited = 0
  timer:start(POLL_MS, POLL_MS, function()
    waited = waited + POLL_MS
    local found = vim.uv.fs_stat(file) ~= nil
    if not found and waited < timeout_ms then
      return
    end
    timer:stop()
    timer:close()
    vim.schedule(function()
      cb(found)
    end)
  end)
end

local function start_bg(argv, cb)
  local root = vim.fn.resolve(vim.fn.stdpath("config"))
  vim.system(argv, { cwd = root, text = true }, function(res)
    local id = actions.parse_session_id(res.stdout or "")
    vim.schedule(function()
      cb(id, res)
    end)
  end)
end

---Opens a tab in the ticket's repo with Claude implementing it.
---@param key string ticket key
---@param repo? string repo folder name under repos_dir
function M.implement(key, repo)
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  local repos = vim.fn.expand(cfg.repos_dir)
  local dir = actions.implement_target({ key = key, repo = repo }, repos, function(p)
    return vim.fn.isdirectory(p) == 1
  end)
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(dir))
  vim.fn.jobstart(actions.implement_cmd(key), { term = true, cwd = dir })
  vim.cmd.startinsert()
  notify("Implementing " .. key)
end

---Opens a tab in the PR's repo and has Claude review it with core.review.
---@param target { number: integer, repo: string, dir: string|nil, title: string }
local function review_target(target)
  if not target.dir then
    notify(
      ("Clone %s into the repos folder to review PR #%d"):format(target.repo, target.number),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(target.dir))
  require("core.review").review(target.number)
end

---Finds the open PR that mentions a ticket and reviews it, asking when there are several.
---@param key string ticket key
function M.review(key)
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  if (cfg.github_org or "") == "" then
    notify("Set github_org in the desk config to find the PRs of a ticket", vim.log.levels.WARN)
    return
  end
  vim.system(
    actions.pr_search_argv(key, cfg.github_org),
    { text = true },
    vim.schedule_wrap(function(res)
      local ok, prs = pcall(vim.json.decode, res.stdout or "")
      if res.code ~= 0 or not ok then
        notify("gh could not search the PRs of " .. key, vim.log.levels.WARN)
        return
      end
      local targets = actions.review_targets(prs, vim.fn.expand(cfg.repos_dir), function(p)
        return vim.fn.isdirectory(p) == 1
      end)
      if #targets == 0 then
        notify("No open PR mentions " .. key)
        return
      end
      if #targets == 1 then
        return review_target(targets[1])
      end
      vim.ui.select(targets, {
        prompt = "Review which PR of " .. key,
        format_item = function(t)
          return ("%s #%d  %s"):format(t.repo, t.number, t.title)
        end,
      }, function(choice)
        if choice then
          review_target(choice)
        end
      end)
    end)
  )
end

local function offer_review(items)
  for _, item in ipairs(items or {}) do
    M.review(item.key)
  end
end

local function offer_implement(items)
  for _, item in ipairs(items or {}) do
    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
      notify(("%s is ready to implement, run :DeskImplement %s"):format(item.key, item.key))
    else
      M.implement(item.key, item.repo)
    end
  end
end

local function finish_work(id, task, found)
  running.work = false
  end_session(id)
  last.work_at = os.date("%H:%M")
  if not found then
    task:fail("The work session did not finish in time")
    return
  end
  local message, ok = actions.work_summary(read_json(STATE .. "/work.json"))
  if ok then
    task:done(message)
  else
    task:fail(message)
  end
end

local function start_work(cfg, work)
  if running.work then
    return
  end
  running.work = true
  vim.fn.delete(STATE .. "/work.json")
  local task = require("core.progress").start({
    id = "eldentree_desk",
    title = "Desk",
    message = ("Analyzing %d %s"):format(#work, #work == 1 and "ticket" or "tickets"),
  })
  start_bg(actions.build_work_argv(cfg, paths(cfg)), function(id, res)
    if not id then
      running.work = false
      task:fail("Could not start the work session: " .. vim.trim(res.stderr or ""))
      return
    end
    wait_for(STATE .. "/work.json", WORK_TIMEOUT_MS, function(found)
      finish_work(id, task, found)
    end)
  end)
end

local function finish_check(cfg, id, found)
  running.check = false
  end_session(id)
  last.check_at = os.date("%H:%M")
  local result = found and read_json(STATE .. "/check.json") or nil
  if not result then
    notify("The desk check left no result", vim.log.levels.WARN)
    return
  end
  if result.error then
    notify("Desk check: " .. result.error, vim.log.levels.WARN)
  end
  offer_implement(result.implement)
  offer_review(result.review)
  if result.work and #result.work > 0 then
    start_work(cfg, result.work)
  end
end

---Runs the cheap check now: reads the queue and the board, then hands off any real work.
function M.check()
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  if running.check then
    return
  end
  running.check = true
  last.check = vim.uv.now()
  vim.fn.mkdir(STATE, "p")
  vim.fn.delete(STATE .. "/check.json")
  start_bg(actions.build_check_argv(cfg, paths(cfg), inputs_hash(cfg)), function(id, res)
    if not id then
      running.check = false
      notify("Could not start the desk check: " .. vim.trim(res.stderr or ""), vim.log.levels.WARN)
      return
    end
    wait_for(STATE .. "/check.json", CHECK_TIMEOUT_MS, function(found)
      finish_check(cfg, id, found)
    end)
  end)
end

local function tick()
  local cfg = M.config()
  if not cfg or vim.g.eldentree_desk_paused then
    return
  end
  if actions.in_work_hours(os.date("*t"), cfg) then
    M.check()
  end
end

---Opens the desk artifact in the browser.
function M.open()
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  if cfg.artifact_url == "" then
    notify("Set artifact_url in the desk config to the published desk link", vim.log.levels.WARN)
    return
  end
  vim.ui.open(cfg.artifact_url)
end

---Says when the desk last checked and worked, and when it checks next.
function M.status()
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  local left = actions.minutes_left(last.check, vim.uv.now(), cfg.sync.every_minutes)
  notify(table.concat({
    ("Last check: %s%s"):format(last.check_at or "never", running.check and " (running)" or ""),
    ("Last work: %s%s"):format(last.work_at or "never", running.work and " (running)" or ""),
    ("Next check in %d min%s"):format(
      left,
      actions.in_work_hours(os.date("*t"), cfg) and "" or ", outside work hours"
    ),
  }, "\n"))
end

local SUBCOMMANDS = { open = M.open, sync = M.check, status = M.status }

local function command(opts)
  local run = SUBCOMMANDS[opts.args ~= "" and opts.args or "open"]
  if not run then
    notify("Usage: :Desk [open|sync|status]", vim.log.levels.WARN)
    return
  end
  run()
end

local function start_schedule()
  local cfg = M.config()
  if not cfg or schedule_timer then
    return
  end
  schedule_timer = vim.uv.new_timer()
  local every = cfg.sync.every_minutes * 60 * 1000
  schedule_timer:start(20 * 1000, every, vim.schedule_wrap(tick))
end

function M.setup()
  vim.api.nvim_create_user_command("Desk", command, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(SUBCOMMANDS)
    end,
    desc = "Open the desk, sync it now or see its status",
  })
  vim.api.nvim_create_user_command("DeskImplement", function(opts)
    M.implement(opts.fargs[1], opts.fargs[2])
  end, { nargs = "+", desc = "Implement a ticket in a new tab: KEY [repo]" })
  vim.api.nvim_create_user_command("DeskReview", function(opts)
    M.review(opts.fargs[1])
  end, { nargs = 1, desc = "Review the open PR of a ticket in a new tab: KEY" })
  start_schedule()
end

return M
