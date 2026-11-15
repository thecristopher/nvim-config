local actions = require("core.claude_panel.actions")

describe("default_width", function()
  it("gives Claire's panel its default share of the editor", function()
    assert.equals(76, actions.default_width(200))
  end)

  it("keeps at least one column for Inde on a tiny editor", function()
    assert.equals(1, actions.default_width(1))
  end)
end)
