-- The trophies the HUD shows: foes felled from the bestiary, the finest rank, the days fought and
-- the longest run of days in a row, from the chronicle. Pure counting only.
local M = {}

-- best first, the same ranks core/results hands out
M.RANKS = { "S", "A", "B", "C", "D" }

--- Counts every foe felled in every repo of the bestiary.
---@param store table the bestiary, { [repo] = { [key] = { kills } } }
---@return integer
function M.felled(store)
  local total = 0
  for _, foes in pairs(store or {}) do
    for _, entry in pairs(type(foes) == "table" and foes or {}) do
      total = total + (tonumber(type(entry) == "table" and entry.kills) or 0)
    end
  end
  return total
end

local function rank_order(rank)
  for index, known in ipairs(M.RANKS) do
    if known == rank then
      return index
    end
  end
  return nil
end

--- Finds the finest rank of the chronicle and the first day it was earned.
---@param history table the chronicle, { ["2026-10-29"] = { rank } }
---@return string|nil rank, string|nil date
function M.best_rank(history)
  local best, best_date
  for date, day in pairs(history or {}) do
    local order = rank_order(type(day) == "table" and day.rank)
    local better = order and (not best or order < best or (order == best and date < best_date))
    if better then
      best, best_date = order, date
    end
  end
  return best and M.RANKS[best] or nil, best_date
end

local function day_number(date)
  local year, month, day = date:match("^(%d+)-(%d+)-(%d+)$")
  if not year then
    return nil
  end
  -- noon keeps a daylight saving shift from moving the day
  local time = os.time({ year = year, month = month, day = day, hour = 12 })
  return math.floor(time / 86400 + 0.5)
end

local function sorted_days(history)
  local days = {}
  for date in pairs(history or {}) do
    local number = day_number(date)
    if number then
      table.insert(days, number)
    end
  end
  table.sort(days)
  return days
end

--- Counts the days the chronicle remembers.
---@param history table
---@return integer
function M.days(history)
  return #sorted_days(history)
end

--- The longest run of days fought one after another.
---@param history table
---@return integer
function M.longest_streak(history)
  local longest, current, previous = 0, 0, nil
  for _, number in ipairs(sorted_days(history)) do
    current = previous and number == previous + 1 and current + 1 or 1
    longest = math.max(longest, current)
    previous = number
  end
  return longest
end

--- The run of days fought that reaches today or yesterday, zero once a day was skipped.
---@param history table
---@param today string as YYYY-MM-DD
---@return integer
function M.current_streak(history, today)
  local days = sorted_days(history)
  local now = day_number(today)
  local last = days[#days]
  if not now or not last or now - last > 1 then
    return 0
  end
  local streak = 1
  for index = #days - 1, 1, -1 do
    if days[index] ~= days[index + 1] - 1 then
      break
    end
    streak = streak + 1
  end
  return streak
end

--- Everything the trophies tab shows, from the two stores.
---@param bestiary table
---@param chronicle table
---@return { felled: integer, rank: string|nil, rank_date: string|nil, days: integer, streak: integer }
function M.summary(bestiary, chronicle)
  local rank, rank_date = M.best_rank(chronicle)
  return {
    felled = M.felled(bestiary),
    rank = rank,
    rank_date = rank_date,
    days = M.days(chronicle),
    streak = M.longest_streak(chronicle),
  }
end

--- Tells whether there is anything to show yet.
---@param summary table from M.summary
---@return boolean
function M.empty(summary)
  return summary.felled == 0 and summary.days == 0
end

return M
