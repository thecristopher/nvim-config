local actions = require("core.skin.actions")

describe("border_chars", function()
  it("gives telescope the double frame of the inventory", function()
    assert.same(
      { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
      actions.border_chars("double")
    )
  end)

  it("falls back to rounded for a border it does not know", function()
    assert.same(actions.BORDER_CHARS.rounded, actions.border_chars("shadow"))
  end)
end)

describe("toggleterm_border", function()
  it("calls rounded curved, the way toggleterm does", function()
    assert.equal("curved", actions.toggleterm_border("rounded"))
  end)

  it("passes double through untouched", function()
    assert.equal("double", actions.toggleterm_border("double"))
  end)
end)

describe("ornate", function()
  it("frames Malenia's title in gold ornaments", function()
    assert.equal("◈ Malenia ◈", actions.ornate("Malenia", { ornament = { "◈ ", " ◈" } }))
  end)

  it("leaves the title bare when the skin has no ornament", function()
    assert.equal("Claire", actions.ornate("Claire", {}))
  end)
end)

describe("sign_text", function()
  it("keys every sign by its severity", function()
    local severity = vim.diagnostic.severity
    local text =
      actions.sign_text({ error = "☣", warn = "▲", hint = "◆", info = "◇" }, severity)
    assert.equal("☣", text[severity.ERROR])
    assert.equal("◇", text[severity.INFO])
  end)
end)
