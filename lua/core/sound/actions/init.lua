-- Which file a sound event plays and which program plays it. Pure logic only.
local M = {}

M.EXTENSIONS = { wav = true, mp3 = true, aiff = true, m4a = true, ogg = true }

-- every player plays at this share of full volume, so a sound keeps you company and never startles
M.VOLUME = 0.6

-- every moment that can make a sound, the file name is the event, variants add _1, _2...
M.EVENTS = {
  "title",
  "door",
  "fog",
  "rest",
  "boss",
  "merchant",
  "felled",
  "great",
  "died",
  "grace",
  "cleansed",
  "region",
  "zone",
  "phantom",
  "continue",
  "summon",
  "comfort",
  "expedition",
  "bought",
  "hud_open",
  "hud_close",
  "hud_move",
  "hud_select",
  "hud_back",
}

--- How long an event stays quiet after playing, so a burst of the same moment is one sound.
--- Inventory sounds follow every keypress, the rest are moments that should not echo.
---@param event string
---@return integer milliseconds
function M.debounce_ms(event)
  if event:match("^hud_") then
    return 60
  end
  return 400
end

local function event_of(file)
  local stem, extension = file:match("^(.+)%.(%w+)$")
  if not stem or not M.EXTENSIONS[extension:lower()] then
    return nil
  end
  return (stem:gsub("_%d+$", ""))
end

--- Lists the files that belong to an event: "died.wav" and its variants like "died_2.mp3".
---@param files string[] file names in the franchise's sound folder
---@param event string
---@return string[]
function M.candidates(files, event)
  return vim.tbl_filter(function(file)
    return event_of(file) == event
  end, files)
end

--- Picks one of the event's files, a different variant each time when there are several.
---@param files string[]
---@param event string
---@param rand fun(n: integer): integer returns 1..n
---@return string|nil
function M.pick(files, event, rand)
  local candidates = M.candidates(files, event)
  table.sort(candidates)
  if #candidates == 0 then
    return nil
  end
  return candidates[rand(#candidates)]
end

--- The first event with at least one file, nil when none of them has any.
---@param files string[] file names in the franchise's sound folder
---@param events string[] in order of preference
---@return string|nil
function M.first_available(files, events)
  for _, event in ipairs(events) do
    if #M.candidates(files, event) > 0 then
      return event
    end
  end
  return nil
end

--- Builds the command that plays a file with the first player found.
---@param file string absolute path
---@param executable fun(name: string): boolean
---@return string[]|nil command, nil when no player is installed
function M.command(file, executable)
  if executable("afplay") then
    return { "afplay", "-v", tostring(M.VOLUME), file }
  end
  if executable("paplay") then
    -- paplay counts volume from 0 to 65536
    return { "paplay", "--volume=" .. math.floor(65536 * M.VOLUME), file }
  end
  if executable("ffplay") then
    local volume = tostring(math.floor(100 * M.VOLUME))
    return { "ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", "-volume", volume, file }
  end
  return nil
end

return M
