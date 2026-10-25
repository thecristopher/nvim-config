local actions = require("core.title.actions")

describe("big", function()
  it("writes every letter five rows tall", function()
    assert.equal(actions.HEIGHT, #actions.big("RE"))
  end)

  it("keeps every row the same width", function()
    local rows = actions.big("RESIDENT EVIL")
    for _, row in ipairs(rows) do
      assert.equal(vim.fn.strdisplaywidth(rows[1]), vim.fn.strdisplaywidth(row))
    end
  end)

  it("reads lowercase the same as uppercase", function()
    assert.same(actions.big("ELDEN"), actions.big("elden"))
  end)

  it("leaves a gap for anything outside the alphabet", function()
    assert.same(actions.big("A A"), actions.big("A?A"))
  end)
end)

describe("shown_today", function()
  it("remembers Malenia's world already greeted her today", function()
    assert.is_true(actions.shown_today("2026-10-24 elden_ring", "2026-10-24", "elden_ring"))
  end)

  it("greets again when the franchise changed", function()
    assert.is_false(actions.shown_today("2026-10-24 elden_ring", "2026-10-24", "resident_evil"))
  end)

  it("greets again the next day", function()
    assert.is_false(actions.shown_today("2026-10-23 resident_evil", "2026-10-24", "resident_evil"))
  end)
end)

describe("shimmer_level", function()
  it("rests at the plain color far from the band", function()
    assert.equal(1, actions.shimmer_level(200, 0, 60))
  end)

  it("glints brightest where the band crosses", function()
    local width = 60
    local middle = actions.SHIMMER.period * (actions.SHIMMER.band + 30) / (width + actions.SHIMMER.band * 2)
    assert.equal(actions.LEVELS, actions.shimmer_level(30, middle, width))
  end)
end)

describe("drips", function()
  local bottom = actions.big("RESIDENT EVIL")[actions.HEIGHT]

  it("bleeds only from solid cells", function()
    local chars = vim.fn.split(bottom, "\\zs")
    for _, drip in ipairs(actions.drips(bottom)) do
      assert.equal("█", chars[drip.col + 1])
    end
  end)

  it("never runs deeper than the title allows", function()
    for _, drip in ipairs(actions.drips(bottom)) do
      assert.is_true(drip.depth >= 1 and drip.depth <= actions.DRIP_DEPTH)
    end
  end)
end)

describe("drip_length", function()
  it("waits for the letters to rise first", function()
    assert.equal(0, actions.drip_length(3, actions.FADE_IN))
  end)

  it("stops at its own depth", function()
    assert.equal(3, actions.drip_length(3, 60000))
  end)
end)
