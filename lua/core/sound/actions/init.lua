-- Which file a sound event plays and which program plays it. Pure logic only.
local M = {}

M.EXTENSIONS = { wav = true, mp3 = true, aiff = true, m4a = true, ogg = true }

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
}

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

--- Builds the command that plays a file with the first player found.
---@param file string absolute path
---@param executable fun(name: string): boolean
---@return string[]|nil command, nil when no player is installed
function M.command(file, executable)
  if executable("afplay") then
    return { "afplay", file }
  end
  if executable("paplay") then
    return { "paplay", file }
  end
  if executable("ffplay") then
    return { "ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", file }
  end
  return nil
end

return M
