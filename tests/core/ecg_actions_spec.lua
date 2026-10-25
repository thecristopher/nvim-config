local actions = require("core.ecg.actions")

describe("condition", function()
  it("reads Fine when Claire's buffer is clean", function()
    assert.equal("fine", actions.condition(0, 0))
  end)

  it("reads Caution with a single error", function()
    assert.equal("caution", actions.condition(1, 0))
  end)

  it("reads Caution when warnings pile up with no errors", function()
    assert.equal("caution", actions.condition(0, 5))
  end)

  it("reads Danger once three errors chase Leon", function()
    assert.equal("danger", actions.condition(3, 0))
  end)
end)

describe("trace", function()
  it("is always as wide as the monitor", function()
    assert.equal(actions.WIDTH, vim.fn.strchars(actions.trace("danger", 12345)))
  end)

  it("holds still between steps", function()
    assert.equal(
      actions.trace("fine", 0),
      actions.trace("fine", actions.CONDITIONS.fine.step_ms - 1)
    )
  end)

  it("scrolls once a step has passed", function()
    assert.are_not.equal(
      actions.trace("fine", 0),
      actions.trace("fine", actions.CONDITIONS.fine.step_ms)
    )
  end)

  it("beats faster in danger than when fine", function()
    local function beats(condition)
      local _, count = actions.trace(condition, 0, 36):gsub("▇", "")
      return count
    end
    assert.is_true(beats("danger") > beats("fine"))
  end)
end)
