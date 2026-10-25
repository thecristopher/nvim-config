-- Plays the franchise's sounds from sounds/<franchise>/<event>.wav (or mp3, aiff, m4a, ogg).
-- A missing file stays quiet, vim.g.eldentree_sound = false silences everything.
local actions = require("core.sound.actions")

local M = {}

local last_played = {}
-- the same event twice in a heartbeat is one sound, not an echo
local DEBOUNCE_MS = 400

local function folder()
  return vim.fn.stdpath("config") .. "/sounds/" .. require("core.franchise").name()
end

local function executable(name)
  return vim.fn.executable(name) == 1
end

--- Plays the sound for an event, if the franchise has one.
---@param event string one of actions.EVENTS
function M.play(event)
  if vim.g.eldentree_sound == false or #vim.api.nvim_list_uis() == 0 then
    return
  end
  local now = vim.uv.now()
  if last_played[event] and now - last_played[event] < DEBOUNCE_MS then
    return
  end
  local ok, files = pcall(vim.fn.readdir, folder())
  if not ok then
    return
  end
  local file = actions.pick(files, event, math.random)
  if not file then
    return
  end
  local command = actions.command(folder() .. "/" .. file, executable)
  if not command then
    return
  end
  last_played[event] = now
  pcall(vim.system, command, { detach = true })
end

function M.setup()
  vim.api.nvim_create_user_command("Sound", function(cmd)
    -- a preview, so it plays even right after the same event fired
    last_played[cmd.args] = nil
    M.play(cmd.args)
  end, {
    nargs = 1,
    complete = function()
      return actions.EVENTS
    end,
    desc = "Play one of the franchise's sounds",
  })
end

return M
