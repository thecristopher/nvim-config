local trophies = require("core.hud.actions.trophies")

local bestiary = {
  ["/haligtree"] = { ["Lua undefined-global"] = { kills = 7, last = "2026-11-03" } },
  ["/raccoon-city"] = {
    ["ts 2322"] = { kills = 3, last = "2026-11-04" },
    ["eslint no-unused-vars"] = { kills = 2, last = "2026-11-04" },
  },
}

local chronicle = {
  ["2026-11-01"] = { rank = "B" },
  ["2026-11-02"] = { rank = "A" },
  ["2026-11-03"] = { rank = "S" },
  ["2026-11-05"] = { rank = "S" },
  ["2026-11-06"] = { rank = "D" },
}

describe("felled", function()
  it("counts every foe Malenia and Claire felled across their repos", function()
    assert.equal(12, trophies.felled(bestiary))
  end)

  it("counts nothing before the first fight", function()
    assert.equal(0, trophies.felled({}))
    assert.equal(0, trophies.felled(nil))
  end)
end)

describe("best_rank", function()
  it("finds the first day Inde earned an S", function()
    local rank, date = trophies.best_rank(chronicle)
    assert.equal("S", rank)
    assert.equal("2026-11-03", date)
  end)

  it("has no rank before any run ended", function()
    assert.is_nil(trophies.best_rank({}))
  end)
end)

describe("days and streak", function()
  it("counts the anniversary week Claire fought", function()
    assert.equal(5, trophies.days(chronicle))
  end)

  it("finds the longest run of days in a row", function()
    assert.equal(3, trophies.longest_streak(chronicle))
  end)

  it("crosses a month without breaking Malenia's streak", function()
    assert.equal(
      2,
      trophies.longest_streak({ ["2026-10-31"] = { rank = "B" }, ["2026-11-01"] = { rank = "C" } })
    )
  end)

  it("ignores keys that are not dates", function()
    assert.equal(1, trophies.days({ ["2026-11-14"] = {}, notes = {} }))
  end)
end)

describe("summary", function()
  it("gathers everything the trophies tab shows", function()
    assert.same(
      { felled = 12, rank = "S", rank_date = "2026-11-03", days = 5, streak = 3 },
      trophies.summary(bestiary, chronicle)
    )
  end)

  it("is empty until Inde fights or felled anything", function()
    assert.is_true(trophies.empty(trophies.summary({}, {})))
    assert.is_false(trophies.empty(trophies.summary(bestiary, {})))
  end)
end)

describe("current_streak", function()
  local history = {
    ["2026-11-10"] = { rank = "B" },
    ["2026-11-13"] = { rank = "A" },
    ["2026-11-14"] = { rank = "S" },
    ["2026-11-15"] = { rank = "B" },
  }

  it("counts the days Malenia fought in a row up to today", function()
    assert.equal(3, trophies.current_streak(history, "2026-11-15"))
  end)

  it("still counts the run when today has no fight yet", function()
    assert.equal(3, trophies.current_streak(history, "2026-11-16"))
  end)

  it("drops to zero once Inde skipped a day", function()
    assert.equal(0, trophies.current_streak(history, "2026-11-18"))
    assert.equal(0, trophies.current_streak({}, "2026-11-18"))
  end)
end)
