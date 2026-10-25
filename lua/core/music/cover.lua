-- Album covers for the now playing panel: downloaded from Cider's artwork URL or saved out of
-- Music.app, once per album, into nvim's cache.
local actions = require("core.music.actions")

local M = {}

local EXTENSIONS = { "jpg", "png", "jpeg" }

local function cache_dir()
  local dir = vim.fn.stdpath("cache") .. "/eldentree/music"
  vim.fn.mkdir(dir, "p")
  return dir
end

local function cached(base)
  for _, extension in ipairs(EXTENSIONS) do
    local file = base .. "." .. extension
    if vim.uv.fs_stat(file) then return file end
  end
  return nil
end

local function from_cider(track, base, on_done)
  if not track.cover then return on_done(nil) end
  local file = base .. "." .. actions.url_extension(track.cover)
  vim.system({ "curl", "-s", "-f", "--max-time", "5", "-o", file, track.cover }, {}, vim.schedule_wrap(function(result)
    if result.code == 0 then return on_done(file) end
    os.remove(file)
    on_done(nil)
  end))
end

local function from_music(base, on_done)
  -- AppleScript tells the format only after writing, so the bytes land first and get named after
  local partial = base .. ".part"
  vim.system(actions.music_cover_command(partial), { text = true }, vim.schedule_wrap(function(result)
    local extension = result.code == 0 and actions.cover_extension(result.stdout)
    if not extension then
      os.remove(partial)
      return on_done(nil)
    end
    local file = base .. "." .. extension
    os.rename(partial, file)
    on_done(file)
  end))
end

--- Finds the cover of a track, fetching it the first time its album shows up.
---@param track table from the music actions parsers
---@param source string|nil "cider" or "music"
---@param on_done fun(file: string|nil) nil when the song has no cover
function M.fetch(track, source, on_done)
  local base = cache_dir() .. "/" .. actions.cover_name(track)
  local file = cached(base)
  if file then return on_done(file) end
  if source == "cider" then return from_cider(track, base, on_done) end
  if source == "music" then return from_music(base, on_done) end
  on_done(nil)
end

return M
