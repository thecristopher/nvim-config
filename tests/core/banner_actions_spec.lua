local actions = require("core.banner.actions")

local felled = actions.kind("felled")

describe("spaced", function()
  it("letterspaces the way the game does", function()
    assert.equal("E N E M Y   F E L L E D", actions.spaced("Enemy Felled"))
  end)

  it("handles a single word region", function()
    assert.equal("C A E L I D", actions.spaced("caelid"))
  end)
end)

describe("kind", function()
  it("lets a region banner bring its own title", function()
    assert.equal("Haligtree", actions.kind("region", { text = "Haligtree" }).text)
  end)

  it("returns nothing for a kind that does not exist", function()
    assert.is_nil(actions.kind("you_won_against_malenia_first_try"))
  end)
end)

describe("envelope", function()
  it("is invisible the moment it appears", function()
    assert.equal(0, actions.envelope(0, felled))
  end)

  it("is fully visible in the middle", function()
    assert.equal(1, actions.envelope(felled.duration / 2, felled))
  end)

  it("is gone once the duration ends", function()
    assert.near(0, actions.envelope(felled.duration, felled), 0.001)
  end)
end)

describe("letter_alpha", function()
  it("wakes the first letter before the last", function()
    local early = 100
    assert.is_true(actions.letter_alpha(1, early, felled) > actions.letter_alpha(10, early, felled))
  end)

  it("lets YOU DIED rise as one word", function()
    local died = actions.kind("died")
    assert.equal(actions.letter_alpha(1, 500, died), actions.letter_alpha(6, 500, died))
  end)
end)

describe("band_alpha", function()
  it("is strongest in the center", function()
    assert.is_true(actions.band_alpha(3, 50, 100, 7) > actions.band_alpha(0, 50, 100, 7))
  end)

  it("vanishes at the screen edge", function()
    assert.equal(0, actions.band_alpha(3, 0, 100, 7))
  end)
end)

describe("blend_for", function()
  it("makes a solid cell from full alpha", function()
    assert.equal(0, actions.blend_for(1))
  end)

  it("makes an invisible cell from zero alpha", function()
    assert.equal(100, actions.blend_for(0))
  end)
end)

describe("rule_alpha", function()
  it("glows in the middle and fades at the tips", function()
    assert.equal(1, actions.rule_alpha(6, 11))
    assert.equal(0, actions.rule_alpha(1, 11))
  end)
end)

describe("should_cleanse", function()
  local long_fight = { errors = 0, errors_since = 0, now = 60 * 1000 }

  it("celebrates errors that finally clear after a long fight", function()
    assert.is_true(actions.should_cleanse(long_fight))
  end)

  it("ignores errors that flickered for a moment", function()
    assert.is_false(
      actions.should_cleanse({ errors = 0, errors_since = 59 * 1000, now = 60 * 1000 })
    )
  end)

  it("stays quiet while errors remain", function()
    assert.is_false(actions.should_cleanse({ errors = 2, errors_since = 0, now = 60 * 1000 }))
  end)

  it("waits out the cooldown after the last banner", function()
    assert.is_false(
      actions.should_cleanse(vim.tbl_extend("force", long_fight, { last_shown = 50 * 1000 }))
    )
  end)
end)

describe("drips", function()
  it("bleeds every other letter", function()
    assert.equal(3, #actions.drips({ 10, 12, 14, 16, 18 }))
  end)

  it("never runs deeper than the band", function()
    for _, drip in ipairs(actions.drips({ 1, 2, 3, 4, 5, 6, 7, 8, 9 })) do
      assert.is_true(drip.length >= 1 and drip.length <= actions.DRIP_DEPTH)
    end
  end)

  it("lays the same drips every time", function()
    assert.same(actions.drips({ 4, 6, 8 }), actions.drips({ 4, 6, 8 }))
  end)
end)

describe("drip_alpha", function()
  local kind = { fade_in = 300, letter_ms = 500, duration = 4600, fade_out = 1100 }

  it("waits for the letters before the first drop", function()
    assert.equal(0, actions.drip_alpha(1, 300, kind))
  end)

  it("lets deeper drops arrive later", function()
    assert.is_true(actions.drip_alpha(1, 1200, kind) > actions.drip_alpha(3, 1200, kind))
  end)
end)

describe("kind styles", function()
  before_each(function()
    vim.g.eldentree_franchise = "resident_evil"
  end)
  after_each(function()
    vim.g.eldentree_franchise = "elden_ring"
  end)

  it("makes Leon's death drip in Raccoon City", function()
    assert.is_true(actions.kind("died").drip)
  end)

  it("keeps the other banners clean", function()
    assert.is_nil(actions.kind("felled").drip)
  end)
end)

describe("kind styles in the Lands Between", function()
  it("lets Malenia's death fade without dripping", function()
    assert.is_nil(actions.kind("died").drip)
  end)
end)

describe("rains", function()
  it("crumbles Claire's code when she dies in a file", function()
    assert.is_true(actions.rains("died", "", nil))
  end)

  it("keeps the code standing for a felled boss", function()
    assert.is_false(actions.rains("felled", "", nil))
  end)

  it("stays dry over terminals and pickers", function()
    assert.is_false(actions.rains("died", "terminal", nil))
    assert.is_false(actions.rains("died", "nofile", nil))
  end)

  it("stays dry when Malenia turned the rain off", function()
    assert.is_false(actions.rains("died", "", false))
  end)
end)
