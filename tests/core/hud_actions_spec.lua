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

describe("stale_copies", function()
  it("throws away the copy of Claire's portrait made before it was recropped", function()
    local copies = { { file = "claire.png", mtime = 100 } }
    assert.same({ "claire.png" }, hud.stale_copies(200, copies))
  end)

  it("keeps the copy of Malenia's figure made after her photo", function()
    local copies = { { file = "malenia.png", mtime = 300 } }
    assert.same({}, hud.stale_copies(200, copies))
  end)

  it("skips the copy of Inde's date photo that was never made", function()
    assert.same({}, hud.stale_copies(200, { { file = "inde.png" } }))
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

describe("typing", function()
  it("types a short note to Inde at its own pace", function()
    assert.equal(10 * hud.TYPING.per_char, hud.typing_ms(10))
  end)

  it("never makes Claire wait on a long description", function()
    assert.equal(hud.TYPING.max, hud.typing_ms(500))
    assert.equal(0, hud.typing_ms(0))
  end)
end)

describe("reveal", function()
  local lines = { "Roses for Malenia", "at the Haligtree" }

  it("shows the whole description once it has typed in", function()
    assert.same(lines, hud.reveal(lines, nil))
    assert.same(lines, hud.reveal(lines, 999))
  end)

  it("blanks what is still to come, keeping every line as wide", function()
    assert.same({ "Roses            ", "                " }, hud.reveal(lines, 5))
  end)

  it("carries on into the second line", function()
    assert.same({ "Roses for Malenia", "at              " }, hud.reveal(lines, 19))
  end)

  it("counts characters, not bytes", function()
    assert.same({ "Inde ♥  " }, hud.reveal({ "Inde ♥ ♥" }, 6))
  end)
end)

describe("bar_fill", function()
  it("fills half of Claire's playlist bar halfway through the song", function()
    assert.equal(5, hud.bar_fill(120, 240, 10))
  end)

  it("stays full past the end and says nothing without a length", function()
    assert.equal(10, hud.bar_fill(300, 240, 10))
    assert.is_nil(hud.bar_fill(30, nil, 10))
    assert.is_nil(hud.bar_fill(nil, 240, 10))
  end)
end)

describe("the attaché case", function()
  -- Claire's case: a wide love letter, three small keepsakes and a big box of photos
  local items = {
    { name = "Love letter", size = { w = 2, h = 1 } },
    { name = "Rose" },
    { name = "Ring" },
    { name = "Photo box", size = { w = 2, h = 2 } },
    { name = "Mixtape" },
  }
  local case = hud.pack(items, 3)

  it("packs the wide letter across two cells and the next keepsake beside it", function()
    assert.same({ row = 1, col = 1, w = 2, h = 1 }, case.places[1])
    assert.same({ row = 1, col = 3, w = 1, h = 1 }, case.places[2])
  end)

  it("gives the photo box four cells and fills the hole it leaves", function()
    assert.same({ row = 2, col = 2, w = 2, h = 2 }, case.places[4])
    assert.same({ row = 3, col = 1, w = 1, h = 1 }, case.places[5])
    assert.equal(3, case.rows)
  end)

  it("never lets a piece grow wider than the case", function()
    local narrow = hud.pack({ { size = { w = 3, h = 1 } } }, 2)
    assert.equal(2, narrow.places[1].w)
  end)

  it("walks right from the letter to the rose and down into the photo box", function()
    assert.equal(2, hud.case_move(case, 1, "l"))
    assert.equal(4, hud.case_move(case, 2, "j"))
  end)

  it("steps over empty cells to reach the next keepsake", function()
    local sparse = hud.pack({ { name = "Rose" }, { name = "Ring" } }, 3)
    sparse.cells[1][2] = nil
    sparse.places[2] = { row = 1, col = 3, w = 1, h = 1 }
    sparse.cells[1][3] = 2
    assert.equal(2, hud.case_move(sparse, 1, "l"))
  end)

  it("leaves the case through its edge", function()
    assert.is_nil(hud.case_move(case, 1, "k"))
    assert.is_nil(hud.case_move(case, 2, "l"))
  end)

  it("scrolls just enough to show the whole photo box", function()
    assert.equal(2, hud.case_scroll(case.places[4], 1, 0))
    assert.equal(1, hud.case_scroll(case.places[4], 2, 0))
    assert.equal(0, hud.case_scroll(case.places[1], 2, 1))
  end)

  it("joins the walls with the double line joint their arms ask for", function()
    assert.equal("╬", hud.joint(true, true, true, true))
    assert.equal("╔", hud.joint(false, true, false, true))
    assert.equal("╩", hud.joint(true, false, true, true))
    assert.equal(" ", hud.joint(false, false, false, false))
  end)
end)

describe("item screen helpers", function()
  it("says how long ago Inde last wrote her note", function()
    assert.equal("just now", hud.ago(20))
    assert.equal("1 minute ago", hud.ago(65))
    assert.equal("3 hours ago", hud.ago(3 * 3600 + 5))
    assert.equal("2 days ago", hud.ago(2 * 86400))
  end)

  it("tells two init.lua apart by their folder and leaves a lone name bare", function()
    assert.same(
      { "hud/init.lua", "hub/init.lua", "letter.md" },
      hud.file_labels({ "/claire/hud/init.lua", "/claire/hub/init.lua", "/inde/letter.md" })
    )
  end)

  it("lays Malenia's attributes in two columns, filling the left one first", function()
    local rows = hud.stat_rows({ { "Level", "S" }, { "Vigor", "14" }, { "Mind", "2" } }, 30)
    local first = table.concat(vim.tbl_map(function(chunk)
      return chunk[1]
    end, rows[1]))
    assert.equal(2, #rows)
    assert.is_truthy(first:find("Level", 1, true))
    assert.is_truthy(first:find("Mind", 1, true))
  end)

  it("lights the cells around the glint and leaves the rest of the frame alone", function()
    local chunks = hud.glint_run("━━━━━━", "EldenHudFrameSel", 2, "EldenHudGlint")
    assert.same(
      { "━", "━━━", "━━" },
      vim.tbl_map(function(chunk)
        return chunk[1]
      end, chunks)
    )
    assert.equal("EldenHudGlint", chunks[2][2])
    assert.same(
      { { "━━", "EldenHudFrame" } },
      hud.glint_run("━━", "EldenHudFrame", nil, "x")
    )
  end)

  it("pins the runes held to the right edge when the row has room", function()
    local row = hud.corner({ { "Roundtable" } }, { { "◈ 600" } }, 30)
    assert.equal(30, hud.width(row))
    assert.same({ { "Roundtable" } }, hud.corner({ { "Roundtable" } }, { { "◈ 600" } }, 14))
  end)

  it("sets the typewriter's carriage right after the last letter struck", function()
    assert.same({ "Dear▌    " }, hud.typed_with_caret({ "Dear Inde" }, 4, "▌"))
    assert.same({ "Dear Inde" }, hud.typed_with_caret({ "Dear Inde" }, nil, "▌"))
  end)

  it("opens Claire's Check float beside her slot, or left of it at the screen's edge", function()
    local screen = { columns = 120, lines = 40, gap = 18 }
    assert.same(
      { row = 9, col = 38 },
      hud.float_beside({ row = 10, col = 20 }, { width = 30, height = 8 }, screen)
    )
    assert.same(
      { row = 9, col = 57 },
      hud.float_beside({ row = 10, col = 90 }, { width = 30, height = 8 }, screen)
    )
  end)

  it("pages a long letter to Inde into pages as tall as the reader", function()
    local letter = {}
    for index = 1, 25 do
      letter[index] = "line " .. index
    end
    local pages = hud.pages(letter, 40, 10)
    assert.equal(3, #pages)
    assert.equal(" line 11", pages[2][1])
    assert.same({ { " " } }, { hud.pages({ "" }, 40, 10)[1] })
  end)
end)
