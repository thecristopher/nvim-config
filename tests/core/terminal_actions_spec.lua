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

describe("pixels_for", function()
  it("draws Inde's PNG valentine without ImageMagick", function()
    assert.is_true(actions.pixels_for("inde_valentine.png", false))
  end)

  it("leaves Claire's JPEG portrait to chafa without ImageMagick", function()
    assert.is_false(actions.pixels_for("claire.jpg", false))
  end)

  it("draws Malenia's JPEG once ImageMagick can convert it", function()
    assert.is_true(actions.pixels_for("malenia.jpg", true))
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
    assert.equal(
      "\27]1337;SetProfile=Eldentree Resident Evil\7",
      actions.iterm_profile("Eldentree Resident Evil")
    )
  end)
end)

describe("ghostty_config", function()
  it("writes Malenia's font and opacity sorted by key", function()
    assert.same({
      "# written by Eldentree from the franchise skin, edits here are overwritten",
      "background-opacity = 0.94",
      "font-style = Light",
    }, actions.ghostty_config({ ["font-style"] = "Light", ["background-opacity"] = 0.94 }))
  end)

  it("turns Claire's blur off with a plain false", function()
    assert.equal(
      "background-blur = false",
      actions.ghostty_config({ ["background-blur"] = false })[2]
    )
  end)

  it("leaves only the header when there is nothing to wear", function()
    assert.equal(1, #actions.ghostty_config(nil))
  end)
end)

describe("parse_opacity", function()
  it("takes Inde's 0.9 as it is", function()
    assert.equal(0.9, actions.parse_opacity("0.9"))
  end)

  it("reads Malenia's 85 as a percentage", function()
    assert.equal(0.85, actions.parse_opacity("85"))
  end)

  it("reads Claire's 94% with the sign", function()
    assert.equal(0.94, actions.parse_opacity("94%"))
  end)

  it("refuses an opacity so low Leon could not read his love notes", function()
    assert.is_nil(actions.parse_opacity("5%"))
  end)

  it("refuses anything that is not a number", function()
    assert.is_nil(actions.parse_opacity("wesker"))
  end)
end)

describe("opacity_label", function()
  it("shows Claire and Inde's anniversary glass at 97%", function()
    assert.equal("97%", actions.opacity_label(0.97))
  end)
end)

describe("with_opacity", function()
  it("lays Inde's choice over Malenia's skin", function()
    local skin = { ["font-style"] = "Light", ["background-opacity"] = 0.94 }
    assert.same(
      { ["font-style"] = "Light", ["background-opacity"] = 0.8 },
      actions.with_opacity(skin, 0.8)
    )
  end)

  it("leaves the skin's own table untouched", function()
    local skin = { ["background-opacity"] = 0.94 }
    actions.with_opacity(skin, 0.8)
    assert.equal(0.94, skin["background-opacity"])
  end)

  it("keeps the skin as it is when nothing was chosen", function()
    local skin = { ["background-opacity"] = 1 }
    assert.equal(skin, actions.with_opacity(skin, nil))
  end)

  it("still sets the opacity when Claire's skin has no Ghostty keys", function()
    assert.same({ ["background-opacity"] = 0.9 }, actions.with_opacity(nil, 0.9))
  end)
end)

describe("body_groups", function()
  local base, mantle = 0x0E0908, 0x1A1412

  it("clears the body Claire writes Inde's love notes on", function()
    local groups = actions.body_groups({
      Normal = { fg = 0xFFFFFF, bg = base },
      SignColumn = { bg = base },
    })
    assert.same({ "Normal", "SignColumn" }, groups)
  end)

  it("keeps Malenia's floats solid on their own shade", function()
    local groups = actions.body_groups({
      Normal = { bg = base },
      NormalFloat = { bg = mantle },
    })
    assert.same({ "Normal" }, groups)
  end)

  it("clears the dimmed inactive windows too", function()
    local groups = actions.body_groups({ Normal = { bg = base }, NormalNC = { bg = mantle } })
    assert.same({ "Normal", "NormalNC" }, groups)
  end)

  it("leaves links and groups without a background alone", function()
    local groups = actions.body_groups({
      Normal = { bg = base },
      EndOfBuffer = { link = "Normal" },
      Comment = { fg = 0x888888 },
    })
    assert.same({ "Normal" }, groups)
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
