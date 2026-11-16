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
  "curtain",
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
  "welcome",
  "weapon",
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

--- Picks one of the event's files, never the one that played last time when there are several.
---@param files string[]
---@param event string
---@param rand fun(n: integer): integer returns 1..n
---@param last string|nil the file this event played last time
---@return string|nil
function M.pick(files, event, rand, last)
  local candidates = M.candidates(files, event)
  table.sort(candidates)
  if #candidates > 1 and last then
    candidates = vim.tbl_filter(function(file)
      return file ~= last
    end, candidates)
  end
  if #candidates == 0 then
    return nil
  end
  return candidates[rand(#candidates)]
end

-- how much a moment weighs: a bigger one cuts a smaller one short, a smaller one waits its turn
-- by staying quiet. Anything not listed weighs 1
M.WEIGHT = {
  died = 6,
  felled = 5,
  great = 5,
  boss = 4,
  title = 3,
  rest = 3,
  grace = 3,
  cleansed = 3,
  door = 3,
  fog = 3,
  curtain = 3,
  merchant = 2,
  welcome = 2,
  bought = 2,
  weapon = 2,
  expedition = 2,
}

--- The channel an event plays on: every HUD sound shares one, every other moment the other.
---@param event string
---@return "hud"|"moment"
function M.channel(event)
  return event:match("^hud_") and "hud" or "moment"
end

--- How much a moment weighs against another, see M.WEIGHT.
---@param event string
---@return integer
function M.weight(event)
  return M.WEIGHT[event] or 1
end

--- Decides whether an event plays over what its channel is playing, and whether that gets cut.
--- A HUD sound always replaces the last one, so holding a key ticks instead of buzzing. A moment
--- plays when the channel is quiet or it weighs at least as much as the one playing, cutting it.
---@param event string
---@param playing string|nil the event still playing on the same channel
---@return boolean play, boolean cut
function M.arbitrate(event, playing)
  if not playing then
    return true, false
  end
  if M.channel(event) == "hud" or M.weight(event) >= M.weight(playing) then
    return true, true
  end
  return false, false
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
