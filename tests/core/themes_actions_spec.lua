local actions = require("core.themes.actions")

local SLOTS = {
  "base", "mantle", "crust", "surface0", "surface1", "surface2",
  "overlay0", "overlay1", "overlay2", "subtext0", "subtext1", "text",
  "yellow", "peach", "green", "teal", "lavender", "mauve", "red", "maroon",
  "rosewater", "flamingo", "blue", "sapphire", "sky", "pink",
}

local malenia = actions.find("haligtree").palette

local function brightness(hex)
  local r, g, b = hex:match("#(%x%x)(%x%x)(%x%x)")
  return tonumber(r, 16) + tonumber(g, 16) + tonumber(b, 16)
end

describe("regions", function()
  it("lists all six in picker order", function()
    assert.same({ "leyndell", "haligtree", "raya_lucaria", "caelid", "mohgwyn", "ordina" }, actions.names())
  end)

  it("fills every catppuccin slot with a hex color in every region", function()
    for _, region in ipairs(actions.REGIONS) do
      for _, slot in ipairs(SLOTS) do
        assert.is_truthy((region.palette[slot] or ""):match("^#%x%x%x%x%x%x$"), region.name .. "." .. slot)
      end
    end
  end)

  it("keeps errors and the accent apart in every region", function()
    for _, region in ipairs(actions.REGIONS) do
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

  it("wraps from Ordina back to Leyndell", function()
    assert.equal("leyndell", actions.next_name("ordina"))
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
