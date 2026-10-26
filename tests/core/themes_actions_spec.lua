local actions = require("core.themes.actions")

local SLOTS = {
  "base",
  "mantle",
  "crust",
  "surface0",
  "surface1",
  "surface2",
  "overlay0",
  "overlay1",
  "overlay2",
  "subtext0",
  "subtext1",
  "text",
  "yellow",
  "peach",
  "green",
  "teal",
  "lavender",
  "mauve",
  "red",
  "maroon",
  "rosewater",
  "flamingo",
  "blue",
  "sapphire",
  "sky",
  "pink",
}

local malenia = actions.find("haligtree").palette

local function brightness(hex)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  return tonumber(r, 16) + tonumber(g, 16) + tonumber(b, 16)
end

describe("regions", function()
  it("lists all eleven in picker order", function()
    assert.same({
      "leyndell",
      "haligtree",
      "raya_lucaria",
      "caelid",
      "mohgwyn",
      "ordina",
      "limgrave",
      "stormveil",
      "volcano_manor",
      "nokron",
      "farum_azula",
    }, actions.names())
  end)

  it("fills every catppuccin slot with a hex color in every region", function()
    for _, region in ipairs(actions.regions()) do
      for _, slot in ipairs(SLOTS) do
        assert.is_truthy(
          (region.palette[slot] or ""):match("^#%x%x%x%x%x%x$"),
          region.name .. "." .. slot
        )
      end
    end
  end)

  it("keeps errors and the accent apart in every region", function()
    for _, region in ipairs(actions.regions()) do
      assert.are_not.equal(region.palette.yellow, region.palette.red, region.name)
    end
  end)
end)

describe("resolve", function()
  it("finds Rennala's academy by name", function()
    assert.equal("Raya Lucaria", actions.resolve("raya_lucaria").title)
  end)

  it("falls back to Leyndell for an unknown region", function()
    assert.equal("leyndell", actions.resolve("stormveil_but_misspelled").name)
  end)

  it("falls back to Leyndell when nothing was saved", function()
    assert.equal("leyndell", actions.resolve(nil).name)
  end)
end)

describe("next_name", function()
  it("moves from Leyndell to the Haligtree", function()
    assert.equal("haligtree", actions.next_name("leyndell"))
  end)

  it("moves from Ordina down to Limgrave", function()
    assert.equal("limgrave", actions.next_name("ordina"))
  end)

  it("wraps from Farum Azula back to Leyndell", function()
    assert.equal("leyndell", actions.next_name("farum_azula"))
  end)
end)

describe("blend", function()
  it("returns the background at zero", function()
    assert.equal("#0D0B09", actions.blend("#C9A84C", "#0D0B09", 0))
  end)

  it("returns the foreground at one", function()
    assert.equal("#C9A84C", actions.blend("#C9A84C", "#0D0B09", 1))
  end)

  it("meets in the middle at one half", function()
    assert.equal("#808080", actions.blend("#FFFFFF", "#000000", 0.5))
  end)
end)

describe("derive", function()
  it("tints the insert cursorline more than the normal one", function()
    local tints = actions.derive(malenia)
    assert.is_true(brightness(tints.cursorline_insert) > brightness(tints.cursorline))
  end)

  it("tints Leyndell's cursorline a faint gold", function()
    assert.equal("#18140D", actions.derive(actions.find("leyndell").palette).cursorline)
  end)

  it("lifts the side panel floor above Malenia's base", function()
    assert.is_true(brightness(actions.derive(malenia).panel) > brightness(malenia.base))
  end)

  it("keeps the panel darker than surface0 so it stays a background", function()
    assert.is_true(brightness(actions.derive(malenia).panel) < brightness(malenia.surface0))
  end)

  it("tints the separator with the region accent", function()
    assert.equal("#514421", actions.derive(actions.find("leyndell").palette).separator)
  end)

  it("warms Mohg's panel with blood instead of plain gray", function()
    local panel = actions.derive(actions.find("mohgwyn").palette).panel
    local r, g = panel:match("^#(%x%x)(%x%x)")
    assert.is_true(tonumber(r, 16) > tonumber(g, 16) * 2)
  end)

  for _, region in ipairs(actions.regions()) do
    it(
      ("draws a separator in %s that reads as clearly as everywhere else"):format(region.title),
      function()
        local separator = actions.derive(region.palette).separator
        assert.is_true(actions.contrast(separator, region.palette.base) >= 2.0)
      end
    )

    it(("lifts %s's panels enough to see but not enough to glare"):format(region.title), function()
      local ratio = actions.contrast(actions.derive(region.palette).panel, region.palette.base)
      assert.is_true(ratio >= 1.07 and ratio < 1.15)
    end)
  end
end)

describe("contrast", function()
  it("is 21 for black on white", function()
    assert.equal(21, actions.contrast("#000000", "#FFFFFF"))
  end)

  it("is 1 for the same color", function()
    assert.equal(1, actions.contrast("#C9A84C", "#C9A84C"))
  end)
end)

describe("tint_to_contrast", function()
  it("mixes just enough of the accent to hit the target", function()
    local mixed = actions.tint_to_contrast("#C9A84C", "#0D0B09", 2.0)
    assert.is_true(actions.contrast(mixed, "#0D0B09") >= 2.0)
  end)

  it("stops before reaching the full accent when it does not need it", function()
    assert.are_not.equal("#C9A84C", actions.tint_to_contrast("#C9A84C", "#0D0B09", 2.0))
  end)

  it("gives back the accent itself when no mix is bright enough", function()
    assert.equal("#111111", actions.tint_to_contrast("#111111", "#101010", 5))
  end)
end)

describe("ui builders", function()
  it("paints lualine normal mode with the region accent", function()
    assert.equal(malenia.yellow, actions.lualine_theme(malenia).normal.a.bg)
  end)

  it("paints lualine insert mode in grace green", function()
    assert.equal(malenia.green, actions.lualine_theme(malenia).insert.a.bg)
  end)

  it("marks the selected bufferline tab with the accent", function()
    assert.equal(malenia.yellow, actions.bufferline_highlights(malenia).indicator_selected.fg)
  end)

  it("leads the indent rainbow with the accent", function()
    assert.equal(malenia.yellow, actions.rainbow(malenia)[1])
  end)

  it("gives indent guides one color per rainbow level", function()
    assert.equal(#actions.rainbow(malenia), #actions.indent_guides(malenia))
  end)

  for _, region in ipairs(actions.regions()) do
    it(
      ("keeps %s's scope louder than the outermost guide it shares a color with"):format(
        region.title
      ),
      function()
        local p = region.palette
        local guide = actions.indent_guides(p)[1]
        assert.is_true(actions.contrast(p.yellow, p.base) > actions.contrast(guide, p.base))
      end
    )
  end
end)

describe("mode_look", function()
  local tints = actions.derive(malenia)

  it("warms the cursor line in insert mode", function()
    assert.equal(tints.cursorline_insert, actions.mode_look(malenia, tints, "i").cursorline)
  end)

  it("paints the line number lavender in visual block mode", function()
    assert.equal(malenia.lavender, actions.mode_look(malenia, tints, "\22").number)
  end)

  it("falls back to the region accent in normal mode", function()
    assert.equal(malenia.yellow, actions.mode_look(malenia, tints, "n").number)
  end)
end)

describe("characters", function()
  it("gives every region a champion and names its portrait file", function()
    for _, region in ipairs(actions.regions()) do
      assert.is_truthy(region.character, region.name)
      assert.is_truthy(region.portrait:match("%.jpg$"), region.portrait)
    end
  end)

  it("keeps every region's portrait on disk", function()
    local root = vim.fn.getcwd() .. "/images/portraits/"
    for _, region in ipairs(actions.regions()) do
      assert.equal(1, vim.fn.filereadable(root .. region.portrait), region.portrait)
    end
  end)

  it("never lets two regions share an accent", function()
    local seen = {}
    for _, region in ipairs(actions.regions()) do
      assert.is_nil(seen[region.palette.yellow], region.name)
      seen[region.palette.yellow] = true
    end
  end)

  it("crowns Malenia in the Haligtree", function()
    assert.equal("Malenia", actions.find("haligtree").character)
  end)
end)

describe("cursor_group", function()
  it("gives Claire's insert mode the grace green cursor", function()
    assert.equal("EldenCursorInsert", actions.cursor_group("i"))
  end)

  it("paints every visual flavor with the same cursor, blockwise included", function()
    assert.equal("EldenCursorVisual", actions.cursor_group("v"))
    assert.equal("EldenCursorVisual", actions.cursor_group("V"))
    assert.equal("EldenCursorVisual", actions.cursor_group("\22"))
  end)

  it("keeps the plain Cursor for normal and operator pending modes", function()
    assert.equal("Cursor", actions.cursor_group("n"))
    assert.equal("Cursor", actions.cursor_group("no"))
  end)

  it("falls back to the plain Cursor before any mode is known", function()
    assert.equal("Cursor", actions.cursor_group(nil))
  end)
end)

describe("guicursor", function()
  it("hands every mode group to the terminal cursor", function()
    local value = actions.guicursor()
    for _, group in pairs(actions.CURSOR_GROUPS) do
      assert.is_truthy(value:find(group, 1, true), group)
    end
  end)

  it("keeps the insert cursor a thin bar so Malenia's love letters stay readable", function()
    assert.is_truthy(actions.guicursor():find("i-ci-ve:ver25-EldenCursorInsert", 1, true))
  end)
end)

describe("of_the_day", function()
  local names = { "limgrave", "caelid", "haligtree", "leyndell" }

  it("keeps Malenia in the same region all day", function()
    assert.equal(
      actions.of_the_day("2026-10-26", "elden_ring", names),
      actions.of_the_day("2026-10-26", "elden_ring", names)
    )
  end)

  it("always lands on a real region", function()
    assert.is_true(vim.tbl_contains(names, actions.of_the_day("2026-02-14", "elden_ring", names)))
  end)

  it("moves through more than one region over Claire and Inde's week", function()
    local seen = {}
    for day = 20, 26 do
      seen[actions.of_the_day("2026-10-" .. day, "resident_evil", names)] = true
    end
    assert.is_true(vim.tbl_count(seen) > 1)
  end)
end)

describe("choice_for", function()
  it("keeps the region Malenia picked this morning", function()
    assert.equal("haligtree", actions.choice_for("2026-10-26 haligtree", "2026-10-26"))
  end)

  it("lets yesterday's pick go at midnight", function()
    assert.is_nil(actions.choice_for("2026-10-25 haligtree", "2026-10-26"))
  end)

  it("ignores a region Wesker made up", function()
    assert.is_nil(actions.choice_for("2026-10-26 umbrella_hq", "2026-10-26"))
  end)

  it("ignores the old file that held only a name", function()
    assert.is_nil(actions.choice_for("caelid", "2026-10-26"))
  end)
end)

describe("encode_choice", function()
  it("writes Inde's pick with its day", function()
    assert.equal("2026-10-26 caelid", actions.encode_choice("2026-10-26", "caelid"))
  end)
end)
