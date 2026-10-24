local actions = require("core.fog.actions")

describe("density_at", function()
  it("starts clear so Claire never sees the wall coming", function()
    assert.equal(0, actions.density_at(0))
  end)

  it("is thickest once the mist has risen", function()
    assert.equal(1, actions.density_at(actions.RISE))
  end)

  it("holds thick while the new project opens", function()
    assert.equal(1, actions.density_at((actions.RISE + actions.HOLD) / 2))
  end)

  it("is gone again once Malenia steps through", function()
    assert.equal(0, actions.density_at(1))
  end)

  it("thins out gradually after the hold", function()
    assert.is_true(actions.density_at(0.6) > actions.density_at(0.85))
  end)

  it("clamps progress that overshoots the end", function()
    assert.equal(0, actions.density_at(1.4))
  end)
end)

describe("cloud", function()
  it("always stays between clear air and full cloud", function()
    for row = 0, 40, 5 do
      for col = 0, 200, 13 do
        local cloud = actions.cloud(col, row, 41, 3.7)
        assert.is_true(cloud >= 0 and cloud <= 1)
      end
    end
  end)

  it("drifts smoothly, neighbors never jump from clear to thick", function()
    for col = 0, 120 do
      local here, next_door = actions.cloud(col, 20, 41, 1.2), actions.cloud(col + 1, 20, 41, 1.2)
      assert.is_true(math.abs(here - next_door) < 0.15)
    end
  end)

  it("pools at eye level more than at the edges of the screen", function()
    local middle, top = 0, 0
    for col = 0, 200 do
      middle = middle + actions.cloud(col, 20, 41, 0.5)
      top = top + actions.cloud(col, 0, 41, 0.5)
    end
    assert.is_true(middle > top)
  end)
end)

describe("row_levels", function()
  it("gives every column a level within range", function()
    local levels = actions.row_levels(30, 10, 21, 2.0, 0)
    assert.equal(30, #levels)
    for _, level in ipairs(levels) do assert.is_true(level >= 0 and level <= actions.LEVELS) end
  end)

  it("moves the clouds as they drift", function()
    local still = actions.row_levels(60, 10, 21, 2.0, 0)
    local drifted = actions.row_levels(60, 10, 21, 2.0, actions.DRIFT)
    assert.are_not.same(still, drifted)
  end)
end)

describe("runs", function()
  it("joins equal neighbors into one run", function()
    assert.same({ { 0, 3, 2 }, { 3, 4, 5 } }, actions.runs({ 2, 2, 2, 5 }))
  end)

  it("gives a run to every change, like Inde's playlist skipping tracks", function()
    assert.equal(3, #actions.runs({ 1, 2, 1 }))
  end)

  it("has nothing to say about an empty row", function()
    assert.same({}, actions.runs({}))
  end)
end)

describe("blend_for", function()
  it("keeps clear air invisible", function()
    assert.equal(100, actions.blend_for(0, 1))
  end)

  it("keeps everything invisible before the wall rises", function()
    assert.equal(100, actions.blend_for(actions.LEVELS, 0))
  end)

  it("never hides the editor completely, even at the thickest cloud", function()
    assert.is_true(actions.blend_for(actions.LEVELS, 1) > 0)
  end)

  it("lets thicker clouds hide more of the code", function()
    assert.is_true(actions.blend_for(actions.LEVELS, 1) < actions.blend_for(2, 1))
  end)
end)
