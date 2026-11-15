local actions = require("core.heartbeat.actions")

describe("condition", function()
  it("stays calm on Claire's clean love letter", function()
    assert.equal("fine", actions.condition(0, 0))
  end)

  it("races when Malenia leaves three errors behind", function()
    assert.equal("danger", actions.condition(3, 0))
  end)
end)

describe("pulse", function()
  it("peaks with the lub at the start of every beat", function()
    local lub = 60000 / 60 * (actions.LUB.at + actions.LUB.width / 2)
    assert.near(actions.LUB.peak, actions.pulse(lub, 60), 0.0001)
  end)

  it("answers with a softer dub right after", function()
    local dub = 60000 / 60 * (actions.DUB.at + actions.DUB.width / 2)
    assert.near(actions.DUB.peak, actions.pulse(dub, 60), 0.0001)
  end)

  it("rests between beats", function()
    assert.equal(0, actions.pulse(800, 60))
  end)

  it("comes back on the next beat", function()
    assert.near(actions.pulse(70, 60), actions.pulse(1070, 60), 0.0001)
  end)
end)

describe("glow_level", function()
  it("stays dim while the heart rests", function()
    assert.equal(1, actions.glow_level(800, "fine"))
  end)

  it("lights up fully at the lub", function()
    local lub = 60000 / 60 * (actions.LUB.at + actions.LUB.width / 2)
    assert.equal(actions.GLOW_LEVELS, actions.glow_level(lub, "fine"))
  end)
end)

describe("PACES", function()
  it("beats faster as Inde's buffer gets worse", function()
    assert.is_true(actions.PACES.fine.bpm < actions.PACES.caution.bpm)
    assert.is_true(actions.PACES.caution.bpm < actions.PACES.danger.bpm)
  end)

  it("breaks the heart when things are dangerous", function()
    assert.are_not.equal(actions.PACES.fine.glyph, actions.PACES.danger.glyph)
  end)
end)
