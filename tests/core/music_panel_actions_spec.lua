local panel = require("core.music.actions.panel")

local elden = require("core.franchise.actions").lore("elden_ring")
local evil = require("core.franchise.actions").lore("resident_evil")

local song = {
  title = "Shared Playlist",
  artist = "Inde Navarrete",
  album = "Our Anniversary",
  playing = true,
  duration = 250,
}

local date_night = {
  kind = "synced",
  lines = {
    { time = 1, text = "Inde, my love" },
    { time = 5, text = "Meet me at the Terrasave roof" },
    { time = 9, text = "" },
    { time = 12, text = "Claire waits by the gate" },
  },
}

local function view(extra)
  return vim.tbl_extend("force", {
    lyrics = nil,
    focus = 0,
    sweep = 0,
    elapsed = 62,
    eq_ms = 0,
    style = elden.skin.music,
    words = elden.music,
  }, extra or {})
end

local function groups_on(marks, row)
  local groups = {}
  for _, mark in ipairs(marks) do
    if mark.row == row then
      table.insert(groups, mark.group)
    end
  end
  return groups
end

describe("fit", function()
  it("keeps a short title whole", function()
    assert.equal("Love Note", panel.fit("Love Note", 20))
  end)

  it("cuts a long one and marks the cut", function()
    assert.equal("Malenia…", panel.fit("Malenia, Blade of Miquella", 8))
  end)
end)

describe("clock", function()
  it("writes the minute of Claire's song like a player", function()
    assert.equal("1:02", panel.clock(62.9))
    assert.equal("0:00", panel.clock(-3))
  end)
end)

describe("equalizer", function()
  it("lies flat while Inde's song is paused", function()
    assert.same({ 1, 1, 1, 1, 1, 1 }, panel.equalizer(500, false))
  end)

  it("dances inside the bar heights while it plays", function()
    local moved = false
    for _, height in ipairs(panel.equalizer(900, true)) do
      assert.is_true(height >= 1 and height <= 8)
      moved = moved or height > 1
    end
    assert.is_true(moved)
  end)

  it("moves from one moment to the next", function()
    assert.are_not.same(panel.equalizer(0, true), panel.equalizer(400, true))
  end)
end)

describe("progress_row", function()
  it("fills Malenia's gold thread up to where the song is", function()
    local row = panel.progress_row(125, 250, elden.skin.music.bar)
    local line = row.lines[1]
    assert.truthy(line:find("2:05 ", 1, true))
    assert.truthy(line:find(" 4:10", 1, true))
    assert.truthy(line:find("━◈─", 1, true))
  end)

  it("runs like a tape in Raccoon City", function()
    local line = panel.progress_row(0, 250, evil.skin.music.bar).lines[1]
    assert.truthy(line:find("0:00 ▶▱", 1, true))
  end)

  it("keeps the bar the same width at any moment", function()
    local start = panel.progress_row(0, 250, elden.skin.music.bar).lines[1]
    local finish = panel.progress_row(250, 250, elden.skin.music.bar).lines[1]
    assert.equal(vim.fn.strdisplaywidth(start), vim.fn.strdisplaywidth(finish))
  end)

  it("shows only the time when the player does not say how long the song is", function()
    assert.equal("1:02", vim.trim(panel.progress_row(62, nil, elden.skin.music.bar).lines[1]))
  end)

  it("stays empty when the player does not say where it is", function()
    assert.same({ "" }, panel.progress_row(nil, 250, elden.skin.music.bar).lines)
  end)
end)

describe("divider", function()
  it("crosses the panel with the gem in the middle", function()
    local line = panel.divider(elden.skin.music.divider).lines[1]
    assert.equal(panel.WIDTH - 1, vim.fn.strdisplaywidth(line))
    assert.truthy(line:find("─ ◈ ─", 1, true))
  end)
end)

describe("lyrics_block", function()
  it("wraps the sung line in the skin's marks with its neighbors fading by distance", function()
    local block = panel.lyrics_block(view({ lyrics = date_night, focus = 2 }))
    assert.equal(panel.LYRIC_ROWS, #block.lines)
    assert.equal("▸ Meet me at the Terrasave roof ◂", vim.trim(block.lines[3]))
    assert.same({ "EldenMusicLyricNear" }, groups_on(block.marks, 1))
    assert.same({ "EldenMusicLyricFar" }, groups_on(block.marks, 4))
  end)

  it("sweeps Claire's verse as far as it has been sung", function()
    local block = panel.lyrics_block(view({ lyrics = date_night, focus = 1, sweep = 0.4 }))
    local swept
    for _, mark in ipairs(block.marks) do
      if mark.group == "EldenMusicLyricSweep" then
        swept = block.lines[mark.row + 1]:sub(mark.col + 1, mark.end_col)
      end
    end
    assert.equal("Inde,", swept)
  end)

  it("shows the note icon during the pause between verses", function()
    local block = panel.lyrics_block(view({ lyrics = date_night, focus = 3 }))
    assert.equal("▸ 󰝚 ◂", vim.trim(block.lines[3]))
  end)

  it("centers each line inside the panel", function()
    local line = panel.lyrics_block(view({ lyrics = date_night, focus = 1 })).lines[3]
    local left = #line:match("^ *")
    local right = panel.WIDTH - vim.fn.strdisplaywidth(line)
    assert.is_true(math.abs(left - right) <= 1)
  end)

  it("speaks the franchise's words while the lyrics are on their way", function()
    local block = panel.lyrics_block(view({ style = evil.skin.music, words = evil.music }))
    assert.truthy(block.lines[3]:find(evil.music.loading, 1, true))
  end)

  it("says so when Wesker's song has no lyrics", function()
    local block = panel.lyrics_block(view({ lyrics = false }))
    assert.truthy(block.lines[3]:find(elden.music.missing, 1, true))
  end)

  it("shows plain lyrics from the first line asked for", function()
    local plain = { kind = "plain", lines = { { text = "Rose petals" }, { text = "for Inde" } } }
    local block = panel.lyrics_block(view({ lyrics = plain, focus = 2 }))
    assert.equal("for Inde", vim.trim(block.lines[1]))
    assert.same({ "EldenMusicLyricPlain" }, groups_on(block.marks, 0))
  end)
end)

describe("keys_row", function()
  it("offers pause while Inde's playlist plays", function()
    assert.truthy(panel.keys_row(song).lines[1]:find("󰏤 p", 1, true))
  end)

  it("offers play when Claire paused the song", function()
    local paused = vim.tbl_extend("force", song, { playing = false })
    assert.truthy(panel.keys_row(paused).lines[1]:find("󰐊 p", 1, true))
  end)
end)

describe("clamp_scroll", function()
  local lines = {}
  for i = 1, 8 do
    lines[i] = { text = "Malenia verse " .. i }
  end
  local plain = { kind = "plain", lines = lines }

  it("stops at the first line", function()
    assert.equal(1, panel.clamp_scroll(plain, 0))
  end)

  it("stops when the last line reaches the bottom row", function()
    assert.equal(8 - panel.LYRIC_ROWS + 1, panel.clamp_scroll(plain, 20))
  end)
end)

describe("panel", function()
  it("puts the song beside the cover, the lyrics between dividers and the keys last", function()
    local layout = panel.panel(song, "cider", view())
    assert.equal(panel.HEIGHT, #layout.lines)
    assert.truthy(layout.lines[1]:find("Shared Playlist", 1, true))
    assert.truthy(layout.lines[panel.ROWS.state + 1]:find("Playing in Cider", 1, true))
    assert.truthy(layout.lines[panel.ROWS.progress + 1]:find("1:02", 1, true))
    assert.truthy(layout.lines[panel.ROWS.lyrics]:find("◈", 1, true))
    assert.truthy(layout.lines[panel.HEIGHT]:find("󰅖 q", 1, true))
  end)

  it("leaves the cover's columns empty so the image lands on blank space", function()
    local layout = panel.panel(song, "music", view())
    local beside = layout.cover.col + layout.cover.width
    for row = 1, layout.cover.height do
      assert.equal("", vim.trim(layout.lines[row]:sub(1, beside)))
    end
  end)

  it("keeps each moving piece's marks on its own rows", function()
    local layout = panel.panel(song, "cider", view({ lyrics = date_night, focus = 1 }))
    for _, mark in ipairs(layout.marks.state) do
      assert.equal(panel.ROWS.state, mark.row)
    end
    for _, mark in ipairs(layout.marks.lyrics) do
      assert.is_true(mark.row >= panel.ROWS.lyrics)
      assert.is_true(mark.row < panel.ROWS.lyrics + panel.LYRIC_ROWS)
    end
  end)

  it("keeps the same height whether the lyrics arrived or not", function()
    local waiting = panel.panel(song, "cider", view())
    local synced = panel.panel(song, "cider", view({ lyrics = date_night, focus = 1 }))
    assert.equal(#waiting.lines, #synced.lines)
  end)

  it("keeps every line inside the panel in both franchises", function()
    local long = vim.tbl_extend("force", song, { title = ("Malenia "):rep(10) })
    for _, lore in ipairs({ elden, evil }) do
      local looks = view({ lyrics = date_night, focus = 2, style = lore.skin.music })
      for _, line in ipairs(panel.panel(long, "cider", looks).lines) do
        assert.is_true(vim.fn.strdisplaywidth(line) <= panel.WIDTH)
      end
    end
  end)
end)
