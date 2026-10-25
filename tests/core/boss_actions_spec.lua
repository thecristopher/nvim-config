local actions = require("core.boss.actions")

describe("boss_for", function()
  it("sends Malenia to guard the Haligtree", function()
    assert.equal("Malenia, Blade of Miquella", actions.boss_for("haligtree"))
  end)

  it("gives every region its own boss", function()
    for _, region in ipairs(require("core.themes.actions").regions()) do
      assert.is_truthy(require("core.franchise").current().bosses[region.name], region.name)
    end
  end)

  it("falls back to Morgott for a region nobody guards", function()
    assert.equal("Morgott, the Omen King", actions.boss_for("raccoon_city"))
  end)
end)

describe("should_engage", function()
  it("waits while Claire's typos are still fresh", function()
    assert.is_false(
      actions.should_engage({ errors = 5, since = 0, now = actions.ENGAGE_AFTER_MS - 1 })
    )
  end)

  it("starts the fight once the errors linger", function()
    assert.is_true(actions.should_engage({ errors = 5, since = 0, now = actions.ENGAGE_AFTER_MS }))
  end)

  it("ignores a buffer with fewer errors than the threshold", function()
    assert.is_false(
      actions.should_engage({ errors = actions.THRESHOLD - 1, since = 0, now = 60000 })
    )
  end)

  it("never engages before the errors were first seen", function()
    assert.is_false(actions.should_engage({ errors = 9, since = nil, now = 60000 }))
  end)
end)

describe("health", function()
  it("is full at the worst moment of the fight", function()
    assert.equal(1, actions.health(6, 6))
  end)

  it("drops by the share of errors Inde already fixed", function()
    assert.equal(0.5, actions.health(3, 6))
  end)

  it("is zero without a peak to measure against", function()
    assert.equal(0, actions.health(3, 0))
  end)
end)

describe("width", function()
  it("takes a little over half of a normal editor", function()
    assert.equal(66, actions.width(120))
  end)

  it("caps the bar on wide monitors", function()
    assert.equal(actions.MAX_WIDTH, actions.width(400))
  end)

  it("keeps a usable bar in a narrow split", function()
    assert.equal(20, actions.width(30))
  end)
end)

describe("segments", function()
  it("fills the whole bar at full health", function()
    assert.same({ fill = 40, chip = 0, empty = 0 }, actions.segments(40, 1, 1))
  end)

  it("shows the gold chip between health and the old reach", function()
    assert.same({ fill = 20, chip = 10, empty = 10 }, actions.segments(40, 0.5, 0.75))
  end)

  it("never lets the chip fall below the health", function()
    assert.same({ fill = 20, chip = 0, empty = 20 }, actions.segments(40, 0.5, 0.2))
  end)

  it("always adds up to the bar width", function()
    local parts = actions.segments(33, 0.37, 0.81)
    assert.equal(33, parts.fill + parts.chip + parts.empty)
  end)
end)

describe("chip_at", function()
  it("holds at the old health right after Malenia lands a hit", function()
    assert.equal(1, actions.chip_at(1, 0.5, 0))
  end)

  it("drains all the way to the new health", function()
    assert.equal(0.5, actions.chip_at(1, 0.5, actions.CHIP_HOLD_MS + actions.CHIP_MS))
  end)

  it("sits between the two while draining", function()
    local chip = actions.chip_at(1, 0.5, actions.CHIP_HOLD_MS + actions.CHIP_MS / 2)
    assert.is_true(chip < 1 and chip > 0.5)
  end)

  it("jumps straight to the new health when the boss heals", function()
    assert.equal(0.8, actions.chip_at(0.5, 0.8, 0))
  end)
end)

describe("frame", function()
  local entered = { health = 1, entered_at = 0 }

  it("starts empty as the boss walks in", function()
    assert.equal(0, actions.frame(entered, 0).fill)
  end)

  it("is full once the entrance is over", function()
    assert.equal(1, actions.frame(entered, actions.ENTRANCE_MS).fill)
  end)

  it("shows the damage of a fresh hit", function()
    local fight = { health = 0.5, entered_at = 0, hit_at = 1000, chip_from = 1, damage = 3 }
    assert.equal(3, actions.frame(fight, 1100).damage)
  end)

  it("lets the damage number fade once the chip has settled", function()
    local fight = { health = 0.5, entered_at = 0, hit_at = 1000, chip_from = 1, damage = 3 }
    assert.is_nil(actions.frame(fight, 1000 + actions.hit_duration()).damage)
  end)

  it("keeps the chip at least as long as the health", function()
    local fight = { health = 0.5, entered_at = 0, hit_at = 1000, chip_from = 1, damage = 3 }
    local frame = actions.frame(fight, 1000 + actions.hit_duration())
    assert.is_true(frame.chip >= frame.fill)
  end)
end)

describe("header", function()
  it("puts the boss on the left and the damage on the right", function()
    assert.equal("Mohg      12", actions.header("Mohg", 12, 12))
  end)

  it("leaves the right side empty without damage", function()
    assert.equal("Mohg        ", actions.header("Mohg", nil, 12))
  end)

  it("keeps a space between a long name and the damage", function()
    assert.equal("Starscourge Radahn 4", actions.header("Starscourge Radahn", 4, 10))
  end)
end)

describe("placement", function()
  local screen = { lines = 50, cmdheight = 1, statusline = 1, top = 1 }

  it("sits just above the statusline", function()
    assert.equal(46, actions.placement(vim.tbl_extend("force", screen, { cursor_row = 10 })))
  end)

  it("moves to the top while Leon edits the last lines", function()
    assert.equal(1, actions.placement(vim.tbl_extend("force", screen, { cursor_row = 47 })))
  end)
end)

describe("closeness", function()
  it("starts the hunt far away even with every error still there", function()
    assert.is_true(actions.closeness(5, 5, 0) < 0.5)
  end)

  it("brings Mr. X all the way while Leon ignores the errors", function()
    assert.equal(1, actions.closeness(5, 5, actions.APPROACH_MS))
  end)

  it("pushes him back with every fix", function()
    assert.is_true(
      actions.closeness(2, 5, actions.APPROACH_MS) < actions.closeness(4, 5, actions.APPROACH_MS)
    )
  end)
end)

describe("footsteps", function()
  it("sounds distant when the stalker is far", function()
    assert.equal("distant footsteps", actions.footsteps(0.1))
  end)

  it("warns when it is right behind you", function()
    assert.equal("right behind you", actions.footsteps(1))
  end)
end)

describe("hall", function()
  it("leaves the whole hall between Claire and a stalker that just arrived", function()
    assert.same({ near = 38, far = 0 }, actions.hall(40, 0))
  end)

  it("closes the gap when it reaches her", function()
    assert.same({ near = 0, far = 38 }, actions.hall(40, 1))
  end)

  it("always fills the width with you and the stalker included", function()
    local hall = actions.hall(40, 0.37)
    assert.equal(40, hall.near + hall.far + 2)
  end)
end)

describe("stalker_header", function()
  it("puts the stalker's name left and its footsteps right", function()
    local header = actions.stalker_header("Mr. X", 1, 30)
    assert.equal(30, vim.api.nvim_strwidth(header))
    assert.is_truthy(header:match("^Mr%. X%s+right behind you$"))
  end)
end)
