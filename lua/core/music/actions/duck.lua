-- Ducking: the music steps back while a character speaks and comes back once they are done.
-- Apple Music on macOS only, its volume goes from 0 to 100. Pure building and math only.
local M = {}

-- low enough for the voice to sit over it, high enough that the song is still there
M.RATIO = 0.3
-- a voice cut by the next one should not let the music swell between them
M.RESTORE_DELAY_MS = 400
M.RESTORE_STEPS = 5
M.RESTORE_STEP_MS = 120

local GET_VOLUME =
  'if application "Music" is running then tell application "Music" to get sound volume'
local SET_VOLUME =
  'if application "Music" is running then tell application "Music" to set sound volume to %d'

--- Builds the osascript call that reads Music.app's volume, empty when it is closed.
---@return string[]
function M.volume_command()
  return { "osascript", "-e", GET_VOLUME }
end

--- Builds the osascript call that sets Music.app's volume, ignored when it is closed.
---@param volume integer 0 to 100
---@return string[]
function M.set_volume_command(volume)
  return { "osascript", "-e", SET_VOLUME:format(volume) }
end

--- Reads the answer of the volume script.
---@param stdout string|nil
---@return integer|nil volume, nil when Music.app is closed or answered nonsense
function M.parse_volume(stdout)
  local volume = tonumber(vim.trim(stdout or ""))
  if not volume or volume < 0 or volume > 100 then
    return nil
  end
  return math.floor(volume)
end

--- The volume the music drops to under a voice.
---@param volume integer the volume before the voice
---@return integer
function M.lowered(volume)
  return math.floor(volume * M.RATIO + 0.5)
end

--- The volumes the music climbs through on its way back, ending exactly where it was.
---@param from integer the lowered volume
---@param to integer the volume before the voice
---@param steps integer
---@return integer[]
function M.ramp(from, to, steps)
  local volumes = {}
  for step = 1, steps do
    volumes[step] = math.floor(from + (to - from) * step / steps + 0.5)
  end
  return volumes
end

return M
