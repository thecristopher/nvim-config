-- The branch's CI run in the statusline, asked to gh in the background. A run that finishes while
-- you work gets its verdict as a banner, :CI or <leader>gi opens it in the browser.
local actions = require("core.ci.actions")

local M = {}

local run = nil
local root = nil
local branch = nil
local timer = nil
local asking = false
local focused = true

local function enabled()
  return vim.g.eldentree_ci ~= false and vim.fn.executable("gh") == 1
end

local function words()
  return require("core.franchise").current().ci
end

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenCiRunning", { fg = p.yellow })
  vim.api.nvim_set_hl(0, "EldenCiPassed", { fg = p.green })
  vim.api.nvim_set_hl(0, "EldenCiFailed", { fg = p.red, bold = true })
end

local GROUPS = { running = "EldenCiRunning", passed = "EldenCiPassed", failed = "EldenCiFailed" }

local function announce(verdict)
  local text = words()[verdict]
  if verdict == "passed" then
    require("core.banner").show("felled", { subtitle = text })
  else
    require("core.banner").show("died", { subtitle = text })
  end
  require("core.voice").say("ci_" .. verdict, { branch = branch })
end

local function settle(next_run)
  local verdict = actions.finished(run, next_run)
  run = next_run
  require("core.utils").refresh_statusline()
  if verdict then
    announce(verdict)
  end
end

local schedule

--- Asks gh for the latest run of the branch, in the background.
function M.check()
  if not enabled() or asking then
    return
  end
  root = require("core.repos").root()
  -- read from .git/HEAD, a git process here would block every FocusGained
  branch = root and require("core.repos").branch(root)
  if not branch then
    run = nil
    return
  end
  asking = true
  vim.system(
    { "gh", "run", "list", "--branch", branch, "--limit", "1", "--json", actions.FIELDS },
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      asking = false
      settle(result.code == 0 and actions.parse(result.stdout) or nil)
      schedule()
    end)
  )
end

-- the next question waits longer while nothing runs, and none goes out while nvim is unfocused
schedule = function()
  if not timer then
    return
  end
  timer:stop()
  timer:start(
    actions.poll_ms(run),
    0,
    vim.schedule_wrap(function()
      if focused then
        M.check()
      end
    end)
  )
end

--- Asks again a little after a push, once GitHub had the time to start the new run.
function M.soon()
  vim.defer_fn(M.check, actions.AFTER_PUSH_MS)
end

--- The statusline piece: the run's state in the franchise's words, empty without a run.
---@return string
function M.statusline()
  if not run then
    return ""
  end
  return ("%%#%s#%s%%*"):format(GROUPS[run.state], actions.label(run, words()))
end

local function show_log(excerpt, url)
  local lines = #excerpt.lines > 0 and excerpt.lines or { "gh returned no log for this run" }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local width = math.min(vim.o.columns - 8, 120)
  local height = math.min(#lines, vim.o.lines - 8)
  local title = words().failed .. (excerpt.title and ("  ·  " .. excerpt.title) or "")
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = require("core.skin").border(),
    title = " " .. require("core.skin").title(title) .. " ",
    title_pos = "center",
    footer = " o open in the browser  ·  q close ",
    footer_pos = "center",
  })
  -- the error is at the end of the step
  vim.api.nvim_win_set_cursor(win, { #lines, 0 })
  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "o", function()
    close()
    vim.ui.open(url)
  end, { buffer = buf, nowait = true })
end

-- a failed run explains itself: the end of the step that broke, asked to gh in the background
local function open_failed()
  local task = require("core.progress").start({
    id = "eldentree_ci_log",
    title = "CI",
    message = "Reading the failed step…",
  })
  vim.system(
    { "gh", "run", "view", tostring(run.id), "--log-failed" },
    { cwd = root, text = true, timeout = 30000 },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        task:fail("gh could not read the log, opening the run instead")
        return vim.ui.open(run.url)
      end
      task:done(words().failed)
      show_log(actions.failed_excerpt(result.stdout), run.url)
    end)
  )
end

--- Opens the latest run: the failing step's log when it failed, the browser otherwise.
function M.open()
  if run and run.state == "failed" and run.id then
    return open_failed()
  end
  if run and run.url ~= "" then
    return vim.ui.open(run.url)
  end
  vim.notify("No CI run on this branch yet", vim.log.levels.INFO, { title = "CI" })
  M.check()
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_ci", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      focused = false
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      focused = true
      M.check()
    end,
  })
  -- a new repo or a new branch has its own run, the old one says nothing about it
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      run = nil
      M.check()
    end,
  })
  vim.api.nvim_create_user_command("CI", M.open, { desc = "Open the branch's CI run" })
  timer = vim.uv.new_timer()
  vim.defer_fn(M.check, 3000)
end

return M
