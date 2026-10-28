local actions = require("core.btb.actions")

describe("persona_of", function()
  it("reads the coach of the franchise", function()
    assert.are.equal("claire", actions.persona_of({ coach = { persona = "claire" } }))
  end)

  it("leaves the choice to btb when the lore names nobody", function()
    assert.is_nil(actions.persona_of({ coach = { persona = "" } }))
    assert.is_nil(actions.persona_of({}))
  end)

  it("gives Resident Evil to Claire and Elden Ring to Malenia", function()
    local lore = require("core.franchise.actions").lore
    assert.are.equal("claire", actions.persona_of(lore("resident_evil")))
    assert.are.equal("malenia", actions.persona_of(lore("elden_ring")))
  end)
end)

describe("sound_for", function()
  it("summons Malenia with the spirit calling bell, Claire with the HUD's own sound", function()
    assert.are.same({ "summon", "hud_open" }, actions.sound_for("coach_open"))
  end)

  it("stays quiet on a clean solve, the banner already sings", function()
    assert.is_nil(actions.sound_for("passed_clean"))
  end)
end)

describe("celebration", function()
  it("fells the enemy on a clean solve, names it and pays its XP in runes", function()
    local fanfare =
      actions.celebration({ ok = true, outcome = "clean", xp = 15, title = "Notas de amor" })
    assert.are.same(
      { banner = "felled", subtitle = "Notas de amor  ·  +15 XP", runes = 15 },
      fanfare
    )
  end)

  it("brings out the great banner with the level when Inde levels up", function()
    local fanfare = actions.celebration({ ok = true, outcome = "struggled", xp = 8, level_up = 1 })
    assert.are.equal("great", fanfare.banner)
    assert.are.equal("level 1 cleared  ·  +8 XP", fanfare.subtitle)
  end)

  it("still pays tribute when the title is missing", function()
    local fanfare = actions.celebration({ ok = true, outcome = "clean", xp = 15 })
    assert.are.equal("+15 XP", fanfare.subtitle)
  end)

  it("pays a struggled solve without a banner", function()
    assert.are.same(
      { banner = nil, subtitle = nil, runes = 6 },
      actions.celebration({ ok = true, outcome = "struggled", xp = 6 })
    )
  end)

  it("gives nothing for a failure or a redo", function()
    local nothing = { banner = nil, subtitle = nil, runes = 0 }
    assert.are.same(nothing, actions.celebration({ ok = false, xp = 0 }))
    assert.are.same(nothing, actions.celebration({ ok = true, redo = true, xp = 0 }))
  end)
end)

describe("portrait_file", function()
  it("finds Claire's portrait among the config's portraits", function()
    local file = actions.portrait_file("/config", { portrait = "claire.jpg" })
    assert.are.equal("/config/images/portraits/claire.jpg", file)
  end)

  it("has nothing to draw for a coach without a portrait", function()
    assert.is_nil(actions.portrait_file("/config", { name = "Melina" }))
  end)
end)

describe("hud lessons", function()
  local love_note =
    { id = "node/love-note", title = "Love note", level = 1, concepts = { "closures" } }

  local function lesson(fields)
    return vim.tbl_extend("force", love_note, { lesson = "/btb/lesson.md" }, fields)
  end

  it("reads a lesson with its state, level and concepts", function()
    local fields = actions.hud_fields(lesson({ state = "solved" }))
    assert.are.same({ icon = "✓", name = "Love note", count = 1, desc = "closures" }, fields)
  end)

  it("shows only what was fought, the newest solve first", function()
    local entries = {
      lesson({ id = "a", state = "solved", solvedAt = "2026-10-20" }),
      lesson({ id = "b", state = "new" }),
      lesson({ id = "c", state = "mastered", solvedAt = "2026-10-26" }),
    }
    local ids = vim.tbl_map(function(entry)
      return entry.id
    end, actions.hud_lessons(entries, 5))
    assert.are.same({ "c", "a" }, ids)
  end)

  it("keeps the HUD to the limit it asks for", function()
    local entries = {
      lesson({ id = "a", state = "solved" }),
      lesson({ id = "b", state = "solved" }),
    }
    assert.are.equal(1, #actions.hud_lessons(entries, 1))
  end)
end)

describe("portrait_anchor", function()
  it("fills a stage window shaped like Claire's portrait", function()
    assert.are.same({ row = 0, col = 0, width = 33, height = 20 }, actions.portrait_anchor(33, 20))
  end)

  it("centers Malenia in a narrow window instead of stretching her", function()
    assert.are.same({ row = 5, col = 0, width = 16, height = 10 }, actions.portrait_anchor(16, 20))
  end)

  it("centers Inde's coach in a short, wide window", function()
    assert.are.same({ row = 0, col = 4, width = 16, height = 10 }, actions.portrait_anchor(24, 10))
  end)
end)
