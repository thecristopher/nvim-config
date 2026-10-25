local actions = require("core.motion.actions")

describe("progress", function()
  it("starts at zero", function()
    assert.equal(0, actions.progress(0, 400))
  end)

  it("never overshoots when a timer ticks late", function()
    assert.equal(1, actions.progress(900, 400))
  end)

  it("finishes instantly when there is no duration", function()
    assert.equal(1, actions.progress(0, 0))
  end)
end)

describe("ease", function()
  it("pins every curve to zero and one at the ends", function()
    for name in pairs(actions.easings) do
      assert.near(0, actions.ease(name, 0), 0.001, name)
      assert.near(1, actions.ease(name, 1), 0.001, name)
    end
  end)

  it("rushes out of the gate with out_cubic", function()
    assert.is_true(actions.ease("out_cubic", 0.25) > 0.25)
  end)

  it("falls back to linear for an unknown curve", function()
    assert.equal(0.5, actions.ease("radahn_meteor", 0.5))
  end)
end)

describe("mix", function()
  it("stays at the start color at zero", function()
    assert.equal(0xC9A84C, actions.mix(0xC9A84C, 0x000000, 0))
  end)

  it("lands on the end color at one", function()
    assert.equal(0xC42B3B, actions.mix(0xC9A84C, 0xC42B3B, 1))
  end)

  it("meets in the middle at one half", function()
    assert.equal(0x808080, actions.mix(0x000000, 0xFFFFFF, 0.5))
  end)
end)

describe("mix_hl", function()
  it("blends colors and keeps the target's other attributes", function()
    local mixed = actions.mix_hl({ fg = 0x000000 }, { fg = 0xFFFFFF, bold = true }, 0.5)
    assert.same({ fg = 0x808080, bold = true }, mixed)
  end)

  it("snaps straight to a link", function()
    assert.same({ link = "Comment" }, actions.mix_hl({ fg = 0x000000 }, { link = "Comment" }, 0.1))
  end)
end)

describe("changed_groups", function()
  it("lists only groups whose colors move", function()
    local before = { Melina = { fg = 1 }, Margit = { fg = 2 }, Morgott = { link = "Margit" } }
    local after = { Melina = { fg = 9 }, Margit = { fg = 2 }, Morgott = { link = "Margit" } }
    assert.same({ "Melina" }, actions.changed_groups(before, after))
  end)
end)

describe("hex conversion", function()
  it("round trips Leyndell gold", function()
    assert.equal("#C9A84C", actions.to_hex(actions.to_int("#C9A84C")))
  end)
end)
