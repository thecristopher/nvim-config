-- The chronicle: every day you fought, as a grid of weeks lit by the day's rank and commits.
-- The history is shaped like { ["2026-10-29"] = { seconds, saves, fixes, rank } }. Pure logic only.
local results = require("core.results.actions")

local M = {}

M.WEEKS = 20
M.DAYS = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }
M.LEVELS = 4

local RANK_LEVEL = { S = 4, A = 3, B = 2, C = 1, D = 1 }
local COMMIT_STEPS = { 10, 6, 3, 1 }

--- Adds a finished run to its day, the day's rank follows the totals.
---@param history table
---@param date string like "2026-10-29"
---@param run { seconds: integer, saves: integer, fixes: integer }
---@return table history
function M.merge_day(history, date, run)
  local day = history[date] or { seconds = 0, saves = 0, fixes = 0 }
  day.seconds = day.seconds + run.seconds
  day.saves = day.saves + run.saves
  day.fixes = day.fixes + run.fixes
  day.rank = results.rank(day)
  history[date] = day
  return history
end

--- Counts commits per day from `git log --format=%ad --date=short`.
---@param stdout string|nil
---@return table<string, integer>
function M.commits_per_day(stdout)
  local counts = {}
  for date in (stdout or ""):gmatch("%d%d%d%d%-%d%d%-%d%d") do
    counts[date] = (counts[date] or 0) + 1
  end
  return counts
end

local function commit_level(count)
  for index, step in ipairs(COMMIT_STEPS) do
    if count >= step then
      return M.LEVELS - index + 1
    end
  end
  return 0
end

--- How lit a day is, from 0 (not fought) to LEVELS, the brighter of its rank and its commits.
---@param day { rank?: string }|nil
---@param commits integer|nil
---@return integer
function M.level(day, commits)
  local by_rank = day and RANK_LEVEL[day.rank] or 0
  return math.max(by_rank, commit_level(commits or 0))
end

local function parse(date)
  local year, month, day = date:match("^(%d+)-(%d+)-(%d+)$")
  return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
end

-- Monday is 0, Sunday is 6
local function weekday(time)
  return (os.date("*t", time).wday + 5) % 7
end

--- The grid of the last weeks, one row per weekday and one column per week, the last one this week.
---@param history table
---@param commits table<string, integer>
---@param today string like "2026-10-29"
---@param weeks? integer M.WEEKS by default
---@return { date: string, level: integer, future: boolean }[][] rows Monday first
function M.grid(history, commits, today, weeks)
  weeks = weeks or M.WEEKS
  local now = parse(today)
  local monday = now - weekday(now) * 86400
  local first = monday - (weeks - 1) * 7 * 86400
  local rows = {}
  for row = 1, 7 do
    rows[row] = {}
    for week = 1, weeks do
      local time = first + ((week - 1) * 7 + row - 1) * 86400
      local date = os.date("%Y-%m-%d", time)
      rows[row][week] =
        { date = date, level = M.level(history[date], commits[date]), future = time > now }
    end
  end
  return rows
end

--- Counts the days fought in a grid and how many ended at each rank.
---@param history table
---@param rows table[][] from M.grid
---@return { days: integer, ranks: table<string, integer> }
function M.totals(history, rows)
  local days, ranks = 0, {}
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row) do
      if cell.level > 0 then
        days = days + 1
      end
      local day = history[cell.date]
      if day and day.rank then
        ranks[day.rank] = (ranks[day.rank] or 0) + 1
      end
    end
  end
  return { days = days, ranks = ranks }
end

return M
