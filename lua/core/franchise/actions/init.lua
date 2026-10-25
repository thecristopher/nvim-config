-- Which franchise the config speaks: a new one every day, or the one chosen for today.
local M = {}

-- picker order, and the first one is the fallback for anything unknown
M.NAMES = { "elden_ring", "resident_evil" }

--- Returns the franchise name when it exists, the first one otherwise.
---@param name string|nil
---@return string
function M.resolve(name)
  return vim.tbl_contains(M.NAMES, name) and name or M.NAMES[1]
end

--- Returns everything a franchise brings: regions, bosses, weather, banners and words.
---@param name string|nil franchise name
---@return table lore
function M.lore(name)
  return require("core.franchise.lore." .. M.resolve(name))
end

--- Counts days since the epoch for a calendar date, the same in every timezone.
---@param date { year: integer, month: integer, day: integer }
---@return integer
function M.day_number(date)
  -- noon keeps daylight saving shifts from landing the date on its neighbor
  return math.floor(os.time({ year = date.year, month = date.month, day = date.day, hour = 12 }) / 86400)
end

--- Returns the franchise for a date, rotating through all of them one day at a time.
---@param date { year: integer, month: integer, day: integer }
---@return string franchise name
function M.of_the_day(date)
  return M.NAMES[M.day_number(date) % #M.NAMES + 1]
end

--- Writes a choice so it only holds for the day it was made.
---@param day string date as YYYY-MM-DD
---@param name string franchise name
---@return string
function M.encode_choice(day, name)
  return day .. " " .. name
end

--- Reads a saved choice back, nil when it was made another day or names nothing known.
---@param line string|nil saved line
---@param day string today as YYYY-MM-DD
---@return string|nil franchise name
function M.choice_for(line, day)
  local saved_day, name = (line or ""):match("^(%S+)%s+(%S+)$")
  if saved_day ~= day or not vim.tbl_contains(M.NAMES, name) then return nil end
  return name
end

return M
