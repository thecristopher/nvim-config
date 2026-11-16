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
    local middle = actions.SHIMMER.period
      * (actions.SHIMMER.band + 30)
      / (width + actions.SHIMMER.band * 2)
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

describe("bulbs", function()
  it("rings the title on every side", function()
    local rows, cols = {}, {}
    for _, bulb in ipairs(actions.bulbs(20, 5)) do
      rows[bulb.row], cols[bulb.col] = true, true
    end
    assert.is_true(rows[-1] and rows[5])
    assert.is_true(cols[-actions.MARQUEE.spacing] and cols[20 + actions.MARQUEE.spacing - 1])
  end)

  it("walks around the frame in order, so the chase runs like Claire's marquee", function()
    local bulbs = actions.bulbs(20, 5)
    assert.same({ row = -1, col = -actions.MARQUEE.spacing }, bulbs[1])
    -- the last one sits right under the first, closing the ring
    assert.same({ row = 0, col = -actions.MARQUEE.spacing }, bulbs[#bulbs])
  end)

  it("never puts a bulb inside the letters", function()
    for _, bulb in ipairs(actions.bulbs(20, 5)) do
      local inside = bulb.row >= 0 and bulb.row < 5 and bulb.col >= 0 and bulb.col < 20
      assert.is_false(inside)
    end
  end)
end)

describe("bulb_lit", function()
  it("lights one bulb in every few", function()
    local lit = 0
    for index = 1, 12 do
      lit = lit + (actions.bulb_lit(index, 0) and 1 or 0)
    end
    assert.equal(12 / actions.MARQUEE.every, lit)
  end)

  it("moves the light one bulb along on the next step", function()
    assert.equal(actions.bulb_lit(1, 0), actions.bulb_lit(2, actions.MARQUEE.step_ms))
  end)
end)

describe("font_for", function()
  it("writes Malenia's world in thin strokes", function()
    assert.equal(actions.THIN, actions.font_for("shimmer"))
  end)

  it("keeps Claire's drip in solid blocks", function()
    assert.equal(actions.FONT, actions.font_for("drip"))
  end)

  it("has every letter in both fonts at the same height", function()
    for letter, glyph in pairs(actions.FONT) do
      assert.equal(actions.HEIGHT, #actions.THIN[letter])
      assert.equal(actions.HEIGHT, #glyph)
    end
  end)
end)

describe("ring", function()
  it("arcs over the name, every row as wide as asked", function()
    local rows = actions.ring(4, 60)
    assert.equal(4, #rows)
    for _, row in ipairs(rows) do
      assert.equal(60, vim.fn.strdisplaywidth(row))
    end
  end)

  it("is narrowest at the top and widest at the bottom, like an arch over Inde", function()
    local spans = actions.arch(5, 60)
    assert.is_true(spans[1].right - spans[1].left < spans[5].right - spans[5].left)
  end)

  it("turns its corners round", function()
    assert.is_truthy(actions.ring(4, 60)[1]:find("╭", 1, true))
  end)
end)

describe("flicker", function()
  it("keeps the light steady most of the time", function()
    local steady = 0
    for elapsed = 0, 30000, 37 do
      steady = steady + (actions.flicker(elapsed) == 1 and 1 or 0)
    end
    assert.is_true(steady / (30000 / 37) > 0.9)
  end)

  it("stutters at the start of a failing period", function()
    assert.is_true(actions.flicker(10) < 1)
  end)
end)
