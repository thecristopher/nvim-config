-- The karaoke ticker: while the now playing panel is closed and lyrics are shown, the statusline
-- sings the synced line of the song instead of its name. A light timer checks the line only while
-- a song plays and nvim is focused, and repaints only when the line changes.
local actions = require("core.music.actions.lyrics")
local lyrics = require("core.music.lyrics")

local M = {}

local TICK_MS = 250

local timer
local running = false
local state = { name = nil, found = nil, line = nil, fetching = false }

local function music()
  return require("core.music")
end

local function panel()
  return require("core.music.panel")
end

-- the panel shows the lyrics itself, the ticker sings only while it is closed
local function wanted()
  local track = music().now_playing()
  return track ~= nil and track.playing and panel().lyrics_shown() and not panel().is_open()
end

local function load(track)
  local name = actions.name(track)
  if state.name == name then
    return
  end
  state.name, state.found, state.line, state.fetching = name, nil, nil, true
  lyrics.fetch(track, function(found)
    if state.name ~= name then
      return
    end
    state.fetching, state.found = false, found
  end)
end

local function tick()
  if not wanted() then
    if state.line then
      state.line = nil
      require("core.utils").refresh_statusline()
    end
    return
  end
  local track = music().now_playing()
  load(track)
  local line = actions.ticker_line(state.found, music().elapsed())
  if line ~= state.line then
    state.line = line
    require("core.utils").refresh_statusline()
  end
end

--- The line being sung right now, nil when the statusline should name the song instead.
---@return string|nil
function M.line()
  if not wanted() then
    return nil
  end
  return state.line
end

--- Starts following the song, called while a song plays and nvim is focused. Safe to call again.
function M.start()
  if running then
    return
  end
  running = true
  timer = timer or vim.uv.new_timer()
  timer:start(0, TICK_MS, vim.schedule_wrap(tick))
end

--- Stops following the song, when it stops or nvim loses focus, and lets the name come back.
function M.stop()
  if not running then
    return
  end
  running = false
  if timer then
    timer:stop()
  end
  if state.line then
    state.line = nil
    require("core.utils").refresh_statusline()
  end
end

return M
