-- The manager desk: opens the desk artifact and opens the tabs it asks for. Opening it asks for one
-- work session that syncs and runs whatever the page queued, nothing runs between visits. nvim
-- watches the inbox that session fills, so implement and review requests open a tab here.
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

local function open_item(item)
  -- a tab popping up mid sentence would steal the typing, so say it instead
  if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
    local cmd = item.kind == "implement" and "DeskImplement" or "DeskReview"
    notify(("%s is ready, run :%s %s"):format(item.key, cmd, item.key))
    return
  end
  if item.kind == "implement" then
    M.implement(item.key, item.repo)
  else
    M.review(item.key)
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
        open_item(item)
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

---Opens the desk artifact in the browser and asks for the one sync of this visit.
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
