-- Phantoms: who last touched a line, told the way the game shows other players. Pure parsing and
-- wording only, so it can be tested headless. Times are seconds.
local M = {}

--- Reads the one line block of `git blame --porcelain` into the fields a phantom needs.
---@param lines string[]
---@return { sha: string, author: string, mail: string, time: integer, summary: string, unwritten: boolean }|nil
function M.parse_porcelain(lines)
  if not lines or not lines[1] then return nil end
  local sha = lines[1]:match("^(%x+) ")
  if not sha then return nil end
  local info = { sha = sha, author = "", mail = "", time = 0, summary = "", unwritten = sha:match("^0+$") ~= nil }
  for _, line in ipairs(lines) do
    local key, value = line:match("^(%S+) (.*)$")
    if key == "author" then info.author = value end
    if key == "author-mail" then info.mail = value:gsub("^<", ""):gsub(">$", "") end
    if key == "author-time" then info.time = tonumber(value) or 0 end
    if key == "summary" then info.summary = value end
  end
  return info
end

-- what a line in a file git has never seen looks like
M.UNWRITTEN = { sha = "0000000", author = "", mail = "", time = 0, summary = "", unwritten = true }

--- Tells whether blame failed only because the file was never committed.
---@param stderr string|nil
---@return boolean
function M.untracked(stderr)
  return (stderr or ""):find("no such path", 1, true) ~= nil
end

local UNITS = {
  { 365 * 24 * 3600, "year" },
  { 30 * 24 * 3600, "month" },
  { 7 * 24 * 3600, "week" },
  { 24 * 3600, "day" },
  { 3600, "hour" },
  { 60, "minute" },
}

--- Turns an age into words like "3 days ago".
---@param seconds integer
---@return string
function M.relative_time(seconds)
  for _, unit in ipairs(UNITS) do
    local count = math.floor(seconds / unit[1])
    if count >= 1 then
      return ("%d %s%s ago"):format(count, unit[2], count == 1 and "" or "s")
    end
  end
  return "moments ago"
end

--- Tells what kind of phantom wrote a line: nobody yet, your past self, or another Tarnished.
---@param info { author: string, mail: string, unwritten: boolean }
---@param me { name: string|nil, mail: string|nil }
---@return "unwritten"|"self"|"other"
function M.kind(info, me)
  if info.unwritten then return "unwritten" end
  me = me or {}
  if (me.mail and me.mail ~= "" and info.mail == me.mail) or (me.name and info.author == me.name) then
    return "self"
  end
  return "other"
end

--- Builds the float's title and lines for a phantom.
---@param info table parsed blame
---@param kind string from M.kind
---@param now integer seconds since the epoch
---@return { title: string, lines: string[] }
function M.describe(info, kind, now)
  if kind == "unwritten" then
    return { title = " ◈ Unwritten ", lines = { "Not yet etched into history.", "Commit it before the fog takes it." } }
  end
  local words = require("core.franchise").current().words
  local who = kind == "self" and words.past_self or words.phantom:format(info.author)
  local when = ("%s · %s"):format(M.relative_time(math.max(0, now - info.time)), info.sha:sub(1, 7))
  return { title = " ◈ " .. who .. " ", lines = { when, info.summary } }
end

return M
