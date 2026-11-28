-- Pure checks a fresh take from the writer passes before it joins a role: Drama 3 markup the
-- studio can read, holes its moment can fill, the length the prompt asked for, and something new
-- rather than a paraphrase of what the role already says.
local studio = require("core.voice.studio.actions")

local M = {}

-- a take longer than this is a speech, not a notification
M.MAX_CHARS = 240
-- the prompt asks for at most this many words
M.MAX_WORDS = 25
-- word overlap with a take the role has from which a new one reads as the same line
M.SIMILAR = 0.6

-- paired tags the studio can voice on both models
local TAGS = { emphasis = true, whisper = true, soft = true, slow = true }

---Whether a take's markup is what the prompt asks for: at most one [direction], first, any number
---of [break], and at most one known paired tag, closed.
---@param take string
---@return boolean
function M.markup_ok(take)
  local directions = 0
  for cue in take:gmatch("%[([^%]]*)%]") do
    if cue ~= "break" then
      directions = directions + 1
    end
  end
  local leads = directions == 0 or vim.trim(take):match("^%[[^%]]*%]") ~= nil
  local pairs_found = 0
  for tag in take:gmatch("<(%a+)>") do
    if not TAGS[tag] or not take:find("</" .. tag .. ">", 1, true) then
      return false
    end
    pairs_found = pairs_found + 1
  end
  local closings = select(2, take:gsub("</%a+>", ""))
  return directions <= 1 and leads and pairs_found <= 1 and closings == pairs_found
end

---Whether every hole in a take is one its moment can fill.
---@param take string
---@param moment string
---@return boolean
function M.holes_ok(take, moment)
  local allowed = {}
  for _, hole in ipairs(studio.holes(moment)) do
    allowed[hole] = true
  end
  for hole in take:gmatch("{(%w+)}") do
    if not allowed[hole] then
      return false
    end
  end
  return true
end

-- the lowercase words of a take as heard, without its markup or holes
local function words(take)
  local set, count = {}, 0
  for word in studio.plain(take):gsub("{%w+}", ""):lower():gmatch("[%w']+") do
    if not set[word] then
      set[word] = true
      count = count + 1
    end
  end
  return set, count
end

---How much two takes share, from 0 (no word in common) to 1 (the same words).
---@param a string
---@param b string
---@return number
function M.similarity(a, b)
  local first, first_count = words(a)
  local second, second_count = words(b)
  local shared = 0
  for word in pairs(first) do
    shared = shared + (second[word] and 1 or 0)
  end
  local union = first_count + second_count - shared
  return union == 0 and 1 or shared / union
end

---Whether a take says something none of the others already say.
---@param take string
---@param others string[]
---@return boolean
function M.new_enough(take, others)
  for _, other in ipairs(others or {}) do
    if M.similarity(take, other) >= M.SIMILAR then
      return false
    end
  end
  return true
end

-- the length and the forbidden characters
local function shape_ok(take)
  local plain = studio.plain(take)
  local _, count = plain:gsub("%S+", "")
  return #plain > 0
    and #take <= M.MAX_CHARS
    and count <= M.MAX_WORDS
    and not take:find("—", 1, true)
    and not take:find('"', 1, true)
end

---Whether a fresh take may join its moment.
---@param take any what the writer answered for it
---@param moment string
---@param others string[] the takes the moment already has, banned ones too
---@return boolean
function M.usable(take, moment, others)
  if type(take) ~= "string" then
    return false
  end
  take = vim.trim(take)
  return shape_ok(take)
    and M.markup_ok(take)
    and M.holes_ok(take, moment)
    and M.new_enough(take, others)
end

return M
