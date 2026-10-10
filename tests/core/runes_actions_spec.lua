local actions = require("core.runes.actions")

local function held(amount, bloodstain) return { held = amount, bloodstain = bloodstain or 0 } end

describe("format", function()
  it("groups Radahn's bounty by thousands", function()
    assert.equal("1,234,567", actions.format(1234567))
  end)

  it("leaves small amounts alone", function()
    assert.equal("800", actions.format(800))
  end)

  it("never leads with a comma", function()
    assert.equal("123,456", actions.format(123456))
  end)
end)

describe("gain_for_edits", function()
  it("pays out for every edit since the last save", function()
    assert.equal(4 * actions.RUNES_PER_EDIT, actions.gain_for_edits(4))
  end)

  it("pays nothing when nothing changed", function()
    assert.equal(0, actions.gain_for_edits(nil))
  end)
end)

describe("roll", function()
  it("starts at the old total", function()
    assert.equal(100, actions.roll(100, 900, 0))
  end)

  it("lands on the new total", function()
    assert.equal(900, actions.roll(100, 900, 1))
  end)
end)

describe("after_banner", function()
  it("drops every rune as a bloodstain on YOU DIED", function()
    assert.same(held(0, 5000), actions.after_banner(held(5000), "died"))
  end)

  it("loses the older bloodstain when Malenia kills you twice", function()
    assert.same(held(0, 200), actions.after_banner(held(200, 5000), "died"))
  end)

  it("reclaims the bloodstain and pays the bounty when an enemy falls", function()
    assert.same(held(5800 + 100, 0), actions.after_banner(held(100, 5000), "felled"))
  end)

  it("ignores banners that carry no bounty", function()
    assert.same(held(100, 50), actions.after_banner(held(100, 50), "region"))
  end)
end)

describe("persistence", function()
  it("round trips through the state file format", function()
    assert.same(held(42, 7), actions.decode(actions.encode(held(42, 7))))
  end)

  it("starts a fresh Tarnished with nothing when the file is garbage", function()
    assert.same(held(0, 0), actions.decode("wesker was here"))
  end)
end)

describe("breath", function()
  it("starts exhaled", function()
    assert.equal(0, actions.breath(0))
  end)

  it("is fully inhaled halfway through the period", function()
    assert.near(1, actions.breath(actions.GLOW_PERIOD / 2), 0.0001)
  end)
end)
