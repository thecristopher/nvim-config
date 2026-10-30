local actions = require("core.chronicle.actions")

describe("merge_day", function()
  it("adds Claire's runs of the same day and ranks the totals", function()
    local history = actions.merge_day({}, "2026-10-29", { seconds = 1800, saves = 10, fixes = 2 })
    history = actions.merge_day(history, "2026-10-29", { seconds = 1800, saves = 10, fixes = 2 })
    assert.same({ seconds = 3600, saves = 20, fixes = 4, rank = "A" }, history["2026-10-29"])
  end)
end)

describe("commits_per_day", function()
  it("counts Inde's commits per day", function()
    local counts = actions.commits_per_day("2026-10-29\n2026-10-29\n2026-10-27\n")
    assert.same({ ["2026-10-29"] = 2, ["2026-10-27"] = 1 }, counts)
  end)
end)

describe("level", function()
  it("lights a day by the brighter of its rank and its commits", function()
    assert.equal(4, actions.level({ rank = "S" }, 0))
    assert.equal(4, actions.level({ rank = "D" }, 12))
    assert.equal(2, actions.level(nil, 3))
    assert.equal(0, actions.level(nil, nil))
  end)
end)

describe("grid", function()
  local rows = actions.grid(
    { ["2026-10-26"] = { rank = "S" } },
    { ["2026-10-29"] = 1 },
    "2026-10-29",
    2
  )

  it("lays the weeks out Monday first with this week last", function()
    assert.equal(7, #rows)
    assert.equal(2, #rows[1])
    assert.equal("2026-10-19", rows[1][1].date)
    assert.equal("2026-10-26", rows[1][2].date)
    assert.equal("2026-11-01", rows[7][2].date)
  end)

  it("lights the days Malenia fought and leaves the future dark", function()
    assert.equal(4, rows[1][2].level)
    assert.equal(1, rows[4][2].level)
    assert.is_false(rows[4][2].future)
    assert.is_true(rows[5][2].future)
  end)
end)

describe("totals", function()
  it("counts the days fought and the ranks they earned", function()
    local history = { ["2026-10-26"] = { rank = "S" } }
    local rows = actions.grid(history, { ["2026-10-29"] = 1 }, "2026-10-29", 2)
    assert.same({ days = 2, ranks = { S = 1 } }, actions.totals(history, rows))
  end)
end)
