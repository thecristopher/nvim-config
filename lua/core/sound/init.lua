-- Plays the franchise's sounds from sounds/<franchise>/<event>.wav (or mp3, aiff, m4a, ogg).
-- On macOS a resident player (core/sound/player.lua) plays them at once, afplay is the fallback.
-- Sounds travel on two channels: the HUD's, where each sound replaces the last one, and the
-- moments', where a bigger moment cuts a smaller one and a smaller one stays quiet. The character's
-- spoken lines (core/voice) have a third one of their own, over both. Nothing plays
-- while nvim is out of focus, except a :Sound preview. A missing file stays quiet,
-- vim.g.eldentree_sound = false silences everything.
local actions = require("core.sound.actions")
local player = require("core.sound.player")

local M = {}

local last_played = {}
local last_file = {}
-- what each channel is playing right now: { event, channel, process or resident, done }
local channels = {}
local focused = true
-- every sound gets its own number, so the player can say which one is over
local sounds = 0

local function folder()
  return require("core.utils").root() .. "/sounds/" .. require("core.franchise").name()
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
  if not entry or entry.done then
    return
  end
  if entry.resident then
    player.stop(entry.channel)
  elseif entry.process then
    pcall(entry.process.kill, entry.process, 15)
  end
end

-- the event still sounding on a channel, nil once its player is gone
local function sounding(channel)
  local entry = channels[channel]
  return entry and not entry.done and entry.event or nil
end

local function start(event, file, command, channel)
  channel = channel or actions.channel(event)
  local entry = { event = event, channel = channel }
  sounds = sounds + 1
  local function over()
    entry.done = true
  end
  if player.play(channel, sounds, file, over) then
    entry.resident = true
  else
    local started, process = pcall(vim.system, command, { detach = true }, over)
    if not started then
      return nil
    end
    entry.process = process
  end
  channels[channel] = entry
  -- callers keep this to cut a long sound short, and it only ever cuts its own
  return {
    kill = function()
      if channels[channel] == entry then
        stop(entry)
      end
    end,
  }
end

--- Plays the sound for an event, if the franchise has one and its channel lets it.
---@param event string one of actions.EVENTS
---@param opts? { force?: boolean } force plays even while nvim is out of focus (previews)
---@return { kill: fun() }|nil playing cuts this sound short while it still plays
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
  local path = file and folder() .. "/" .. file
  local command = path and actions.command(path, executable)
  if not path or not (player.ready() or command) then
    return
  end
  if cut then
    stop(channels[actions.channel(event)])
  end
  last_played[event], last_file[event] = now, file
  return start(event, path, command)
end

--- Plays a character's spoken line on the voice channel, over the moments and the HUD, cutting
--- the line said before it so two never talk at once.
---@param path string absolute path of the clip
---@return { kill: fun() }|nil playing nil when sound is off, out of focus or nothing can play it
function M.speak(path)
  if silenced({}) then
    return nil
  end
  local command = actions.command(path, executable)
  if not (player.ready() or command) then
    return nil
  end
  stop(channels.voice)
  return start("voice", path, command, "voice")
end

---Whether a sound would be heard right now: sound is on, a screen is attached and nvim has focus.
---@return boolean
function M.audible()
  return not silenced({})
end

---Whether a character's spoken line is still playing.
---@return boolean
function M.speaking()
  return sounding("voice") ~= nil
end

---@return string the folder of the franchise's sounds
function M.folder()
  return folder()
end

--- Plays the first of the events the franchise has a file for, so each franchise can bring its own.
---@param events string[] in order of preference
---@return { kill: fun() }|nil playing
function M.play_first(events)
  local ok, files = pcall(vim.fn.readdir, folder())
  if not ok then
    return
  end
  local event = actions.first_available(files, events)
  return event and M.play(event) or nil
end

function M.setup()
  player.start()
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
  -- a terminal inside nvim (Claude's panel) can swallow or swap the focus events, and a key
  -- pressed in nvim is proof enough that it has the focus
  vim.on_key(function()
    focused = true
  end, vim.api.nvim_create_namespace("eldentree_sound_focus"))
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
