-- The songs heard while working, counted per year for the year card. The store is shaped like
-- { ["2026"] = { ["artist|title"] = { title, artist, plays } } }. Pure logic only.
local M = {}

--- Counts one more play of a song in its year.
---@param store table
---@param year string like "2026"
---@param key string the song's track_key
---@param track { title: string, artist: string }
---@return table store
function M.record(store, year, key, track)
  store[year] = store[year] or {}
  local entry = store[year][key] or { title = track.title, artist = track.artist, plays = 0 }
  entry.plays = entry.plays + 1
  store[year][key] = entry
  return store
end

--- The song heard the most in a year, the first by name when two tie.
---@param store table
---@param year string like "2026"
---@return { title: string, artist: string, plays: integer }|nil
function M.top(store, year)
  local best, best_key
  for key, entry in pairs(type(store[year]) == "table" and store[year] or {}) do
    local plays = tonumber(entry.plays) or 0
    local better = not best or plays > best.plays or (plays == best.plays and key < best_key)
    if better then
      best, best_key = { title = entry.title, artist = entry.artist, plays = plays }, key
    end
  end
  return best
end

return M
