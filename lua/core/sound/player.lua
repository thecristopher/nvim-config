-- The resident player on macOS: player.swift compiled once into the cache and kept running for the
-- whole session, so a sound starts at once instead of waiting a second for afplay to wake the audio
-- device on every keypress. Until it is built, or where it cannot be, core/sound falls back to afplay.
local actions = require("core.sound.actions")

local M = {}

local source = debug.getinfo(1, "S").source:sub(2):gsub("player%.lua$", "player.swift")
local binary = vim.fn.stdpath("cache") .. "/eldentree/sound_player"

local process
local building = false
-- channel -> callback for when the sound with this token is over
local on_done = {}

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.sec or nil
end

local function read(_, chunk)
  if not chunk then
    return
  end
  vim.schedule(function()
    for _, over in ipairs(actions.finished(chunk)) do
      local waiting = on_done[over.channel]
      if waiting and waiting.token == over.token then
        on_done[over.channel] = nil
        waiting.callback()
      end
    end
  end)
end

local function launch()
  local ok, started = pcall(vim.system, { binary }, { stdin = true, stdout = read }, function()
    vim.schedule(function()
      process = nil
      for channel, waiting in pairs(on_done) do
        on_done[channel] = nil
        waiting.callback()
      end
    end)
  end)
  process = ok and started or nil
end

local function build()
  building = true
  vim.fn.mkdir(vim.fs.dirname(binary), "p")
  local ok = pcall(
    vim.system,
    { "swiftc", "-O", source, "-o", binary },
    {},
    vim.schedule_wrap(function(result)
      building = false
      if result.code == 0 then
        launch()
      end
    end)
  )
  if not ok then
    building = false
  end
end

--- Starts the player, compiling it first when its source changed. Only on macOS with swiftc.
function M.start()
  if process or building or vim.fn.has("mac") == 0 or vim.fn.executable("swiftc") == 0 then
    return
  end
  if actions.needs_build(mtime(source), mtime(binary)) then
    return build()
  end
  launch()
end

--- Whether the player is up and taking sounds.
---@return boolean
function M.ready()
  return process ~= nil
end

--- Plays a file on a channel, cutting what it was playing there.
---@param channel string
---@param token integer
---@param file string absolute path
---@param callback fun() called once the sound is over, ended or cut
---@return boolean sent false when the player is not running
function M.play(channel, token, file, callback)
  if not process then
    return false
  end
  local previous = on_done[channel]
  on_done[channel] = { token = tostring(token), callback = callback }
  if previous then
    previous.callback()
  end
  local ok = pcall(process.write, process, actions.player_line(channel, token, file))
  if not ok then
    on_done[channel] = nil
    process = nil
  end
  return ok
end

--- Cuts a channel short.
---@param channel string
function M.stop(channel)
  if process then
    pcall(process.write, process, ("stop %s\n"):format(channel))
  end
end

return M
