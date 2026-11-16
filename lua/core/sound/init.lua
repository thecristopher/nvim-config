-- Plays the franchise's sounds from sounds/<franchise>/<event>.wav (or mp3, aiff, m4a, ogg).
-- Sounds travel on two channels: the HUD's, where each sound replaces the last one, and the
-- moments', where a bigger moment cuts a smaller one and a smaller one stays quiet. Nothing plays
-- while nvim is out of focus, except a :Sound preview. A missing file stays quiet,
-- vim.g.eldentree_sound = false silences everything.
local actions = require("core.sound.actions")

local M = {}

local last_played = {}
local last_file = {}
-- what each channel is playing right now: { event, process }
local channels = {}
local focused = true

local function folder()
  return vim.fn.stdpath("config") .. "/sounds/" .. require("core.franchise").name()
end

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function silenced(opts)
  if vim.g.eldentree_sound == false or #vim.api.nvim_list_uis() == 0 then
    return true
  end
  return not focused and not opts.force
end

local function stop(entry)
  if entry and entry.process then
    pcall(entry.process.kill, entry.process, 15)
  end
end

-- the event still sounding on a channel, nil once its player is gone
local function sounding(channel)
  local entry = channels[channel]
  return entry and not entry.done and entry.event or nil
end

local function start(event, command)
  local channel = actions.channel(event)
  local entry = { event = event }
  local started, process = pcall(vim.system, command, { detach = true }, function()
    entry.done = true
  end)
  if not started then
    return nil
  end
  entry.process = process
  channels[channel] = entry
  return process
end

--- Plays the sound for an event, if the franchise has one and its channel lets it.
---@param event string one of actions.EVENTS
---@param opts? { force?: boolean } force plays even while nvim is out of focus (previews)
---@return vim.SystemObj|nil playing the player process, so a long sound can be cut short
function M.play(event, opts)
  opts = opts or {}
  if silenced(opts) then
    return
  end
  local now = vim.uv.now()
  if last_played[event] and now - last_played[event] < actions.debounce_ms(event) then
    return
  end
  local play, cut = actions.arbitrate(event, sounding(actions.channel(event)))
  if not play then
    return
  end
  local ok, files = pcall(vim.fn.readdir, folder())
  if not ok then
    return
  end
  local file = actions.pick(files, event, math.random, last_file[event])
  local command = file and actions.command(folder() .. "/" .. file, executable)
  if not command then
    return
  end
  if cut then
    stop(channels[actions.channel(event)])
  end
  last_played[event], last_file[event] = now, file
  return start(event, command)
end

--- Plays the first of the events the franchise has a file for, so each franchise can bring its own.
---@param events string[] in order of preference
---@return vim.SystemObj|nil playing
function M.play_first(events)
  local ok, files = pcall(vim.fn.readdir, folder())
  if not ok then
    return
  end
  local event = actions.first_available(files, events)
  return event and M.play(event) or nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_sound", { clear = true })
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
    end,
  })
  vim.api.nvim_create_user_command("Sound", function(cmd)
    -- a preview, so it plays even right after the same event fired and over anything playing
    last_played[cmd.args] = nil
    stop(channels[actions.channel(cmd.args)])
    channels[actions.channel(cmd.args)] = nil
    M.play(cmd.args, { force = true })
  end, {
    nargs = 1,
    complete = function()
      return actions.EVENTS
    end,
    desc = "Play one of the franchise's sounds",
  })
end

return M
