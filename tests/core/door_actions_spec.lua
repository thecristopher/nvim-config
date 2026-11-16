local actions = require("core.door.actions")

describe("darkness", function()
  it("starts with the editor in plain sight", function()
    assert.equal(0, actions.darkness(0))
  end)

  it("is pitch black while the door swings", function()
    assert.equal(1, actions.darkness((actions.SWING_FROM + actions.SWING_UNTIL) / 2))
  end)

  it("lifts completely once Jill is through", function()
    assert.near(0, actions.darkness(1), 0.0001)
  end)
end)

describe("swing", function()
  it("keeps the door shut before it starts to move", function()
    assert.equal(0, actions.swing(actions.SWING_FROM))
  end)

  it("opens it wide by the end of the swing", function()
    assert.equal(1, actions.swing(actions.SWING_UNTIL))
  end)
end)

describe("door_alpha", function()
  it("hides the door before the dark settles", function()
    assert.equal(0, actions.door_alpha(0))
  end)

  it("shows it fully while it swings", function()
    assert.equal(1, actions.door_alpha(actions.SWING_FROM))
  end)

  it("lets it go before the light comes back", function()
    assert.equal(0, actions.door_alpha(actions.LIGHT_FROM))
  end)
end)

describe("rows", function()
  it("draws the frame as tall and wide as the door", function()
    local rows = actions.rows(0)
    assert.equal(actions.HEIGHT, #rows)
    for _, row in ipairs(rows) do
      assert.equal(actions.WIDTH, vim.fn.strchars(row))
    end
  end)

  it("keeps a shut door solid with both handles on it", function()
    local middle = actions.rows(0)[math.floor(actions.HEIGHT / 2)]
    assert.is_falsy(middle:find(" ", 1, true))
    local _, handles = middle:gsub("●", "")
    assert.equal(2, handles)
  end)

  it("leaves only the dark between the hinges once it is open", function()
    assert.equal("│" .. (" "):rep(actions.WIDTH - 2) .. "│", actions.rows(1)[2])
  end)
end)

describe("size", function()
  it("stands most of the screen's height for Leon", function()
    local width, height = actions.size(190, 50)
    assert.is_true(height >= 30)
    assert.is_true(width <= 184)
  end)

  it("still fits a small screen with an even inside", function()
    local width, height = actions.size(90, 26)
    assert.is_true(width <= 84 and height <= 22)
    assert.equal(0, (width - 2) % 2)
  end)
end)

describe("rows at any size", function()
  it("keeps every row as wide as Claire's door", function()
    for _, open in ipairs({ 0, 0.3, 0.7, 1 }) do
      for _, row in ipairs(actions.rows(open, 60, 20)) do
        assert.equal(60, vim.fn.strchars(row))
      end
    end
  end)

  it("slides the planks with the panel instead of squeezing them", function()
    local shut = actions.rows(0, 42, 12)[2]
    local half = actions.rows(0.5, 42, 12)[2]
    -- the panel's free edge keeps the planks it had right by the gap
    assert.equal(vim.fn.strcharpart(shut, 20, 1), vim.fn.strcharpart(half, 10, 1))
  end)
end)
