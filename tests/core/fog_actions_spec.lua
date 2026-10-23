local actions = require("core.fog.actions")

local function always(value) return function() return value end end

describe("blend_at", function()
  it("starts invisible so Claire never sees the wall coming", function()
    assert.equal(100, actions.blend_at(0))
  end)

  it("is thickest at the peak of the crossing", function()
    assert.equal(actions.THICKEST, actions.blend_at(actions.PEAK))
  end)

  it("is gone again once Malenia steps through", function()
    assert.equal(100, actions.blend_at(1))
  end)

  it("thins out gradually after the peak", function()
    assert.is_true(actions.blend_at(0.5) < actions.blend_at(0.8))
  end)

  it("clamps progress that overshoots the end", function()
    assert.equal(100, actions.blend_at(1.4))
  end)
end)

describe("texture", function()
  it("fills one line per row at the full width", function()
    local lines = actions.texture(12, 5, always(0.9))
    assert.equal(5, #lines)
    assert.equal(12, vim.fn.strchars(lines[1]))
  end)

  it("leaves clear air when every roll is high", function()
    assert.equal("    ", actions.texture(4, 3, always(0.99))[2])
  end)

  it("draws thick wisps when every roll is low, like the mist before Inde's date", function()
    assert.equal("▒▒▒▒", actions.texture(4, 3, always(0))[2])
  end)
end)
