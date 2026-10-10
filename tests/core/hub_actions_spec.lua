local actions = require("core.hub.actions")

local function always(value) return function() return value end end

describe("pick_message", function()
  it("picks the first message at the bottom of the roll", function()
    assert.equal(actions.MESSAGES[1], actions.pick_message(always(0)))
  end)

  it("picks the last message at the top of the roll", function()
    assert.equal(actions.MESSAGES[#actions.MESSAGES], actions.pick_message(always(0.9999)))
  end)
end)

describe("shimmer_level", function()
  it("lights up where the band is passing", function()
    local mid_sweep = actions.SHIMMER.sweep / 2
    local lit = 0
    for col = 0, 120 do lit = math.max(lit, actions.shimmer_level(col, 0, mid_sweep, 120)) end
    assert.equal(actions.SHIMMER_LEVELS, lit)
  end)

  it("rests between sweeps", function()
    assert.equal(0, actions.shimmer_level(40, 0, actions.SHIMMER.sweep + 100, 120))
  end)
end)

describe("embers", function()
  local function spawned() return actions.spawn_ember(always(0.5), 100, 40) end

  it("rise as time passes", function()
    local ember = spawned()
    local start = ember.y
    actions.step_ember(ember, 500)
    assert.is_true(ember.y < start)
  end)

  it("burn out once their life is spent", function()
    local ember = spawned()
    actions.step_ember(ember, ember.life + 1)
    assert.is_false(actions.ember_alive(ember))
  end)

  it("glow hottest early in their flight", function()
    local ember = spawned()
    actions.step_ember(ember, ember.life * 0.15)
    local _, level = actions.ember_look(ember)
    assert.equal(actions.EMBER_LEVELS, level)
  end)

  it("scale their count to the window", function()
    assert.is_true(actions.ember_budget(200, 50) > actions.ember_budget(80, 24))
  end)
end)

describe("quill", function()
  it("writes nothing before it starts", function()
    assert.equal(0, actions.typed(20, 0))
  end)

  it("never writes past the message", function()
    assert.equal(20, actions.typed(20, 60 * 1000))
  end)

  it("lifts off the page once the message lingers long enough", function()
    assert.is_true(actions.quill_done(20, 60 * 1000))
    assert.is_false(actions.quill_visible(20, 60 * 1000))
  end)
end)

describe("occupied", function()
  it("marks both cells of a wide character", function()
    local taken = actions.occupied({ { " ", 1 }, { "龍", 2 }, { " ", 1 } })
    assert.same({ [1] = true, [2] = true }, taken)
  end)
end)
