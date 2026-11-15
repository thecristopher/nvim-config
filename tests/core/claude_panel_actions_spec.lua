local actions = require("core.claude_panel.actions")

describe("default_width", function()
  it("gives Claire's panel its default share of the editor", function()
    assert.equals(76, actions.default_width(200))
  end)

  it("keeps at least one column for Inde on a tiny editor", function()
    assert.equals(1, actions.default_width(1))
  end)
end)

describe("on_focus", function()
  it("lets Claire's commit float open over the fullscreen", function()
    assert.equals("keep", actions.on_focus("float"))
  end)

  it("sends focus back when it lands on Malenia's collapsed window", function()
    assert.equals("back", actions.on_focus("collapsed"))
  end)

  it("ends fullscreen when Inde opens a new split", function()
    assert.equals("release", actions.on_focus("new"))
  end)

  it("keeps it when focus is already on the panel", function()
    assert.equals("keep", actions.on_focus("panel"))
  end)
end)
