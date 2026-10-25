local actions = require("core.franchise.actions")
local themes = require("core.themes.actions")

local SLOTS = {
  "base", "mantle", "crust", "surface0", "surface1", "surface2",
  "overlay0", "overlay1", "overlay2", "subtext0", "subtext1", "text",
  "yellow", "peach", "green", "teal", "lavender", "mauve", "red", "maroon",
  "rosewater", "flamingo", "blue", "sapphire", "sky", "pink",
}

local BANNERS = { "felled", "great", "died", "grace", "cleansed" }

local WORDS = {
  "traveler", "hub", "sites", "site", "sites_found", "no_sites", "rise", "choose_region",
  "region_prompt", "phantom", "past_self", "salute", "motion_on", "motion_off",
}

-- Claire and Inde's first date, and the day after
local first_date = { year = 2026, month = 2, day = 14 }
local day_after = { year = 2026, month = 2, day = 15 }

describe("resolve", function()
  it("keeps a franchise that exists", function()
    assert.equal("resident_evil", actions.resolve("resident_evil"))
  end)

  it("falls back to Elden Ring for one it does not know", function()
    assert.equal("elden_ring", actions.resolve("silent_hill"))
  end)

  it("falls back to Elden Ring when nothing was asked for", function()
    assert.equal("elden_ring", actions.resolve(nil))
  end)
end)

describe("of_the_day", function()
  it("gives the same franchise all day long", function()
    assert.equal(actions.of_the_day(first_date), actions.of_the_day({ year = 2026, month = 2, day = 14 }))
  end)

  it("moves to the next franchise the day after the date", function()
    assert.are_not.equal(actions.of_the_day(first_date), actions.of_the_day(day_after))
  end)

  it("rolls over the new year without skipping a day", function()
    local new_years_eve = actions.day_number({ year = 2026, month = 12, day = 31 })
    assert.equal(new_years_eve + 1, actions.day_number({ year = 2027, month = 1, day = 1 }))
  end)
end)

describe("choice_for", function()
  it("keeps what Malenia chose for today", function()
    assert.equal("resident_evil", actions.choice_for(actions.encode_choice("2026-10-23", "resident_evil"), "2026-10-23"))
  end)

  it("forgets yesterday's choice", function()
    assert.is_nil(actions.choice_for("2026-10-22 resident_evil", "2026-10-23"))
  end)

  it("ignores a franchise it does not know", function()
    assert.is_nil(actions.choice_for("2026-10-23 silent_hill", "2026-10-23"))
  end)

  it("ignores an empty state file", function()
    assert.is_nil(actions.choice_for(nil, "2026-10-23"))
  end)
end)

for _, name in ipairs(actions.NAMES) do
  local lore = actions.lore(name)

  describe(lore.title, function()
    it("names itself after its file", function()
      assert.equal(name, lore.name)
    end)

    it("picks a version of every mechanic", function()
      for _, mechanic in ipairs({ "travel", "boss", "status", "rest" }) do
        assert.is_truthy(lore.mechanics[mechanic], mechanic)
      end
      assert.is_boolean(lore.mechanics.ranking)
    end)

    it("names its currency and what you drop when you die", function()
      assert.is_truthy(lore.currency.glyph)
      assert.is_truthy(lore.currency.stain)
    end)

    it("writes every banner", function()
      for _, kind in ipairs(BANNERS) do
        assert.is_truthy(lore.banners[kind], kind)
      end
    end)

    it("says every word the config needs", function()
      for _, word in ipairs(WORDS) do
        assert.is_truthy(lore.words[word], word)
      end
    end)

    it("leaves a blank in every message template", function()
      for _, template in ipairs(lore.message_templates) do
        assert.is_truthy(template:find("%s", 1, true), template)
      end
    end)

    it("brings hub messages, places and item categories", function()
      assert.is_true(#lore.hub_messages > 0)
      assert.is_true(#lore.places > 0)
      assert.is_true(#lore.item_categories > 0)
    end)

    it("never lets two regions share an accent", function()
      local seen = {}
      for _, region in ipairs(lore.regions) do
        assert.is_nil(seen[region.palette.yellow], region.name)
        seen[region.palette.yellow] = true
      end
    end)

    for _, region in ipairs(lore.regions) do
      local p = region.palette

      it(("keeps %s's portrait on disk"):format(region.title), function()
        assert.equal(1, vim.fn.filereadable(vim.fn.getcwd() .. "/images/portraits/" .. region.portrait), region.portrait)
      end)

      it(("gives %s a champion, a portrait, a boss and a sky"):format(region.title), function()
        assert.is_truthy(region.character)
        assert.is_truthy(region.portrait:match("%.jpg$"))
        assert.is_truthy(lore.bosses[region.name])
        assert.is_truthy(lore.weather[region.name])
      end)

      it(("fills every catppuccin slot in %s"):format(region.title), function()
        for _, slot in ipairs(SLOTS) do
          assert.is_truthy((p[slot] or ""):match("^#%x%x%x%x%x%x$"), slot)
        end
      end)

      it(("keeps errors and the accent apart in %s"):format(region.title), function()
        assert.are_not.equal(p.yellow, p.red)
      end)

      it(("draws a separator in %s that reads clearly"):format(region.title), function()
        assert.is_true(themes.contrast(themes.derive(p).separator, p.base) >= 2.0)
      end)

      it(("lifts %s's panels enough to see but not enough to glare"):format(region.title), function()
        local ratio = themes.contrast(themes.derive(p).panel, p.base)
        assert.is_true(ratio >= 1.07 and ratio < 1.15)
      end)
    end
  end)
end

describe("resident evil", function()
  before_each(function() vim.g.eldentree_franchise = "resident_evil" end)
  after_each(function() vim.g.eldentree_franchise = "elden_ring" end)

  it("sends Claire into Raccoon City first", function()
    assert.equal("Claire Redfield", themes.resolve(nil).character)
  end)

  it("lets Nemesis stalk Raccoon City", function()
    assert.equal("Nemesis T-Type", require("core.boss.actions").boss_for("raccoon_city"))
  end)

  it("falls back to Nemesis where an Elden Ring boss used to stand", function()
    assert.equal("Nemesis T-Type", require("core.boss.actions").boss_for("haligtree"))
  end)

  it("announces death the way the mansion does", function()
    assert.equal("YOU ARE DEAD", require("core.banner.actions").kind("died").text)
  end)

  it("files Inde's tests under Umbrella's testing facility", function()
    assert.equal("Umbrella Testing Facility", require("core.zones.actions").zone_name("tests/core"))
  end)

  it("calls a function a weapon in the attaché case", function()
    assert.equal("Weapon", require("core.dive.actions").item_category({ "function.call" }))
  end)

  it("names Leon in the files he left behind", function()
    local phantom = require("core.phantom.actions").describe(
      { author = "Leon Kennedy", sha = "4f9c2a1", time = 0, summary = "love note for Ada" }, "other", 60)
    assert.equal(" ◈ Files left by Leon Kennedy ", phantom.title)
  end)

  it("lets Jill rest in a safe room", function()
    local layout = require("core.rest.actions").layout(80, 24, "Spencer Mansion")
    assert.equal("S A F E   R O O M", layout[2].text)
  end)
end)
