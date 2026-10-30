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
end

local function settle(next_run)
  local verdict = actions.finished(run, next_run)
  run = next_run
  require("core.utils").refresh_statusline()
  if verdict then
    announce(verdict)
  end
end

local function current_branch(cwd)
  local result = vim
    .system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true })
    :wait(2000)
  local name = result.code == 0 and vim.trim(result.stdout or "") or ""
  return name ~= "" and name or nil
end

local schedule

--- Asks gh for the latest run of the branch, in the background.
function M.check()
  if not enabled() or asking then
    return
  end
  root = require("core.repos").root()
  branch = root and current_branch(root)
  if not branch then
    run = nil
    return
  end
  asking = true
  local fields = "status,conclusion,workflowName,url,headSha"
  vim.system(
    { "gh", "run", "list", "--branch", branch, "--limit", "1", "--json", fields },
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

--- Opens the latest run in the browser, asking gh first when there is none yet.
function M.open()
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
  vim.keymap.set("n", "<leader>gi", M.open, { desc = "Open the CI run" })
  timer = vim.uv.new_timer()
  vim.defer_fn(M.check, 3000)
end

return M
