-- Feats: trophies unlocked once and kept for good, earned from what the bestiary, the chronicle
-- and the run in progress already count. The store is shaped like { [id] = "2026-11-23" }, the
-- day each one was unlocked. The cycle (new game plus) also lives here, since it is earned the
-- same way: one more for every full year since the first day of the chronicle. Pure logic only.
local trophies = require("core.hud.actions.trophies")

local M = {}

-- a save between these hours counts as a night shift
M.NIGHT_FROM, M.NIGHT_TO = 2, 5

-- every feat in the order the showcase lists them, the lore names each one by its id
M.FEATS = {
  {
    id = "first_blood",
    desc = "Fell your first foe",
    earned = function(s)
      return s.felled >= 1
    end,
  },
  {
    id = "hundred_foes",
    desc = "Fell 100 foes",
    earned = function(s)
      return s.felled >= 100
    end,
  },
  {
    id = "thousand_foes",
    desc = "Fell 1000 foes",
    earned = function(s)
      return s.felled >= 1000
    end,
  },
  {
    id = "first_s",
    desc = "End a day with an S rank",
    earned = function(s)
      return s.s_days >= 1
    end,
  },
  {
    id = "ten_s",
    desc = "End 10 days with an S rank",
    earned = function(s)
      return s.s_days >= 10
    end,
  },
  {
    id = "week_streak",
    desc = "Fight 7 days in a row",
    earned = function(s)
      return s.streak >= 7
    end,
  },
  {
    id = "month_streak",
    desc = "Fight 30 days in a row",
    earned = function(s)
      return s.streak >= 30
    end,
  },
  {
    id = "hundred_days",
    desc = "Fight on 100 different days",
    earned = function(s)
      return s.days >= 100
    end,
  },
  {
    id = "marathon",
    desc = "Keep one run going for 4 hours",
    earned = function(s)
      return s.run_seconds >= 4 * 3600
    end,
  },
  {
    id = "hundred_saves",
    desc = "Save 100 times in one run",
    earned = function(s)
      return s.run_saves >= 100
    end,
  },
  {
    id = "night_shift",
    desc = "Save a file between 2 and 5 AM",
    earned = function(s)
      return s.night
    end,
  },
  {
    id = "new_cycle",
    desc = "Reach a second cycle, a full year after your first day",
    earned = function(s)
      return s.cycle >= 2
    end,
  },
}

--- The ids of every feat, the keys the lore has to name.
---@return string[]
function M.ids()
  return vim.tbl_map(function(feat)
    return feat.id
  end, M.FEATS)
end

--- Tells whether an hour of the day falls in the night shift.
---@param hour integer 0 to 23
---@return boolean
function M.night(hour)
  return hour >= M.NIGHT_FROM and hour < M.NIGHT_TO
end

local function first_day(history)
  local first
  for date in pairs(history or {}) do
    if type(date) == "string" and date:match("^%d+%-%d+%-%d+$") and (not first or date < first) then
      first = date
    end
  end
  return first
end

--- The cycle you are on: 1 until a full year has passed since the chronicle's first day, then one
--- more for every year after that.
---@param history table the chronicle
---@param today string as YYYY-MM-DD
---@return integer
function M.cycle(history, today)
  local first = first_day(history)
  if not first then
    return 1
  end
  local years = tonumber(today:sub(1, 4)) - tonumber(first:sub(1, 4))
  -- the anniversary has not come yet this year
  if today:sub(6) < first:sub(6) then
    years = years - 1
  end
  return 1 + math.max(0, years)
end

--- How the world names a cycle past the first one, nil on the first.
---@param cycle integer
---@param format string like "Journey %d"
---@return string|nil
function M.cycle_label(cycle, format)
  if cycle < 2 then
    return nil
  end
  return format:format(cycle)
end

local function s_days(history)
  local count = 0
  for _, day in pairs(history or {}) do
    if type(day) == "table" and day.rank == "S" then
      count = count + 1
    end
  end
  return count
end

--- Everything the feats are judged on, from the stores and the run in progress.
---@param bestiary table
---@param chronicle table
---@param run { seconds: integer, saves: integer, night: boolean|nil }
---@param today string as YYYY-MM-DD
---@return table stats
function M.stats(bestiary, chronicle, run, today)
  return {
    felled = trophies.felled(bestiary),
    days = trophies.days(chronicle),
    streak = trophies.longest_streak(chronicle),
    s_days = s_days(chronicle),
    run_seconds = run.seconds or 0,
    run_saves = run.saves or 0,
    night = run.night == true,
    cycle = M.cycle(chronicle, today),
  }
end

--- The feats earned that are not unlocked yet, in the showcase's order.
---@param store table
---@param stats table from M.stats
---@return table[] feats
function M.newly(store, stats)
  local fresh = {}
  for _, feat in ipairs(M.FEATS) do
    if not store[feat.id] and feat.earned(stats) then
      table.insert(fresh, feat)
    end
  end
  return fresh
end

--- Writes the day each feat was unlocked into the store.
---@param store table
---@param feats table[]
---@param today string as YYYY-MM-DD
---@return table store
function M.record(store, feats, today)
  for _, feat in ipairs(feats) do
    store[feat.id] = store[feat.id] or today
  end
  return store
end

--- Every feat with its name in the world's words and the day it was unlocked, nil while locked.
---@param store table
---@param names table<string, string> lore.trophies.feats
---@return { id: string, name: string, desc: string, date: string|nil }[]
function M.entries(store, names)
  return vim.tbl_map(function(feat)
    return {
      id = feat.id,
      name = names[feat.id] or feat.id,
      desc = feat.desc,
      date = type(store[feat.id]) == "string" and store[feat.id] or nil,
    }
  end, M.FEATS)
end

--- Counts the feats unlocked so far.
---@param store table
---@return integer unlocked, integer total
function M.count(store)
  local unlocked = 0
  for _, feat in ipairs(M.FEATS) do
    if store[feat.id] then
      unlocked = unlocked + 1
    end
  end
  return unlocked, #M.FEATS
end

return M
