local actions = require("core.skin.actions")

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
