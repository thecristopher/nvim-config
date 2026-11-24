local actions = require("core.signpost.actions")

describe("alpha", function()
  it("hides the sign before the screen is covered", function()
    assert.equal(0, actions.alpha(0.1, 0.2, 0.6))
  end)

  it("shows it fully once it has faded in", function()
    assert.equal(1, actions.alpha(0.4, 0.2, 0.6))
  end)

  it("has it gone by the end of its window", function()
    assert.near(0, actions.alpha(0.6, 0.2, 0.6), 0.0001)
  end)
end)

describe("text", function()
  it("spaces the letters of a name that fits, the way Malenia's grace reads", function()
    assert.equal("H A L I G T R E E", actions.text("haligtree", 120))
  end)

  it("writes a long branch plain when spacing would not fit", function()
    local name = "feature/claire-and-inde-anniversary-playlist"
    assert.equal(name:upper(), actions.text(name, 80))
  end)

  it("cuts a name wider than the screen with an ellipsis", function()
    local text = actions.text("claire-redfield-love-letters-for-inde", 30)
    assert.is_true(vim.fn.strdisplaywidth(text) <= 30 - 2 * actions.PAD - 4)
    assert.equal("…", vim.fn.strcharpart(text, vim.fn.strchars(text) - 1))
  end)
end)

describe("layout", function()
  it("centers the name on the middle row", function()
    local spot = actions.layout(100, 40, 20)
    assert.equal(20, spot.row)
    assert.equal(40, spot.col)
  end)

  it("puts the rules one row above and below inside the plate", function()
    local spot = actions.layout(100, 40, 20)
    assert.equal(spot.row - 2, spot.top)
    assert.equal(spot.row + 2, spot.bottom)
    assert.equal(24, spot.rule_width)
  end)

  it("never lets the plate run past a narrow screen", function()
    local spot = actions.layout(30, 10, 20)
    assert.equal(30, spot.plate_width)
    assert.equal(0, spot.plate_col)
  end)
end)

describe("plate_runs", function()
  local function levels(width)
    local all = {}
    for _, run in ipairs(actions.plate_runs(width)) do
      for _ = 1, run[1] do
        table.insert(all, run[2])
      end
    end
    return all
  end

  it("covers every column of the plate", function()
    assert.equal(60, #levels(60))
  end)

  it("is solid in the middle where Claire's name sits", function()
    assert.equal(actions.LEVELS, levels(60)[30])
  end)

  it("fades softly toward both edges", function()
    local all = levels(60)
    assert.is_true(all[1] < actions.LEVELS)
    assert.equal(all[1], all[60])
  end)
end)

describe("rule", function()
  it("carries the ornament in the middle of the upper rule", function()
    assert.equal("── ◆ ──", actions.rule(7, true))
  end)

  it("keeps the lower rule plain and the same width", function()
    assert.equal(
      vim.fn.strdisplaywidth(actions.rule(7, true)),
      vim.fn.strdisplaywidth(actions.rule(7, false))
    )
  end)
end)

describe("travels", function()
  local travels = {
    fog = require("core.fog.actions"),
    door = require("core.door.actions"),
    curtain = require("core.curtain.actions"),
  }

  for name, travel in pairs(travels) do
    it(name .. " lasts as long as every other travel", function()
      assert.equal(actions.DURATION, travel.DURATION)
    end)

    it(name .. " shows the sign only after the screen is covered", function()
      assert.is_true(travel.SIGN.from >= travel.COVERED)
      assert.is_true(travel.SIGN.to - travel.SIGN.from > 2 * actions.FADE)
    end)
  end
end)
