-- Lyrics for the now playing panel: asked to LRCLIB once per song and kept in nvim's cache next to
-- the covers. Songs LRCLIB does not know are remembered only until nvim closes, so they get
-- another chance later. `vim.g.eldentree_lyrics = false` keeps song names from leaving the machine.
local actions = require("core.music.actions.lyrics")

local M = {}

local missing = {}

local function cache_file(track)
  local dir = vim.fn.stdpath("cache") .. "/eldentree/music"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. actions.name(track) .. ".json"
end

local function read_cache(file)
  local handle = io.open(file, "r")
  if not handle then
    return nil
  end
  local body = handle:read("*a")
  handle:close()
  return actions.parse(body)
end

local function write_cache(file, body)
  local handle = io.open(file, "w")
  if handle then
    handle:write(body)
    handle:close()
  end
end

--- Finds the lyrics of a track, asking LRCLIB the first time the song shows up.
---@param track table from the music actions parsers
---@param on_done fun(lyrics: table|false) false when the song has none or the lookup is off
function M.fetch(track, on_done)
  if vim.g.eldentree_lyrics == false then
    return on_done(false)
  end
  local file = cache_file(track)
  local known = read_cache(file)
  if known then
    return on_done(known)
  end
  if missing[file] then
    return on_done(false)
  end

  local ok = pcall(
    vim.system,
    actions.command(track),
    { text = true },
    vim.schedule_wrap(function(result)
      local lyrics = result.code == 0 and actions.parse(result.stdout)
      if not lyrics then
        missing[file] = true
        return on_done(false)
      end
      write_cache(file, result.stdout)
      on_done(lyrics)
    end)
  )
  -- curl missing on this machine reads as a song without lyrics
  if not ok then
    on_done(false)
  end
end

return M
