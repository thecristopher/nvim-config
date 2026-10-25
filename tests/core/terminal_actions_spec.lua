local actions = require("core.terminal.actions")

describe("detect", function()
  it("recognizes iTerm, where Claire codes today", function()
    assert.equal("iterm", actions.detect({ TERM_PROGRAM = "iTerm.app" }))
  end)

  it("recognizes Ghostty by its resources folder", function()
    assert.equal("ghostty", actions.detect({ GHOSTTY_RESOURCES_DIR = "/Applications/Ghostty.app" }))
  end)

  it("recognizes Kitty by its window id", function()
    assert.equal("kitty", actions.detect({ KITTY_WINDOW_ID = "1" }))
  end)

  it("admits when it does not know the terminal", function()
    assert.equal("unknown", actions.detect({}))
  end)
end)

describe("images", function()
  it("draws real portraits in Ghostty", function()
    assert.is_true(actions.images("ghostty"))
  end)

  it("leaves iTerm to chafa", function()
    assert.is_false(actions.images("iterm"))
  end)
end)

describe("sequences", function()
  it("paints the terminal background with OSC 11", function()
    assert.equal("\27]11;#0E0908\7", actions.background("#0E0908"))
  end)

  it("gives the background back with OSC 111", function()
    assert.equal("\27]111\7", actions.reset_background())
  end)

  it("switches iTerm to Ada's profile", function()
    assert.equal("\27]1337;SetProfile=Eldentree Resident Evil\7", actions.iterm_profile("Eldentree Resident Evil"))
  end)
end)

describe("passthrough", function()
  it("leaves the sequence alone outside tmux", function()
    assert.equal("\27]111\7", actions.passthrough("\27]111\7", false))
  end)

  it("wraps it and doubles every escape inside tmux", function()
    assert.equal("\27Ptmux;\27\27]111\7\27\\", actions.passthrough("\27]111\7", true))
  end)
end)
