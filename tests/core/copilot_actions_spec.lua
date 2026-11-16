local actions = require("core.copilot.actions")

describe("needs_sign_in", function()
  it("asks Claire to sign in when the server knows no user", function()
    assert.is_true(actions.needs_sign_in(nil, { status = "NotSignedIn" }))
  end)

  it("stays quiet once Malenia is signed in", function()
    assert.is_false(actions.needs_sign_in(nil, { user = "malenia", status = "OK" }))
  end)

  it("never hints on an error or a missing answer, Inde would only see noise", function()
    assert.is_false(actions.needs_sign_in("timeout", nil))
    assert.is_false(actions.needs_sign_in(nil, nil))
  end)
end)

local function suggestion(text, last_line)
  return {
    text = text,
    displayText = text,
    range = { start = { line = 3 }, ["end"] = { line = last_line or 3 } },
  }
end

describe("one_line", function()
  it("lets Claire's love note finish its line but not the rest of the function", function()
    local kept = actions.one_line({ suggestion("local note = 'te amo'\nreturn note\nend") })
    assert.are.equal("local note = 'te amo'", kept[1].text)
    assert.are.equal("local note = 'te amo'", kept[1].displayText)
  end)

  it("keeps Malenia's one line suggestion as it came", function()
    assert.are.same(
      { suggestion("return petals") },
      actions.one_line({ suggestion("return petals") })
    )
  end)

  it("drops a suggestion that would rewrite lines below Inde's cursor", function()
    assert.are.same({}, actions.one_line({ suggestion("x", 5) }))
  end)

  it("drops a suggestion that only starts on the next line", function()
    assert.are.same({}, actions.one_line({ suggestion("\nfunction anniversary()") }))
  end)
end)

describe("one_line_edits", function()
  it("keeps Leon's edit to one line and drops Wesker's whole block", function()
    local leon = suggestion("local case = 'attache'")
    local wesker = suggestion("function uroboros()\nend", 4)
    assert.are.same({ leon }, actions.one_line_edits({ leon, wesker }))
  end)
end)
