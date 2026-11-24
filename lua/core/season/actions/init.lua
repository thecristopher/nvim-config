-- Seasons: a few days of the year dress every world the same way. Halloween brings Resident Evil
-- and rising embers, the end of the year snows, the first day sparkles, and the anniversary set in
-- vim.g.eldentree_anniversary ("MM-DD") brings Elizabeth and hearts. Pure logic only.
local M = {}

-- checked in this order, the first that matches wins, so the anniversary beats any holiday.
-- weather is shaped like a lore's weather: glyphs, drift, speed and two palette slots
M.SEASONS = {
  {
    name = "anniversary",
    title = "Anniversary",
    tagline = "Another year, together",
    franchise = "elizabeth",
    weather = {
      glyphs = { "·", "∙", "󰋑" },
      drift = "rise",
      speed = { 0.3, 0.8 },
      from = "pink",
      to = "red",
    },
  },
  {
    name = "halloween",
    title = "Halloween",
    tagline = "Something stirs in the dark",
    from = { 10, 24 },
    to = { 10, 31 },
    franchise = "resident_evil",
    weather = {
      glyphs = { "·", "∙", "•" },
      drift = "rise",
      speed = { 0.4, 1.1 },
      from = "red",
      to = "peach",
    },
  },
  {
    name = "winter",
    title = "Winter",
    tagline = "Snow falls over every land",
    from = { 12, 15 },
    to = { 12, 31 },
    weather = {
      glyphs = { "·", "∘", "˙" },
      drift = "fall",
      speed = { 0.5, 1.4 },
      from = "overlay1",
      to = "text",
    },
  },
  {
    name = "new_year",
    title = "New Year",
    tagline = "A new year begins",
    from = { 1, 1 },
    to = { 1, 1 },
    weather = {
      glyphs = { "·", "˙", "•" },
      drift = "float",
      speed = { 0.2, 0.6 },
      from = "yellow",
      to = "peach",
    },
  },
}

local function key(month, day)
  return month * 100 + day
end

--- Tells whether a day falls inside a range of the calendar, both ends included.
---@param month integer
---@param day integer
---@param from integer[] { month, day }
---@param to integer[] { month, day }
---@return boolean
function M.within(month, day, from, to)
  local today = key(month, day)
  return today >= key(from[1], from[2]) and today <= key(to[1], to[2])
end

--- Reads an anniversary written as "MM-DD".
---@param text string|nil
---@return integer[]|nil { month, day }
function M.parse_anniversary(text)
  local month, day = tostring(text or ""):match("^(%d%d?)%-(%d%d?)$")
  if not month then
    return nil
  end
  return { tonumber(month), tonumber(day) }
end

local function matches(season, month, day, anniversary)
  if season.name == "anniversary" then
    return anniversary ~= nil and anniversary[1] == month and anniversary[2] == day
  end
  return M.within(month, day, season.from, season.to)
end

--- The season of a day, nil on an ordinary one.
---@param date { month: integer, day: integer }
---@param anniversary string|nil "MM-DD"
---@return table|nil season
function M.season(date, anniversary)
  local parsed = M.parse_anniversary(anniversary)
  for _, season in ipairs(M.SEASONS) do
    if matches(season, date.month, date.day, parsed) then
      return season
    end
  end
  return nil
end

--- The franchise a season brings, nil when it brings none or that one does not play here.
---@param season table|nil
---@param playable string[] the franchises that play on this machine
---@return string|nil
function M.franchise(season, playable)
  if not season or not season.franchise then
    return nil
  end
  return vim.tbl_contains(playable, season.franchise) and season.franchise or nil
end

return M
