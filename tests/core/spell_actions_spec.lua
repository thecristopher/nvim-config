local actions = require("core.spell.actions")

describe("needs_build", function()
  it("builds when Claire's word list was never compiled", function()
    assert.is_true(actions.needs_build(100, nil))
  end)

  it("builds again after Inde added a word", function()
    assert.is_true(actions.needs_build(200, 100))
  end)

  it("leaves a fresh build alone", function()
    assert.is_false(actions.needs_build(100, 150))
  end)

  it("does nothing without a word list", function()
    assert.is_false(actions.needs_build(nil, nil))
  end)
end)
