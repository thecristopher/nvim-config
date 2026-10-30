-- :Expedition [minutes] or <leader>ue: a focus block. Sounds, animations and quiet notifications
-- step aside, the statusline counts down, and the end ranks the block on its own.
local actions = require("core.expedition.actions")

local M = {}

local block = nil

local function words()
  return require("core.franchise").current().expedition
end

local function quiet_notify(original)
  return function(message, level, opts)
    if actions.lets_through(level) then
      return original(message, level, opts)
    end
  end
end

local function hush()
  local saved = {
    sound = vim.g.eldentree_sound,
    motion = vim.g.eldentree_motion,
    notify = vim.notify,
  }
  vim.g.eldentree_sound = false
  vim.g.eldentree_motion = false
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeMotion", modeline = false })
  vim.notify = quiet_notify(saved.notify)
  return saved
end

-- a plugin may have taken vim.notify over meanwhile, that one stays
local function wake(saved, wrapper)
  vim.g.eldentree_sound = saved.sound
  vim.g.eldentree_motion = saved.motion
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeMotion", modeline = false })
  if vim.notify == wrapper then
    vim.notify = saved.notify
  end
end

local function stop_timer()
  if block and block.timer and not block.timer:is_closing() then
    block.timer:stop()
    block.timer:close()
  end
end

--- Ends the block: the world wakes up and the block gets its rank.
function M.stop()
  if not block then
    return
  end
  stop_timer()
  local ending = block
  block = nil
  wake(ending.saved, ending.wrapper)
  require("core.utils").refresh_statusline()
  local segment = actions.segment(ending.run, require("core.results").current())
  require("core.banner").show("great", { reward = false, subtitle = actions.subtitle(segment) })
  vim.notify(words().ended, vim.log.levels.INFO, { title = words().name })
end

--- Starts a block of some minutes, or ends the one running.
---@param arg string|nil minutes, "stop" ends it
function M.start(arg)
  if arg == "stop" or (block and (not arg or arg == "")) then
    return M.stop()
  end
  local minutes = actions.minutes(arg)
  if not minutes then
    return vim.notify(
      "Give it the minutes, like :Expedition 45",
      vim.log.levels.WARN,
      { title = words().name }
    )
  end
  if block then
    M.stop()
  end
  vim.notify(words().started:format(minutes), vim.log.levels.INFO, { title = words().name })
  -- the last sound before the quiet
  require("core.sound").play("expedition")
  local saved = hush()
  block = {
    ends_at = os.time() + minutes * 60,
    run = require("core.results").current(),
    saved = saved,
    wrapper = vim.notify,
    timer = vim.uv.new_timer(),
  }
  -- the countdown moves by the minute, a tick every 15 seconds keeps it honest
  block.timer:start(
    15000,
    15000,
    vim.schedule_wrap(function()
      if block and actions.remaining(block.ends_at, os.time()) == 0 then
        return M.stop()
      end
      require("core.utils").refresh_statusline()
    end)
  )
  require("core.utils").refresh_statusline()
end

--- The statusline countdown, empty while no block runs.
---@return string
function M.statusline()
  if not block then
    return ""
  end
  return ("󱎫 %s %s"):format(
    words().name,
    actions.countdown(actions.remaining(block.ends_at, os.time()))
  )
end

function M.setup()
  vim.api.nvim_create_user_command("Expedition", function(command)
    M.start(command.args)
  end, { nargs = "?", desc = "A focus block, :Expedition stop ends it" })
  vim.keymap.set("n", "<leader>ue", function()
    M.start()
  end, { desc = "Expedition (focus block)" })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("eldentree_expedition", { clear = true }),
    callback = stop_timer,
  })
end

return M
