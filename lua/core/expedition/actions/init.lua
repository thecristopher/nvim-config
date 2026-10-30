-- A focus block: how long is left, what the block did apart from the rest of the run and the
-- rank it earns on its own. Pure logic only.
local results = require("core.results.actions")

local M = {}

M.DEFAULT_MINUTES = 45

--- Reads the minutes :Expedition was given, the default when none.
---@param arg string|nil
---@return integer|nil nil when the argument is not a positive number
function M.minutes(arg)
  if not arg or vim.trim(arg) == "" then
    return M.DEFAULT_MINUTES
  end
  local minutes = tonumber(arg)
  if not minutes or minutes <= 0 then
    return nil
  end
  return math.floor(minutes)
end

--- Seconds left in the block, never below zero.
---@param ends_at integer epoch seconds
---@param now integer epoch seconds
---@return integer
function M.remaining(ends_at, now)
  return math.max(0, ends_at - now)
end

--- The statusline countdown, in minutes until the last one.
---@param seconds integer
---@return string like "32m" or "45s"
function M.countdown(seconds)
  if seconds >= 60 then
    return math.ceil(seconds / 60) .. "m"
  end
  return seconds .. "s"
end

--- What the block did on its own: the run now minus the run when it began.
---@param before { seconds: integer, saves: integer, fixes: integer }
---@param after { seconds: integer, saves: integer, fixes: integer }
---@return { seconds: integer, saves: integer, fixes: integer }
function M.segment(before, after)
  return {
    seconds = after.seconds - before.seconds,
    saves = after.saves - before.saves,
    fixes = after.fixes - before.fixes,
  }
end

--- The banner's subtitle once the block ends: its rank, how long and what it did.
---@param segment { seconds: integer, saves: integer, fixes: integer }
---@return string
function M.subtitle(segment)
  return ("Rank %s  ·  %s  ·  %d saves  ·  %d fixes"):format(
    results.rank(segment),
    results.duration(segment.seconds),
    segment.saves,
    segment.fixes
  )
end

--- Tells whether a notification gets through while the world is quiet: warnings and errors do.
---@param level integer|nil
---@return boolean
function M.lets_through(level)
  return (level or vim.log.levels.INFO) >= vim.log.levels.WARN
end

return M
