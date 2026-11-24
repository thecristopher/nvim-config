-- The results screen after a run: how long it took, how often you saved, how many errors you
-- cleared, and the rank all of that earns. Pure logic only.
local M = {}

-- runs shorter than this were just a peek and never overwrite the last real one
M.MIN_SECONDS = 120

-- points per hour needed for each rank, best first
M.RANKS = {
  { rank = "S", per_hour = 60 },
  { rank = "A", per_hour = 30 },
  { rank = "B", per_hour = 12 },
  { rank = "C", per_hour = 4 },
}

-- a gap longer than this between two signs of life is time away, not time at work
M.IDLE_GAP_MS = 5 * 60 * 1000

--- Adds the time since the last sign of life to the active time, unless the gap was a break.
---@param active_ms integer active time so far
---@param last_ms integer when the last sign of life came
---@param now_ms integer
---@return integer active_ms
function M.active_after(active_ms, last_ms, now_ms)
  local gap = now_ms - last_ms
  if gap <= 0 or gap > M.IDLE_GAP_MS then
    return active_ms
  end
  return active_ms + gap
end

--- Scores a run: fixes count the most, saves keep the pace honest.
---@param run { seconds: integer, saves: integer, fixes: integer }
---@return number points per hour
function M.pace(run)
  local hours = math.max(run.seconds, 600) / 3600
  return (run.fixes * 3 + run.saves) / hours
end

--- Ranks a run from S down to D.
---@param run { seconds: integer, saves: integer, fixes: integer }
---@return string
function M.rank(run)
  local pace = M.pace(run)
  for _, step in ipairs(M.RANKS) do
    if pace >= step.per_hour then
      return step.rank
    end
  end
  return "D"
end

--- Formats a duration the way the results screen does.
---@param seconds integer
---@return string like "2h 13m" or "45m"
function M.duration(seconds)
  local minutes = math.floor(seconds / 60)
  if minutes < 60 then
    return minutes .. "m"
  end
  return ("%dh %02dm"):format(math.floor(minutes / 60), minutes % 60)
end

--- Tells whether a run lasted long enough to be worth remembering.
---@param run { seconds: integer }
---@return boolean
function M.worth_saving(run)
  return run.seconds >= M.MIN_SECONDS
end

--- Counts errors fixed between two diagnostic readings of a buffer.
---@param before integer|nil errors at the previous reading
---@param after integer errors now
---@return integer
function M.fixed(before, after)
  return math.max(0, (before or after) - after)
end

--- Builds the dashboard line for a stored run in the franchise's words.
---@param words { last_run: string, rank: string, saves: string, fixes: string } lore.words
---@param run { seconds: integer, saves: integer, fixes: integer, rank: string }
---@return string
function M.summary(words, run)
  return ("%s  ·  %s %s  ·  %s  ·  %d %s  ·  %d %s"):format(
    words.last_run,
    words.rank,
    run.rank,
    M.duration(run.seconds),
    run.saves,
    words.saves,
    run.fixes,
    words.fixes
  )
end

return M
