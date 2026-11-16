local tint = require("core.music.actions.tint")
local themes = require("core.themes.actions")

local NIGHT = "#1E1E2E"

describe("command", function()
  it("asks ImageMagick for the few colors of Malenia's album cover", function()
    local cmd = tint.command("magick", "/covers/haligtree.jpg")
    assert.equal("magick", cmd[1])
    assert.equal("/covers/haligtree.jpg", cmd[2])
    assert.equal("histogram:info:-", cmd[#cmd])
  end)
end)

describe("parse_histogram", function()
  local output = table.concat({
    "       200: (165.66,145.394,126.643) #A6917F srgb(64.9%,57.0%,49.6%)",
    "      2833: (20.0203,14.6147,11.1009) #140F0B srgb(7.8%,5.7%,4.3%)",
    "       601: (200,40,60) #c8283c srgb(78%,15%,23%)",
  }, "\n")

  it("reads every color of Claire's cover, the most common first", function()
    assert.same({
      { count = 2833, hex = "#140F0B" },
      { count = 601, hex = "#C8283C" },
      { count = 200, hex = "#A6917F" },
    }, tint.parse_histogram(output))
  end)

  it("gives no colors when ImageMagick said nothing", function()
    assert.same({}, tint.parse_histogram(nil))
    assert.same({}, tint.parse_histogram("magick: no decode delegate"))
  end)
end)

describe("vivid", function()
  it("takes the scarlet of Malenia's rot", function()
    assert.is_true(tint.vivid("#C8283C"))
  end)

  it("passes over grays, near black and near white", function()
    assert.is_false(tint.vivid("#808080"))
    assert.is_false(tint.vivid("#140F0B"))
    assert.is_false(tint.vivid("#FFF0F5"))
  end)
end)

describe("accent", function()
  it("dresses Inde's playlist in the cover's vivid color, not its dark background", function()
    local colors = {
      { count = 2833, hex = "#140F0B" },
      { count = 601, hex = "#E0A030" },
    }
    assert.equal("#E0A030", tint.accent(colors, NIGHT))
  end)

  it("lifts a deep red until it reads on Claire's dark base", function()
    local accent = tint.accent({ { count = 10, hex = "#8B1A2B" } }, NIGHT)
    assert.is_true(themes.contrast(accent, NIGHT) >= tint.MIN_CONTRAST)
  end)

  it("prefers the vivid color covering more of the cover", function()
    local colors = {
      { count = 50, hex = "#E0A030" },
      { count = 900, hex = "#3FA0E0" },
    }
    assert.equal("#3FA0E0", tint.accent(colors, NIGHT))
  end)

  it("keeps the palette when Malenia's cover is all browns and grays", function()
    local colors = {
      { count = 2833, hex = "#140F0B" },
      { count = 200, hex = "#A6917F" },
    }
    assert.is_nil(tint.accent(colors, NIGHT))
  end)
end)

describe("groups", function()
  it("tints the panel's accents and the statusline's song alike", function()
    local groups = tint.groups("#E0A030")
    assert.equal("#E0A030", groups.EldenMusicTitle.fg)
    assert.equal("#E0A030", groups.EldenMusicLine.fg)
    assert.is_true(groups.EldenMusicBarHead.bold)
  end)

  it("puts the same groups back in the region's colors", function()
    local p = { yellow = "#D8B45A", peach = "#E0A070", mauve = "#B48EAD" }
    local groups = tint.palette_groups(p)
    assert.equal("#D8B45A", groups.EldenMusicTitle.fg)
    assert.equal("#E0A070", groups.EldenMusicBarHead.fg)
    assert.equal("#B48EAD", groups.EldenMusicLine.fg)
    local tinted, plain = vim.tbl_keys(tint.groups("#000000")), vim.tbl_keys(groups)
    table.sort(tinted)
    table.sort(plain)
    assert.same(tinted, plain)
  end)
end)
