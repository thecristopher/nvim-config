-- Which franchise the config speaks: a new one every day, or the one chosen for today.
-- Every folder in lua/core/franchise/lore/ is a franchise, dropping one in is all it takes.
local M = {}

-- the fallback for anything unknown
M.DEFAULT = "elden_ring"

local discovered

--- Lists every franchise found in the lore folder, sorted so the daily rotation is stable.
---@return string[]
function M.names()
  if discovered then
    return discovered
  end
  local seen, names = {}, {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/core/franchise/lore/*/init.lua", true)) do
    local name = vim.fs.basename(vim.fs.dirname(path))
    if not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end
  table.sort(names)
  discovered = names
  return names
end

--- Forgets the franchises found so far, so a freshly created one shows up.
function M.rediscover()
  discovered = nil
end

--- Returns the franchise name when it exists, the default otherwise.
---@param name string|nil
---@return string
function M.resolve(name)
  return vim.tbl_contains(M.names(), name) and name or M.DEFAULT
end

--- Returns everything a franchise brings: regions, bosses, weather, banners, words and skin.
---@param name string|nil franchise name
---@return table lore
function M.lore(name)
  return (require("core.franchise.lore." .. M.resolve(name)))
end

--- Counts days since the epoch for a calendar date, the same in every timezone.
---@param date { year: integer, month: integer, day: integer }
---@return integer
function M.day_number(date)
  -- noon keeps daylight saving shifts from landing the date on its neighbor
  return math.floor(
    os.time({ year = date.year, month = date.month, day = date.day, hour = 12 }) / 86400
  )
end

--- Returns the franchise for a date, rotating through all of them one day at a time.
---@param date { year: integer, month: integer, day: integer }
---@param names string[]|nil franchises to rotate through, every discovered one by default
---@return string franchise name
function M.of_the_day(date, names)
  names = names or M.names()
  return names[M.day_number(date) % #names + 1]
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
  if saved_day ~= day or not vim.tbl_contains(M.names(), name) then
    return nil
  end
  return name
end

--- Turns a name typed by a person into a folder name: lowercase words joined by underscores.
---@param text string like "Silent Hill"
---@return string|nil name like "silent_hill", nil when nothing usable is left
function M.slug(text)
  local slug = vim.trim(text or ""):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
  return slug ~= "" and slug or nil
end

--- Turns a folder name back into a title.
---@param name string like "silent_hill"
---@return string like "Silent Hill"
function M.title(name)
  return (
    name:gsub("_", " "):gsub("(%a)([%w]*)", function(first, rest)
      return first:upper() .. rest
    end)
  )
end

--- Fills the template's placeholders for a new franchise.
---@param text string template file contents
---@param name string folder name
---@return string
function M.fill_template(text, name)
  return (text:gsub("__name__", name):gsub("__title__", M.title(name)))
end

return M
