-- The manager desk: opens the Desk app (or the artifact in the browser) and the tabs it asks for.
-- Opening it asks for a work session that syncs and runs whatever the page queued. nvim watches the
-- inbox the page and that session fill, opens implement and review tabs from it and leaves what it
-- did in the outbox, where the desk bridge picks it up for the page.
local actions = require("core.desk.actions")

local M = {}

local inbox_watch = nil

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

local function state_dir(cfg)
  if cfg.state_dir ~= "" then
    return vim.fn.expand(cfg.state_dir)
  end
  return vim.fn.stdpath("state") .. "/eldentree_desk"
end

---The short id of the desk's background work session, so its hooks stay quiet.
---@return string[]
function M.session_ids()
  local cfg = M.config()
  if not cfg then
    return {}
  end
  local ok, lines = pcall(vim.fn.readfile, state_dir(cfg) .. "/work.lock", "", 1)
  return { ok and lines[1] and lines[1]:match("^(%x+)") or "" }
end

-- launchd watches this file and starts a work session when it changes
local function wake(cfg)
  require("core.utils").write_state(state_dir(cfg) .. "/wake", { os.date("!%Y-%m-%dT%H:%M:%SZ") })
end

-- says what happened in nvim, and hands it to whoever asked (the page through the outbox)
local function tell(done, msg, level)
  notify(msg, level)
  if done then
    done(msg)
  end
end

---Opens a tab in the ticket's repo with Claude implementing it.
---@param key string ticket key
---@param repo? string repo folder name under repos_dir
---@param done? fun(msg: string) told what happened
function M.implement(key, repo, done)
  local cfg, reason = M.config()
  if not cfg then
    return tell(done, reason, vim.log.levels.WARN)
  end
  local repos = vim.fn.expand(cfg.repos_dir)
  local dir = actions.implement_target({ key = key, repo = repo }, repos, function(p)
    return vim.fn.isdirectory(p) == 1
  end)
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(dir))
  vim.fn.jobstart(actions.implement_cmd(key), { term = true, cwd = dir })
  vim.cmd.startinsert()
  tell(done, ("Implementing %s in %s"):format(key, vim.fn.fnamemodify(dir, ":t")))
end

---Opens a tab in the PR's repo and has Claude review it with core.review.
---@param target { number: integer, repo: string, dir: string|nil, title: string }
---@param done? fun(msg: string)
local function review_target(target, done)
  if not target.dir then
    local msg = ("Clone %s into the repos folder to review PR #%d"):format(
      target.repo,
      target.number
    )
    return tell(done, msg, vim.log.levels.WARN)
  end
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(target.dir))
  require("core.review").review(target.number)
  tell(done, ("Reviewing %s #%d"):format(target.repo, target.number))
end

local function decode(res)
  local ok, data = pcall(vim.json.decode, res.stdout or "")
  return res.code == 0 and ok and data or nil
end

---Finds open PRs from the branches of the local clones whose name holds the key.
---@param cfg table desk config with repos_dir already expanded
---@param key string ticket key
---@param cb fun(prs: table[])
local function prs_by_branch(cfg, key, cb)
  vim.system(actions.branch_scan_argv(cfg.repos_dir, key), { text = true }, function(res)
    local hits = actions.branch_hits(res.stdout)
    local found, left = {}, #hits
    if left == 0 then
      return cb(found)
    end
    for _, hit in ipairs(hits) do
      vim.system(actions.pr_by_branch_argv(cfg.github_org, hit), { text = true }, function(pr)
        vim.list_extend(found, actions.with_repo(decode(pr) or {}, hit.repo))
        left = left - 1
        if left == 0 then
          cb(found)
        end
      end)
    end
  end)
end

---Finds the open PRs of a ticket: those that mention its key, else those on a branch named after it.
---@param cfg table desk config with repos_dir already expanded, the callbacks cannot call vim.fn
---@param key string ticket key
---@param cb fun(prs: table[]|nil) nil when gh could not search
local function find_prs(cfg, key, cb)
  vim.system(actions.pr_search_argv(key, cfg.github_org), { text = true }, function(res)
    local prs = decode(res)
    if not prs or #prs > 0 then
      return cb(prs)
    end
    prs_by_branch(cfg, key, cb)
  end)
end

---Reviews one of several PRs, asking which.
local function pick_target(key, targets, done)
  tell(done, ("Asked in nvim which of %d PRs of %s to review"):format(#targets, key))
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
end

---Finds the open PR of a ticket and reviews it, asking when there are several.
---@param key string ticket key
---@param done? fun(msg: string) told what happened
function M.review(key, done)
  local cfg, reason = M.config()
  if not cfg then
    return tell(done, reason, vim.log.levels.WARN)
  end
  if (cfg.github_org or "") == "" then
    return tell(
      done,
      "Set github_org in the desk config to find the PRs of a ticket",
      vim.log.levels.WARN
    )
  end
  local repos = vim.fn.expand(cfg.repos_dir)
  find_prs(
    vim.tbl_extend("force", cfg, { repos_dir = repos }),
    key,
    vim.schedule_wrap(function(prs)
      if not prs then
        return tell(done, "gh could not search the PRs of " .. key, vim.log.levels.WARN)
      end
      local targets = actions.review_targets(prs, repos, function(p)
        return vim.fn.isdirectory(p) == 1
      end)
      if #targets == 0 then
        return tell(done, ("No open PR for %s, by key or by branch"):format(key))
      end
      if #targets == 1 then
        return review_target(targets[1], done)
      end
      pick_target(key, targets, done)
    end)
  )
end

---Leaves what nvim did with a request in the outbox, where the desk bridge waits to tell the page.
---@param dir string the state folder
---@param queue_id string|nil
---@param msg string
local function report(dir, queue_id, msg)
  if not queue_id then
    return
  end
  local outbox = dir .. "/outbox"
  vim.fn.mkdir(outbox, "p")
  local part = ("%s/%s.json.part"):format(outbox, queue_id)
  require("core.utils").write_state(part, { vim.json.encode({ text = msg }) })
  vim.uv.fs_rename(part, ("%s/%s.json"):format(outbox, queue_id))
end

local function open_item(item, state)
  local done = function(msg)
    report(state, item.queue_id, msg)
  end
  -- a tab popping up mid sentence would steal the typing, so say it instead
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    local cmd = item.kind == "implement" and "DeskImplement" or "DeskReview"
    return tell(done, ("%s is ready in nvim, run :%s %s"):format(item.key, cmd, item.key))
  end
  if item.kind == "implement" then
    M.implement(item.key, item.repo, done)
  else
    M.review(item.key, done)
  end
end

---Opens every request the work session left in the inbox and removes its file.
---@param dir string the inbox folder
local function drain_inbox(dir)
  for _, file in ipairs(vim.fn.glob(dir .. "/*.json", false, true)) do
    -- every open nvim watches the inbox, the rename lets only one of them take each request
    local claimed = file .. "." .. vim.uv.os_getpid()
    if vim.uv.fs_rename(file, claimed) then
      local item = actions.inbox_item(read_json(claimed))
      vim.fn.delete(claimed)
      if item then
        open_item(item, vim.fn.fnamemodify(dir, ":h"))
      end
    end
  end
end

local function watch_inbox(cfg)
  if inbox_watch then
    return
  end
  local dir = state_dir(cfg) .. "/inbox"
  vim.fn.mkdir(dir, "p")
  drain_inbox(dir)
  inbox_watch = vim.uv.new_fs_event()
  -- the work session writes the file in one go, a short pause lets the write land before reading
  local timer = vim.uv.new_timer()
  inbox_watch:start(dir, {}, function()
    timer:stop()
    timer:start(
      200,
      0,
      vim.schedule_wrap(function()
        drain_inbox(dir)
      end)
    )
  end)
end

local function installed()
  for _, plist in ipairs(actions.LAUNCH_AGENTS) do
    if vim.fn.filereadable(vim.fn.expand(plist)) == 0 then
      return false
    end
  end
  return true
end

---Opens the Desk app, or the artifact in the browser when the app is not installed, and asks for a sync.
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
  vim.system(actions.open_argv(cfg, function(p)
    return vim.uv.fs_stat(p) ~= nil
  end))
  if installed() then
    wake(cfg)
  end
end

---Asks for a sync now: launchd sees the wake file change and starts a work session.
function M.sync()
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  if not installed() then
    notify(actions.status_lines({ installed = false, inbox = 0 })[1], vim.log.levels.WARN)
    return
  end
  wake(cfg)
  notify("Sync requested, the work session starts in a few seconds")
end

local function minutes_old(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  return math.floor((os.time() - stat.mtime.sec) / 60)
end

local function session_age(id_file)
  local ok, lines = pcall(vim.fn.readfile, id_file)
  if not ok or not lines[1] then
    return nil, nil
  end
  local id, started = lines[1]:match("^(%x+) (%d+)")
  if not id then
    return nil, nil
  end
  local transcripts =
    vim.fn.glob(vim.fn.expand("~/.claude/projects/*/") .. id .. "*.jsonl", false, true)
  return math.floor((os.time() - tonumber(started)) / 60),
    transcripts[1] and minutes_old(transcripts[1])
end

---Says what the work session is doing and what waits in the inbox.
function M.status()
  local cfg, reason = M.config()
  if not cfg then
    notify(reason, vim.log.levels.WARN)
    return
  end
  local dir = state_dir(cfg)
  local work_age = session_age(dir .. "/work.lock")
  local work = read_json(dir .. "/work.json")
  local lock = vim.uv.fs_stat(dir .. "/work.lock")
  local result = vim.uv.fs_stat(dir .. "/work.json")
  -- work.sh leaves the lock until its next run, a newer result means that session ended
  if lock and result and result.mtime.sec >= lock.mtime.sec then
    work_age = nil
  end
  notify(table.concat(
    actions.status_lines({
      installed = installed(),
      work_age_min = work_age,
      work_finished_at = work and work.finished_at or nil,
      inbox = #vim.fn.glob(dir .. "/inbox/*.json", false, true),
    }),
    "\n"
  ))
end

local SUBCOMMANDS = { open = M.open, sync = M.sync, status = M.status }

local function command(opts)
  local run = SUBCOMMANDS[opts.args ~= "" and opts.args or "open"]
  if not run then
    notify("Usage: :Desk [open|sync|status]", vim.log.levels.WARN)
    return
  end
  run()
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
  local cfg = M.config()
  if cfg then
    watch_inbox(cfg)
  end
end

return M
