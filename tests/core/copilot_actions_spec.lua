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
