local feats = require("core.feats.actions")

local bestiary = {
  ["/haligtree"] = { ["Lua undefined-global"] = { kills = 70, last = "2026-11-03" } },
  ["/raccoon-city"] = { ["ts 2322"] = { kills = 35, last = "2026-11-04" } },
}

local function week_of_s()
  local chronicle = {}
  for day = 1, 7 do
    chronicle[("2026-11-%02d"):format(day)] = { rank = "S" }
  end
  return chronicle
end

local quiet_run = { seconds = 600, saves = 3 }

describe("cycle", function()
  it("keeps Inde on the first cycle before a full year has passed", function()
    assert.equal(1, feats.cycle({ ["2025-12-01"] = {} }, "2026-11-30"))
  end)

  it("starts Malenia's second journey on the anniversary of her first day", function()
    assert.equal(2, feats.cycle({ ["2025-12-01"] = {} }, "2026-12-01"))
  end)

  it("counts one cycle per full year for Claire", function()
    assert.equal(3, feats.cycle({ ["2024-02-14"] = {}, ["2026-01-01"] = {} }, "2026-11-23"))
  end)

  it("stays on the first cycle with an empty chronicle", function()
    assert.equal(1, feats.cycle({}, "2026-11-23"))
  end)

  it("names only the cycles past the first", function()
    assert.is_nil(feats.cycle_label(1, "Journey %d"))
    assert.equal("Journey 2", feats.cycle_label(2, "Journey %d"))
  end)
end)

describe("night", function()
  it("counts Claire's 3 AM save as a night shift", function()
    assert.is_true(feats.night(3))
  end)

  it("leaves Inde's evening and morning saves out", function()
    assert.is_false(feats.night(1))
    assert.is_false(feats.night(5))
  end)
end)

describe("stats", function()
  it("gathers what Malenia earned from the stores and the run", function()
    local stats =
      feats.stats(bestiary, week_of_s(), { seconds = 900, saves = 12, night = true }, "2026-11-08")
    assert.equal(105, stats.felled)
    assert.equal(7, stats.days)
    assert.equal(7, stats.streak)
    assert.equal(7, stats.s_days)
    assert.equal(12, stats.run_saves)
    assert.is_true(stats.night)
    assert.equal(1, stats.cycle)
  end)
end)

describe("newly", function()
  it("unlocks every feat Claire earned, in the showcase's order", function()
    local stats = feats.stats(bestiary, week_of_s(), quiet_run, "2026-11-08")
    local ids = vim.tbl_map(function(feat)
      return feat.id
    end, feats.newly({}, stats))
    assert.same({ "first_blood", "hundred_foes", "first_s", "week_streak" }, ids)
  end)

  it("never unlocks a feat Inde already holds", function()
    local stats = feats.stats(bestiary, {}, quiet_run, "2026-11-08")
    local fresh = feats.newly({ first_blood = "2026-02-14", hundred_foes = "2026-03-01" }, stats)
    assert.same({}, fresh)
  end)

  it("unlocks the marathon after four hours of one run", function()
    local stats = feats.stats({}, {}, { seconds = 4 * 3600, saves = 0 }, "2026-11-08")
    assert.equal("marathon", feats.newly({}, stats)[1].id)
  end)
end)

describe("record and entries", function()
  it("keeps the first day a feat was unlocked", function()
    local store = feats.record(
      { first_blood = "2026-02-14" },
      { { id = "first_blood" } },
      "2026-11-23"
    )
    assert.equal("2026-02-14", store.first_blood)
  end)

  it("names every feat in the world's words and marks the locked ones", function()
    local entries = feats.entries({ first_blood = "2026-02-14" }, { first_blood = "First Blood" })
    assert.equal(#feats.FEATS, #entries)
    assert.equal("First Blood", entries[1].name)
    assert.equal("2026-02-14", entries[1].date)
    assert.is_nil(entries[2].date)
  end)

  it("counts the feats unlocked of the whole showcase", function()
    local unlocked, total = feats.count({ first_blood = "2026-02-14", marathon = "2026-11-01" })
    assert.equal(2, unlocked)
    assert.equal(#feats.FEATS, total)
  end)
end)
