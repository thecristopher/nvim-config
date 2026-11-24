-- The year card: a year of the chronicle told in one card, the hours, the days, the ranks, the
-- best day, the foe you felled the most and the feats unlocked. Pure logic only.
local results = require("core.results.actions")
local trophies = require("core.hud.actions.trophies")

local M = {}

local RANKS = { "S", "A", "B", "C", "D" }

-- days written before runs counted only active time can hold more hours than a day has
M.DAY_CAP = 24 * 3600

local function in_year(date, year)
  return type(date) == "string" and date:sub(1, 5) == ("%d-"):format(year)
end

--- The chronicle's days that fall in a year.
---@param history table the chronicle
---@param year integer
---@return table history of that year only
function M.days_of(history, year)
  local days = {}
  for date, day in pairs(history or {}) do
    if in_year(date, year) and type(day) == "table" then
      days[date] = day
    end
  end
  return days
end

local function rank_order(rank)
  for index, known in ipairs(RANKS) do
    if known == rank then
      return index
    end
  end
  return #RANKS + 1
end

-- the day with the finest rank, the longest one when two share it
local function best_day(days)
  local best, best_date
  for date, day in pairs(days) do
    local order = rank_order(day.rank)
    local better = not best
      or order < best.order
      or (order == best.order and (day.seconds or 0) > (best.seconds or 0))
    if better then
      best, best_date = { order = order, seconds = day.seconds }, date
    end
  end
  return best_date
end

--- The foe felled the most among the ones last felled that year.
---@param bestiary table
---@param year integer
---@return string|nil key, integer kills
function M.top_foe(bestiary, year)
  local top, kills = nil, 0
  for _, foes in pairs(bestiary or {}) do
    for key, entry in pairs(type(foes) == "table" and foes or {}) do
      local count = type(entry) == "table" and tonumber(entry.kills) or 0
      if in_year(entry.last, year) and count > kills then
        top, kills = key, count
      end
    end
  end
  return top, kills
end

--- The feats unlocked during a year, in the order they came.
---@param store table the feats, { [id] = date }
---@param year integer
---@return string[] ids
function M.feats_of(store, year)
  local ids = {}
  for id, date in pairs(store or {}) do
    if in_year(date, year) then
      table.insert(ids, id)
    end
  end
  table.sort(ids, function(a, b)
    return store[a] < store[b] or (store[a] == store[b] and a < b)
  end)
  return ids
end

--- Everything the card shows for a year.
---@param stores { chronicle: table, bestiary: table, feats: table }
---@param year integer
---@return table summary
function M.summary(stores, year)
  local days = M.days_of(stores.chronicle, year)
  local summary = { year = year, days = 0, seconds = 0, saves = 0, fixes = 0, ranks = {} }
  for _, day in pairs(days) do
    summary.days = summary.days + 1
    summary.seconds = summary.seconds + math.min(day.seconds or 0, M.DAY_CAP)
    summary.saves = summary.saves + (day.saves or 0)
    summary.fixes = summary.fixes + (day.fixes or 0)
    if day.rank then
      summary.ranks[day.rank] = (summary.ranks[day.rank] or 0) + 1
    end
  end
  summary.streak = trophies.longest_streak(days)
  summary.best_day = best_day(days)
  summary.best_rank = summary.best_day and days[summary.best_day].rank or nil
  summary.foe, summary.foe_kills = M.top_foe(stores.bestiary, year)
  summary.feats = M.feats_of(stores.feats, year)
  return summary
end

local function rank_line(ranks)
  local parts = {}
  for _, rank in ipairs(RANKS) do
    if ranks[rank] then
      table.insert(parts, ("%s×%d"):format(rank, ranks[rank]))
    end
  end
  return #parts > 0 and table.concat(parts, "  ") or "-"
end

--- The rows of the card, each a label and its value, nil labels for the headings.
---@param summary table from M.summary
---@param said { foe: string|nil, feats: string[], song: { title: string, artist: string, plays: integer }|nil } the foe and feats in the world's words, and the song of the year
---@return { label: string|nil, value: string }[]
function M.rows(summary, said)
  local rows = {
    { label = "Hours", value = results.duration(summary.seconds) },
    { label = "Days fought", value = tostring(summary.days) },
    { label = "Longest streak", value = ("%d days"):format(summary.streak) },
    { label = "Saves", value = tostring(summary.saves) },
    { label = "Errors cleared", value = tostring(summary.fixes) },
    { label = "Ranks", value = rank_line(summary.ranks) },
  }
  if summary.best_day then
    table.insert(rows, {
      label = "Best day",
      value = ("%s, rank %s"):format(summary.best_day, summary.best_rank or "-"),
    })
  end
  if said.foe then
    table.insert(
      rows,
      { label = "Nemesis", value = ("%s ×%d"):format(said.foe, summary.foe_kills) }
    )
  end
  if said.song then
    local song = ("%s · %s (%d plays)"):format(said.song.title, said.song.artist, said.song.plays)
    table.insert(rows, { label = "Song of the year", value = song })
  end
  if #said.feats > 0 then
    table.insert(rows, { value = "" })
    table.insert(rows, { value = ("Feats unlocked: %d"):format(#said.feats) })
    for _, name in ipairs(said.feats) do
      table.insert(rows, { value = "  " .. name })
    end
  end
  return rows
end

local function parse(date)
  local year, month, day = date:match("^(%d+)-(%d+)-(%d+)$")
  return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
end

--- The Monday that starts the week of a date, the id of that week.
---@param date string as YYYY-MM-DD
---@return string as YYYY-MM-DD
function M.monday_of(date)
  local time = parse(date)
  -- Monday is 0, Sunday is 6
  local weekday = (os.date("*t", time).wday + 5) % 7
  return tostring(os.date("%Y-%m-%d", time - weekday * 86400))
end

--- The week before the one a date falls in, told like the year card: days, hours, errors, the
--- finest rank and the feats unlocked.
---@param stores { chronicle: table, feats: table }
---@param today string as YYYY-MM-DD
---@return { from: string, to: string, days: integer, seconds: integer, fixes: integer, best_rank: string|nil, feats: string[] }
function M.last_week(stores, today)
  local monday = parse(M.monday_of(today))
  local from = tostring(os.date("%Y-%m-%d", monday - 7 * 86400))
  local to = tostring(os.date("%Y-%m-%d", monday - 86400))
  local week = { from = from, to = to, days = 0, seconds = 0, fixes = 0, feats = {} }
  local best
  for date, day in pairs(stores.chronicle or {}) do
    if type(day) == "table" and date >= from and date <= to then
      week.days = week.days + 1
      week.seconds = week.seconds + math.min(day.seconds or 0, M.DAY_CAP)
      week.fixes = week.fixes + (day.fixes or 0)
      local order = rank_order(day.rank)
      best = (not best or order < best) and order or best
    end
  end
  week.best_rank = best and RANKS[best] or nil
  for id, date in pairs(stores.feats or {}) do
    if type(date) == "string" and date >= from and date <= to then
      table.insert(week.feats, id)
    end
  end
  table.sort(week.feats)
  return week
end

--- The recap's lines, with the feats already named in the world's words.
---@param week table from M.last_week
---@param feat_names string[]
---@return string[]
function M.week_lines(week, feat_names)
  local lines = {
    ("%d days · %s · %d errors cleared"):format(
      week.days,
      results.duration(week.seconds),
      week.fixes
    ),
    "Finest rank " .. (week.best_rank or "-"),
  }
  if #feat_names > 0 then
    table.insert(lines, "Feats: " .. table.concat(feat_names, ", "))
  end
  return lines
end

--- Tells whether a year has anything to show.
---@param summary table from M.summary
---@return boolean
function M.empty(summary)
  return summary.days == 0 and #summary.feats == 0
end

return M
