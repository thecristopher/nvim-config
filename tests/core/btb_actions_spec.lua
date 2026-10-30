local actions = require("core.btb.actions")

describe("coach_of", function()
  it("makes Claire the coach on Raccoon City's day, by her persona", function()
    assert.are.equal("claire", actions.coach_of({ character = "Claire Redfield" }, "Resident Evil"))
    assert.are.equal("ada", actions.coach_of({ character = "Ada Wong" }, "Resident Evil"))
    assert.are.equal("malenia", actions.coach_of({ character = "Malenia" }, "Elden Ring"))
  end)

  it("hands btb Leon to summon on his region's day", function()
    assert.are.same(
      { id = "leon-s-kennedy", character = "Leon S. Kennedy", franchise = "Resident Evil" },
      actions.coach_of({ character = "Leon S. Kennedy" }, "Resident Evil")
    )
  end)

  it("leaves the choice to btb when the region has nobody", function()
    assert.is_nil(actions.coach_of({}, "Elden Ring"))
    assert.is_nil(actions.coach_of(nil, "Elden Ring"))
  end)

  it("names every region's character as a persona btb can keep", function()
    assert.are.equal("mimic-tear", actions.persona_id("Mimic Tear"))
    for _, name in ipairs({ "resident_evil", "elden_ring" }) do
      for _, region in ipairs(require("core.franchise.actions").lore(name).regions) do
        local id = actions.persona_id(region.character)
        assert.is_nil(id:find("[^a-z0-9%-]"), id)
        assert.is_nil(id:find("^%-") or id:find("%-$") or id:find("%-%-"), id)
      end
    end
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

describe("pass_sound", function()
  it("has the merchant praise every pass, a redo included", function()
    assert.are.equal("weapon", actions.pass_sound({ ok = true, outcome = "struggled" }))
    assert.are.equal("weapon", actions.pass_sound({ ok = true, redo = true }))
  end)

  it("stays quiet on a failure", function()
    assert.is_nil(actions.pass_sound({ ok = false }))
  end)
end)

describe("shop_greeting", function()
  it("welcomes Leon on his first visit of the day", function()
    assert.are.same(
      { "welcome", "merchant" },
      actions.shop_greeting("2026-10-29 resident_evil", "2026-10-30", "resident_evil")
    )
  end)

  it("only asks what he is buying after that", function()
    assert.are.same(
      { "merchant" },
      actions.shop_greeting("2026-10-30 resident_evil", "2026-10-30", "resident_evil")
    )
  end)

  it("welcomes again when Malenia's franchise takes over the same day", function()
    assert.are.same(
      { "welcome", "merchant" },
      actions.shop_greeting("2026-10-30 resident_evil", "2026-10-30", "elden_ring")
    )
  end)

  it("welcomes on the very first visit, with nothing saved", function()
    assert.are.same(
      { "welcome", "merchant" },
      actions.shop_greeting(nil, "2026-10-30", "elden_ring")
    )
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

  it("draws Leon from his region when the summoned coach brings no portrait", function()
    local file = actions.portrait_file("/config", { name = "Leon" }, { portrait = "leon.jpg" })
    assert.are.equal("/config/images/portraits/leon.jpg", file)
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

describe("ahead_text", function()
  it("shows Claire forging the next exercise", function()
    local text = actions.ahead_text({ step = "forge", label = "Forjando el siguiente" })
    assert.are.equal("󰈸 Forjando el siguiente", text)
  end)

  it("keeps the icon when btb sends no label", function()
    assert.are.equal("󰭹", actions.ahead_text({ step = "brief" }))
  end)

  it("goes away once the work is done, failed or never started", function()
    assert.are.equal("", actions.ahead_text({ step = "done" }))
    assert.are.equal("", actions.ahead_text({ step = "failed", error = "Wesker" }))
    assert.are.equal("", actions.ahead_text(nil))
  end)
end)

describe("day_status", function()
  it("counts what Claire still has to fight today", function()
    local today = {
      streak = 6,
      queue = {
        { id = "node/love-note", done = true, review = false },
        { id = nil, slot = true, done = false, review = false },
        { id = "react/playlist", done = false, review = true },
      },
    }
    assert.same({ new = 1, reviews = 1, streak = 6, done = false }, actions.day_status(today))
  end)

  it("knows Malenia is done once nothing is pending", function()
    local today = { streak = 2, queue = { { id = "py/haligtree", done = true } } }
    assert.is_true(actions.day_status(today).done)
  end)

  it("says nothing until btb answers", function()
    assert.is_nil(actions.day_status({ error = "no node" }))
  end)
end)

describe("day_line", function()
  it("reads what is left and the streak", function()
    local line = actions.day_line({ new = 2, reviews = 1, streak = 6, done = false })
    assert.equal("2 new · 1 review · streak 6", line)
  end)

  it("celebrates a finished day", function()
    assert.equal(
      "Done for today ✓ · streak 3",
      actions.day_line({ new = 0, reviews = 0, streak = 3, done = true })
    )
  end)

  it("leaves the streak out on Inde's first day", function()
    assert.equal("2 reviews", actions.day_line({ new = 0, reviews = 2, streak = 0, done = false }))
  end)
end)

describe("day_rank", function()
  local flawless = { solved = 2, clean = 2, skipped = 0, hints = 0, xp = 40, goal = 40 }

  it("gives Malenia an S for a flawless day at the goal", function()
    assert.equal("S", actions.day_rank(flawless))
  end)

  it("drops Claire to an A when a hint was needed", function()
    assert.equal("A", actions.day_rank(vim.tbl_extend("force", flawless, { hints = 1 })))
  end)

  it("gives a B when half the fights were clean", function()
    local day = { solved = 2, clean = 1, skipped = 0, hints = 2, xp = 20, goal = 40 }
    assert.equal("B", actions.day_rank(day))
  end)

  it("gives a D when skips outweigh the solves", function()
    local day = { solved = 1, clean = 0, skipped = 2, hints = 3, xp = 4, goal = 40 }
    assert.equal("D", actions.day_rank(day))
  end)
end)

describe("celebration at the end of the day", function()
  it("closes Inde's day with the great banner and its rank", function()
    local day = { solved = 2, clean = 2, skipped = 0, hints = 0, xp = 40, goal = 40 }
    local fanfare = actions.celebration({
      ok = true,
      outcome = "clean",
      xp = 15,
      title = "Aniversario",
      day = day,
    })
    assert.equal("great", fanfare.banner)
    assert.equal("day cleared  ·  rank S  ·  Aniversario  ·  +15 XP", fanfare.subtitle)
  end)
end)

describe("path_map", function()
  local status = {
    tracks = {
      {
        id = "node",
        title = "Node",
        drawn = true,
        current = 2,
        levels = {
          { level = 1, title = "Basics", clean = 4, target = 4, done = true },
          { level = 2, title = "Closures", clean = 1, target = 4, done = false },
          { level = 3, title = "Async", clean = 0, target = 4, done = false },
        },
      },
      { id = "llm", title = "LLM", drawn = false, locked = { after = "python" }, levels = {} },
    },
  }

  it("draws Claire's Node path as a chain, cleared, current and ahead", function()
    local lines = actions.path_map(status)
    assert.equal(" Node", lines[1])
    assert.equal("   ◆━━◈━━◇", lines[2])
    assert.equal("   level 2 · Closures · 1/4 clean", lines[3])
  end)

  it("lights each node with its state", function()
    local _, marks = actions.path_map(status)
    local groups = vim.tbl_map(function(mark)
      return mark.group
    end, marks)
    assert.same({ "Title", "EldenMapCleared", "DiagnosticWarn", "Comment", "Title" }, groups)
  end)

  it("keeps a locked track out of Malenia's map but names it", function()
    local lines = actions.path_map(status)
    assert.equal(" LLM", lines[5])
    assert.equal("   locked for now", lines[6])
  end)
end)

describe("onsite_name", function()
  it("puts the franchise's word for the onsite beside the boss", function()
    assert.equal(
      "Nemesis T-Type  ·  Final Exam",
      actions.onsite_name("Nemesis T-Type", { onsite = "Final Exam" })
    )
  end)
end)

describe("hint_offer", function()
  local coach = { hint = "What are ya buyin'? A hint for %d XP" }

  it("quotes Claire the price of the next hint", function()
    assert.equal(
      "What are ya buyin'? A hint for 3 XP",
      actions.hint_offer(coach, { hints_left = 2, cost = 3 })
    )
  end)

  it("sells nothing once the hints run out", function()
    assert.is_nil(actions.hint_offer(coach, { hints_left = 0, cost = 3 }))
  end)
end)

describe("concept_map", function()
  local concepts = {
    {
      track = "node",
      concept = "recursion",
      clean = 0,
      struggled = 1,
      skipped = 1,
      standing = "weak",
    },
    {
      track = "node",
      concept = "closures",
      clean = 3,
      struggled = 0,
      skipped = 0,
      standing = "owned",
    },
    {
      track = "react",
      concept = "state",
      clean = 1,
      struggled = 0,
      skipped = 0,
      standing = "learning",
    },
  }

  it("draws Malenia's concepts as rooms under their track", function()
    local lines = actions.concept_map(concepts)
    assert.same({
      " node",
      " □ recursion  ✓0  ✗2",
      " ■ closures   ✓3  ✗0",
      "",
      " react",
      " ▣ state      ✓1  ✗0",
    }, lines)
  end)

  it("paints the costly rooms red and the owned ones blue", function()
    local _, marks = actions.concept_map(concepts)
    assert.equal("EldenMapLeft", marks[2].group)
    assert.equal("EldenMapCleared", marks[3].group)
  end)

  it("remembers the track of every room so Enter opens the right library", function()
    local _, _, tracks = actions.concept_map(concepts)
    assert.equal("node", tracks[2])
    assert.equal("react", tracks[6])
    assert.is_nil(tracks[1])
  end)
end)
