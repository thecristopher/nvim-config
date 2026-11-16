local hud = require("core.hud.actions")

describe("grid_move", function()
  -- ten of Claire's love notes in rows of four: 1-4, 5-8, 9-10
  it("steps right along a row", function()
    assert.equal(2, hud.grid_move(1, 10, 4, "l"))
  end)

  it("drops a whole row down", function()
    assert.equal(6, hud.grid_move(2, 10, 4, "j"))
  end)

  it("lands on the last note when the row below is short", function()
    assert.equal(10, hud.grid_move(8, 10, 4, "j"))
  end)

  it("leaves through the right edge so the chest can take over", function()
    assert.is_nil(hud.grid_move(4, 10, 4, "l"))
  end)

  it("never climbs above the first row", function()
    assert.is_nil(hud.grid_move(3, 10, 4, "k"))
  end)

  it("does nothing in an empty grid", function()
    assert.is_nil(hud.grid_move(1, 0, 4, "l"))
  end)
end)

describe("cycle", function()
  it("wraps from the last tab to the first", function()
    assert.equal(1, hud.cycle(5, 5, 1))
  end)

  it("wraps from the first tab back to the last", function()
    assert.equal(5, hud.cycle(1, 5, -1))
  end)
end)

describe("scroll", function()
  it("keeps the window still while the cursor is inside it", function()
    assert.equal(2, hud.scroll(3, 4, 2))
  end)

  it("follows the cursor down past the last visible row", function()
    assert.equal(3, hud.scroll(6, 4, 0))
  end)

  it("follows it back up", function()
    assert.equal(1, hud.scroll(1, 4, 3))
  end)
end)

describe("text", function()
  it("cuts a long name with an ellipsis", function()
    assert.equal("Anniver…", hud.fit("Anniversary playlist", 8))
  end)

  it("pads a short one to its width", function()
    assert.equal("Inde  ", hud.pad("Inde", 6))
  end)

  it("wraps Malenia's letter at spaces", function()
    assert.same({ "I have never", "known defeat" }, hud.wrap("I have never known defeat", 12))
  end)
end)

describe("compose", function()
  it("turns chunks into one line and a mark per colored chunk", function()
    local lines, marks = hud.compose({ { { "Claire", "Name" }, { " & " }, { "Inde", "Name" } } })
    assert.equal("Claire & Inde", lines[1])
    assert.same({ { 0, 0, 6, "Name", 200 }, { 0, 9, 13, "Name", 200 } }, marks)
  end)

  it("measures marks in bytes, so frames and icons line up", function()
    local _, marks = hud.compose({ { { "╔═", "Frame" }, { "x", "Key" } } })
    assert.same({ 0, 6, 7, "Key", 200 }, marks[2])
  end)

  it("paints a chunk's background under its own color", function()
    local _, marks = hud.compose({ { { "Inde", "Name", bg = "Selected" } } })
    assert.same({ { 0, 0, 4, "Selected", 150 }, { 0, 0, 4, "Name", 200 } }, marks)
  end)

  it("remembers where a spot landed in display cells, past wide frames", function()
    local _, _, spots = hud.compose({ {}, { { "║ " }, { "Claire", "Name", spot = "cursor" } } })
    assert.same({ row = 1, col = 2 }, spots.cursor)
  end)
end)

describe("center", function()
  it("puts Malenia's name in the middle of a plaque", function()
    local lines = hud.compose({ hud.center({ { "Malenia" } }, 13) })
    assert.equal("   Malenia", lines[1])
  end)
end)

describe("middle", function()
  it("lowers a short column to the middle of a tall one", function()
    assert.equal(4, #hud.middle({ { { "Inde" } }, { { "Claire" } } }, 6))
  end)
end)

describe("portrait_fit", function()
  it("grows the portrait as tall as the screen lets it", function()
    assert.same({ width = 46, height = 28 }, hud.portrait_fit(200, 28, 12))
  end)

  it("shrinks it when the width runs out first", function()
    assert.same({ width = 33, height = 20 }, hud.portrait_fit(33, 40, 12))
  end)

  it("leaves it out when it would be too small to recognize anyone", function()
    assert.is_nil(hud.portrait_fit(15, 40, 12))
  end)
end)

describe("fit_hints", function()
  local hints = { "⏎ Love letter", "K Read", "q Goodbye" }

  it("shows every hint when Inde's screen is wide", function()
    assert.equal("⏎ Love letter   K Read   q Goodbye", hud.fit_hints(hints, 80))
  end)

  it("drops whole hints from the end instead of cutting one in half", function()
    assert.equal("⏎ Love letter   K Read", hud.fit_hints(hints, 26))
  end)

  it("shows nothing rather than a broken hint", function()
    assert.equal("", hud.fit_hints(hints, 5))
  end)
end)

describe("biggest_portrait", function()
  local roomy = { name = "roomy", portrait = { width = 46, height = 28 } }
  local snug = { name = "snug", portrait = { width = 20, height = 12 } }
  local bare = { name = "bare" }

  it("keeps the layout where Malenia stands tallest", function()
    assert.equal("roomy", hud.biggest_portrait({ snug, roomy, bare }).name)
  end)

  it("keeps the earlier layout when Claire stands just as tall in both", function()
    local twin = { name = "twin", portrait = { width = 46, height = 28 } }
    assert.equal("roomy", hud.biggest_portrait({ roomy, twin }).name)
  end)

  it("still hands back a layout when none has room for a portrait", function()
    assert.equal("bare", hud.biggest_portrait({ bare }).name)
  end)
end)

describe("beside", function()
  it("pads the left column so the right one starts in the same place on every row", function()
    local rows = hud.beside({ { { "ab" } }, { { "a" } } }, 4, { { { "R" } }, { { "R" } } }, 1)
    local lines = hud.compose(rows)
    assert.equal("ab   R", lines[1])
    assert.equal("a    R", lines[2])
  end)
end)

describe("byte_col", function()
  it("finds the byte where a display column starts after wide frames", function()
    assert.equal(6, hud.byte_col("╔═x", 2))
  end)
end)

describe("hud_window", function()
  -- Malenia's HUD shows in windows 1000 and 1003, Claire's cursor sits in one of them or elsewhere
  it("goes with the cursor when it is in a window showing the HUD", function()
    assert.equal(1003, hud.hud_window(1003, 1000, { 1000, 1003 }))
  end)

  it("stays where it was while the cursor is in Inde's love letter", function()
    assert.equal(1000, hud.hud_window(1005, 1000, { 1000, 1003 }))
  end)

  it("moves back to the window left when its split moved on to another buffer", function()
    assert.equal(1000, hud.hud_window(1003, 1003, { 1000 }))
  end)

  it("gives nil when no window shows the HUD anymore", function()
    assert.is_nil(hud.hud_window(1003, 1000, {}))
  end)
end)

describe("follows", function()
  -- Malenia opens the HUD in window 1000 (buffer 7) and Claire zooms it into window 1001
  it("moves to a zoom float showing the HUD", function()
    assert.is_true(hud.follows(1000, 7, 1001, 7))
  end)

  it("stays when the window is the one it is laid out for", function()
    assert.is_false(hud.follows(1000, 7, 1000, 7))
  end)

  it("ignores windows showing Inde's love letter instead", function()
    assert.is_false(hud.follows(1000, 7, 1001, 12))
  end)
end)

describe("resume_place", function()
  it("opens on the first tab the first time Claire opens it", function()
    local tab, cursor = hud.resume_place(nil, "inventory")
    assert.equal(1, tab)
    assert.same({ items = 1, chest = 1, quest = 1 }, cursor)
  end)

  it("lands Malenia back on the tab and slot she left", function()
    local last = { style = "roundtable", tab = 3, cursor = { items = 5, chest = 2, quest = 1 } }
    local tab, cursor = hud.resume_place(last, "roundtable")
    assert.equal(3, tab)
    assert.same({ items = 5, chest = 2, quest = 1 }, cursor)
  end)

  it("starts over when the franchise changed since Inde left", function()
    local last = { style = "roundtable", tab = 3, cursor = { items = 5, chest = 2, quest = 1 } }
    assert.equal(1, (hud.resume_place(last, "inventory")))
  end)
end)

describe("direct_keys", function()
  local keys = hud.direct_keys({ { key = "f" }, { key = "d" }, { key = "L" } })

  it("answers every hub key Claire adds, the desk included", function()
    assert.same({ "f", "d", "L" }, vim.list_slice(keys, 1, 3))
  end)

  it("keeps the digits that open Malenia's projects", function()
    assert.equal("1", keys[4])
    assert.equal("9", keys[#keys])
  end)
end)

describe("stale", function()
  it("fetches what was never fetched", function()
    assert.is_true(hud.stale(nil, 500, 10000))
  end)

  it("keeps Claire's playlist while it is fresh", function()
    assert.is_false(hud.stale(1000, 5000, 10000))
  end)

  it("fetches again once the time to live is over", function()
    assert.is_true(hud.stale(1000, 11000, 10000))
  end)
end)

describe("parse_branch", function()
  it("reads the branch, its last commit and how far ahead it is", function()
    assert.same(
      { branch = "feature/anniversary", when = "2 days ago", ahead = 3 },
      hud.parse_branch("feature/anniversary\t2 days ago\t3 1")
    )
  end)

  it("leaves the count out on git without ahead-behind", function()
    assert.same(
      { branch = "malenia/haligtree", when = "a week ago" },
      hud.parse_branch("malenia/haligtree\ta week ago")
    )
  end)

  it("skips an empty line", function()
    assert.is_nil(hud.parse_branch(""))
  end)
end)

describe("hud looks", function()
  local p = {
    yellow = "#D8466A",
    base = "#0A0D10",
    text = "#E0E0E0",
    subtext0 = "#A0A0A0",
    subtext1 = "#B0B0B0",
    surface1 = "#303030",
    surface2 = "#404040",
    overlay0 = "#606060",
    overlay1 = "#707070",
    rosewater = "#F0D0D0",
    peach = "#F0B070",
  }
  local blend = require("core.themes.actions").blend

  it("gives Claire's RE tabs plates and Malenia's a rule", function()
    assert.equal(p.surface1, hud.hud_groups(p, blend, true).EldenHudTab.bg)
    assert.is_nil(hud.hud_groups(p, blend, false).EldenHudTab.bg)
  end)

  it("lights the selection brighter than it rests", function()
    local rest = hud.hud_groups(p, blend, true).EldenHudSlotSel.bg
    local lit = hud.selection_flash(p, blend).EldenHudSlotSel.bg
    assert.is_true(tonumber(lit:sub(2, 3), 16) > tonumber(rest:sub(2, 3), 16))
  end)

  it("sinks every color toward the background for the entrance", function()
    local sunk =
      hud.sunk({ EldenHudName = { fg = "#FFFFFF", bold = true } }, "#000000", blend, 0.25)
    assert.equal("#404040", sunk.EldenHudName.fg)
    assert.is_true(sunk.EldenHudName.bold)
  end)

  it("leaves the looks it sinks untouched", function()
    local groups = { EldenHudName = { fg = "#FFFFFF" } }
    hud.sunk(groups, "#000000", blend, 0.25)
    assert.equal("#FFFFFF", groups.EldenHudName.fg)
  end)
end)

describe("hint_chunks", function()
  it("colors Claire's keys apart from their labels", function()
    local chunks = hud.hint_chunks({ "K Check", "⇥ Tabs" }, 80, "Key", "Label")
    assert.same({
      { "K", "Key" },
      { " Check", "Label" },
      { "   ", "Label" },
      { "⇥", "Key" },
      { " Tabs", "Label" },
    }, chunks)
  end)

  it("drops the hints that do not fit, last first", function()
    local chunks = hud.hint_chunks({ "K Check", "q Quit" }, 7, "Key", "Label")
    assert.equal(2, #chunks)
  end)

  it("keeps a hint without a label whole", function()
    assert.same({ { "Inde", "Label" } }, hud.hint_chunks({ "Inde" }, 10, "Key", "Label"))
  end)
end)

describe("last_in", function()
  local oldfiles = {
    "/Users/claire/.claude/desk.html",
    "/Users/claire/love-letters/notes/anniversary.md",
    "/Users/claire/love-letters-old/draft.md",
  }

  it("picks the last file Claire touched inside the project", function()
    assert.equal(
      "/Users/claire/love-letters/notes/anniversary.md",
      hud.last_in(oldfiles, "/Users/claire/love-letters")
    )
  end)

  it("never mistakes a sibling folder that starts the same for the project", function()
    local recent =
      { "/Users/claire/love-letters-old/draft.md", "/Users/claire/love-letters/vows.md" }
    assert.equal(
      "/Users/claire/love-letters/vows.md",
      hud.last_in(recent, "/Users/claire/love-letters")
    )
  end)

  it("falls back to the newest file anywhere outside a project", function()
    assert.equal("/Users/claire/.claude/desk.html", hud.last_in(oldfiles, nil))
  end)
end)
