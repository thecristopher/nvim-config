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

describe("spaced", function()
  it("carves Malenia into wide capitals", function()
    assert.equal("M  A  L  E  N  I  A", actions.spaced("Malenia"))
  end)

  it("leaves a short name like Mohg readable", function()
    assert.equal("M  O  H  G", actions.spaced("mohg"))
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

describe("weather", function()
  local snow = actions.weather("ordina")

  it("gives every region its own sky", function()
    for _, region in ipairs(require("core.themes.actions").REGIONS) do
      assert.equal(actions.WEATHER[region.name], actions.weather(region.name))
    end
  end)

  it("falls back to Leyndell's embers for a region it does not know", function()
    assert.equal(actions.WEATHER.leyndell, actions.weather("raccoon_city"))
  end)

  it("lets Malenia's rot petals drift down from the top", function()
    local petal = actions.spawn_ember(always(0.5), 100, 40, actions.weather("haligtree"))
    local start = petal.y
    actions.step_ember(petal, 500)
    assert.is_true(start < 40 * 0.25)
    assert.is_true(petal.y > start)
  end)

  it("melts snow once it reaches the floor of the window", function()
    local flake = actions.spawn_ember(always(0.5), 100, 40, snow)
    flake.y = 40
    assert.is_false(actions.ember_alive(flake))
  end)

  it("draws snowflakes with Ordina's glyphs", function()
    local flake = actions.spawn_ember(always(0.5), 100, 40, snow)
    actions.step_ember(flake, flake.life * 0.15)
    local glyph = actions.ember_look(flake, snow)
    assert.equal("❄", glyph)
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
