local actions = require("core.chrome.actions")

local chrome = {
  modes = { normal = "SURVIVE", insert = "TYPE", visual = "AIM", command = "RADIO" },
  notify = { info = "Radio", error = "Danger" },
  cmdline = "Typewriter",
  search = "Search",
}

describe("mode_label", function()
  it("calls Claire's normal mode SURVIVE", function()
    assert.equal("SURVIVE", actions.mode_label("n", chrome))
  end)

  it("folds visual line and block into AIM", function()
    assert.equal("AIM", actions.mode_label("V", chrome))
    assert.equal("AIM", actions.mode_label("\22", chrome))
  end)

  it("falls back to the plain name when the franchise has none", function()
    assert.equal("TERMINAL", actions.mode_label("t", chrome))
  end)
end)

describe("notify_title", function()
  it("keeps the title Malenia gave her message", function()
    assert.equal("Scarlet Rot", actions.notify_title("Scarlet Rot", "error", chrome))
  end)

  it("names an untitled error the franchise's way", function()
    assert.equal("Danger", actions.notify_title("", "error", chrome))
  end)

  it("reads numeric levels too", function()
    assert.equal("Radio", actions.notify_title(nil, vim.log.levels.INFO, chrome))
  end)
end)

describe("number_group", function()
  it("leaves the cursor line to CursorLineNr", function()
    assert.is_nil(actions.number_group(0))
  end)

  it("fades with the distance and stops at the last step", function()
    assert.equal("EldenNr1", actions.number_group(1))
    assert.equal("EldenNr5", actions.number_group(42))
  end)
end)

describe("paint_number", function()
  it("colors the number snacks put in the column", function()
    local column = "%@click@  %=12 %#GitSign#▎%T"
    assert.equal("%@click@  %=%#EldenNr2#12 %*%#GitSign#▎%T", actions.paint_number(column, 2))
  end)

  it("leaves the cursor line alone", function()
    assert.equal("%=7 ", actions.paint_number("%=7 ", 0))
  end)
end)

describe("frame_layout", function()
  local layout = {
    layout = {
      box = "horizontal",
      { box = "vertical", title = "{title} {live} {flags}" },
      { win = "preview", title = "{preview}" },
    },
  }

  it("frames Inde's picker title in the ornaments", function()
    local framed = actions.frame_layout(layout, { "▐ ", " ▌" }, "Examine")
    assert.equal("▐ {title} ▌ {live} {flags}", framed.layout[1].title)
    assert.equal("center", framed.layout[1].title_pos)
  end)

  it("names an empty preview the franchise's way", function()
    local framed = actions.frame_layout(layout, { "◈ ", " ◈" }, "Inspect")
    assert.equal("◈ {preview:Inspect} ◈", framed.layout[2].title)
  end)

  it("leaves the layout it was given untouched", function()
    actions.frame_layout(layout, { "▐ ", " ▌" }, "Examine")
    assert.equal("{preview}", layout.layout[2].title)
  end)
end)

describe("cmdline_formats", function()
  it("titles the command line and marks it with the skin's glyph", function()
    local formats = actions.cmdline_formats(
      chrome,
      { icon = "󰌌", search = "󰍉" },
      { "▐ ", " ▌" }
    )
    assert.equal(" ▐ Typewriter ▌ ", formats.cmdline.title)
    assert.equal("󰌌", formats.cmdline.icon)
    assert.equal(" ▐ Search ▌ ", formats.search_up.title)
  end)
end)
