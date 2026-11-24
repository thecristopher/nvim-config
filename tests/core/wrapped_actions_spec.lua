local wrapped = require("core.wrapped.actions")

local chronicle = {
  ["2025-12-31"] = { seconds = 3600, saves = 10, fixes = 5, rank = "S" },
  ["2026-02-14"] = { seconds = 7200, saves = 40, fixes = 12, rank = "A" },
  ["2026-02-15"] = { seconds = 1800, saves = 8, fixes = 2, rank = "C" },
  ["2026-11-23"] = { seconds = 5400, saves = 30, fixes = 20, rank = "A" },
}

local bestiary = {
  ["/haligtree"] = {
    ["Lua undefined-global"] = { kills = 9, last = "2026-11-23" },
    ["Lua unused-local"] = { kills = 40, last = "2025-06-01" },
  },
  ["/raccoon-city"] = { ["ts 2322"] = { kills = 4, last = "2026-02-14" } },
}

local feats =
  { first_blood = "2026-02-14", hundred_foes = "2025-07-01", week_streak = "2026-03-01" }

local function summary()
  return wrapped.summary({ chronicle = chronicle, bestiary = bestiary, feats = feats }, 2026)
end

describe("summary", function()
  it("adds up only the days Claire and Inde fought that year", function()
    local year = summary()
    assert.equal(3, year.days)
    assert.equal(14400, year.seconds)
    assert.equal(78, year.saves)
    assert.equal(34, year.fixes)
    assert.same({ A = 2, C = 1 }, year.ranks)
  end)

  it("finds Valentine's day as the longest of the best ranked days", function()
    local year = summary()
    assert.equal("2026-02-14", year.best_day)
    assert.equal("A", year.best_rank)
    assert.equal(2, year.streak)
  end)

  it("picks Malenia's nemesis among the foes felled that year", function()
    local year = summary()
    assert.equal("Lua undefined-global", year.foe)
    assert.equal(9, year.foe_kills)
  end)

  it("lists the feats of that year in the order they came", function()
    assert.same({ "first_blood", "week_streak" }, summary().feats)
  end)

  it("has nothing to show for a year never fought", function()
    local empty = wrapped.summary({ chronicle = chronicle, bestiary = {}, feats = {} }, 2020)
    assert.is_true(wrapped.empty(empty))
  end)
end)

describe("rows", function()
  it("tells the year in labeled rows with the nemesis and the feats", function()
    local rows = wrapped.rows(summary(), { foe = "Margit", feats = { "First Blood" } })
    assert.same({ label = "Hours", value = "4h 00m" }, rows[1])
    local values = vim.tbl_map(function(row)
      return row.value
    end, rows)
    assert.is_true(vim.tbl_contains(values, "Margit ×9"))
    assert.is_true(vim.tbl_contains(values, "  First Blood"))
  end)
end)

describe("rows with a song", function()
  it("names the song Claire and Inde played the most", function()
    local song = { title = "Lovesong", artist = "The Cure", plays = 42 }
    local rows = wrapped.rows(summary(), { feats = {}, song = song })
    local last = rows[#rows]
    assert.same({ label = "Song of the year", value = "Lovesong · The Cure (42 plays)" }, last)
  end)
end)

describe("day cap", function()
  it("never counts more than a day's hours for the day Malenia left nvim open", function()
    local open_for_days =
      { ["2026-11-06"] = { seconds = 99 * 3600, saves = 1, fixes = 0, rank = "D" } }
    local year = wrapped.summary({ chronicle = open_for_days, bestiary = {}, feats = {} }, 2026)
    assert.equal(wrapped.DAY_CAP, year.seconds)
  end)
end)

describe("weekly recap", function()
  it("starts Claire's week on Monday", function()
    assert.equal("2026-11-23", wrapped.monday_of("2026-11-23"))
    assert.equal("2026-11-23", wrapped.monday_of("2026-11-29"))
  end)

  it("tells how Malenia's last week went", function()
    local chronicle = {
      ["2026-11-16"] = { seconds = 7200, fixes = 10, rank = "B" },
      ["2026-11-20"] = { seconds = 3600, fixes = 4, rank = "A" },
      ["2026-11-23"] = { seconds = 3600, fixes = 99, rank = "S" },
    }
    local feats = { week_streak = "2026-11-18", first_blood = "2026-01-02" }
    local week = wrapped.last_week({ chronicle = chronicle, feats = feats }, "2026-11-25")
    assert.equal("2026-11-16", week.from)
    assert.equal("2026-11-22", week.to)
    assert.equal(2, week.days)
    assert.equal(10800, week.seconds)
    assert.equal(14, week.fixes)
    assert.equal("A", week.best_rank)
    assert.same({ "week_streak" }, week.feats)
  end)

  it("writes the recap Inde reads on Monday", function()
    local week = { days = 2, seconds = 10800, fixes = 14, best_rank = "A", feats = {} }
    assert.same(
      { "2 days · 3h 00m · 14 errors cleared", "Finest rank A" },
      wrapped.week_lines(week, {})
    )
  end)
end)
