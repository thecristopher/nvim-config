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

describe("wrap", function()
  it("breaks Claire's love note between words", function()
    assert.same({ "Meet me at", "the roof" }, panel.wrap("Meet me at the roof", 10))
  end)

  it("cuts a word wider than the row", function()
    assert.same({ "Haligt", "ree" }, panel.wrap("Haligtree", 6))
  end)

  it("keeps an empty line as one empty row", function()
    assert.same({ "" }, panel.wrap("", 10))
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
    for _, height in ipairs(panel.equalizer(500, false)) do
      assert.equal(1, height)
    end
  end)

  it("dances through both rows of levels while it plays", function()
    local tallest = 1
    for ms = 0, 3000, 100 do
      for _, height in ipairs(panel.equalizer(ms, true)) do
        assert.is_true(height >= 1 and height <= 16)
        tallest = math.max(tallest, height)
      end
    end
    assert.is_true(tallest > 8)
  end)

  it("lets the bass on the left stand taller than the treble, like Claire's car stereo", function()
    local bass, treble = 0, 0
    for ms = 0, 20000, 50 do
      local heights = panel.equalizer(ms, true)
      bass, treble = bass + heights[1], treble + heights[#heights]
    end
    assert.is_true(bass > treble)
  end)

  it("moves from one moment to the next", function()
    assert.are_not.same(panel.equalizer(0, true), panel.equalizer(400, true))
  end)
end)

describe("equalizer_rows", function()
  it("leaves the upper row dark while the song is paused", function()
    local paused = vim.tbl_extend("force", song, { playing = false })
    local rows = panel.equalizer_rows(paused, 0)
    assert.equal("", vim.trim(rows.lines[1]))
    assert.truthy(rows.lines[2]:find("▁ ▁", 1, true))
  end)

  it("fits beside the cover", function()
    for _, line in ipairs(panel.equalizer_rows(song, 900).lines) do
      assert.is_true(vim.fn.strdisplaywidth(line) <= panel.WIDTH)
    end
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

  local serenade = {
    kind = "synced",
    lines = {
      { time = 1, text = "Malenia waits beneath the Haligtree" },
      {
        time = 5,
        text = "Inde crossed the Lands Between with a love letter folded in her gauntlet for Malenia",
      },
      { time = 12, text = "Claire hums along" },
    },
  }

  it("wraps a long sung line onto the next row instead of cutting it", function()
    local block = panel.lyrics_block(view({ lyrics = serenade, focus = 2 }))
    local sung = vim.trim(block.lines[2]) .. " " .. vim.trim(block.lines[3])
    assert.equal(
      "▸ Inde crossed the Lands Between with a love ◂ ▸ letter folded in her gauntlet for Malenia ◂",
      sung
    )
    for _, line in ipairs(block.lines) do
      assert.is_nil(line:find("…", 1, true))
    end
  end)

  it("gives the spare row around a wrapped sung line to what comes next", function()
    local block = panel.lyrics_block(view({ lyrics = serenade, focus = 2 }))
    assert.equal("Malenia waits beneath the Haligtree", vim.trim(block.lines[1]))
    assert.equal("Claire hums along", vim.trim(block.lines[4]))
  end)

  it(
    "cuts a neighbor that does not fit whole on one row instead of leaving a piece of it",
    function()
      local vow = ("Malenia promised Inde a garden of scarlet roses "):rep(3)
      local promise = {
        kind = "synced",
        lines = { { time = 1, text = vow }, { time = 9, text = "Claire hums along" } },
      }
      local block = panel.lyrics_block(view({ lyrics = promise, focus = 2 }))
      assert.equal("", block.lines[1])
      assert.truthy(block.lines[2]:find("…$"))
      assert.equal("▸ Claire hums along ◂", vim.trim(block.lines[3]))
    end
  )

  it("keeps a neighbor on each side however long the sung line is", function()
    local vow = ("Inde "):rep(60)
    local promise = {
      kind = "synced",
      lines = {
        { time = 1, text = "Claire hums along" },
        { time = 5, text = vow },
        { time = 9, text = "Malenia answers" },
      },
    }
    local block = panel.lyrics_block(view({ lyrics = promise, focus = 2 }))
    assert.equal("Claire hums along", vim.trim(block.lines[1]))
    assert.truthy(block.lines[4]:find("… ◂", 1, true))
    assert.equal("Malenia answers", vim.trim(block.lines[5]))
  end)

  it("carries the sweep from the first row of Inde's verse onto the second", function()
    local block = panel.lyrics_block(view({ lyrics = serenade, focus = 2, sweep = 0.75 }))
    assert.same(
      { "EldenMusicLyricMark", "EldenMusicLyricSweep", "EldenMusicLyricMark" },
      groups_on(block.marks, 1)
    )
    assert.same({
      "EldenMusicLyricMark",
      "EldenMusicLyricSweep",
      "EldenMusicLyric",
      "EldenMusicLyricMark",
    }, groups_on(block.marks, 2))
  end)

  it("shows a long neighbor whole when it fits above the sung line", function()
    local block = panel.lyrics_block(view({ lyrics = serenade, focus = 3 }))
    assert.equal("folded in her gauntlet for Malenia", vim.trim(block.lines[2]))
    assert.equal("▸ Claire hums along ◂", vim.trim(block.lines[3]))
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
  it("offers l to show or hide the lyrics", function()
    assert.truthy(panel.keys_row(song).lines[1]:find("󰝚 l", 1, true))
  end)

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

describe("height", function()
  it("shrinks when Malenia hides the lyrics", function()
    assert.is_true(panel.height(true) < panel.height(false))
    assert.equal(panel.height(false) - panel.LYRIC_ROWS - 1, panel.height(true))
  end)
end)

describe("panel", function()
  it("puts the song, the equalizer and the progress beside the cover, the keys last", function()
    local layout = panel.panel(song, view())
    assert.equal(panel.height(false), #layout.lines)
    assert.truthy(layout.lines[2]:find("Shared Playlist", 1, true))
    assert.truthy(layout.lines[3]:find("Inde Navarrete", 1, true))
    assert.truthy(layout.lines[4]:find("󰀥 Our Anniversary", 1, true))
    assert.truthy(layout.lines[panel.ROWS.equalizer + 2]:find("[▁▂▃▄▅▆▇█]"))
    assert.truthy(layout.lines[panel.ROWS.progress + 1]:find("1:02", 1, true))
    assert.truthy(layout.lines[panel.ROWS.lyrics]:find("◈", 1, true))
    assert.truthy(layout.lines[#layout.lines]:find("󰅖 q", 1, true))
  end)

  it("never says which player is playing", function()
    for _, line in ipairs(panel.panel(song, view()).lines) do
      assert.is_nil(line:find("Playing", 1, true))
      assert.is_nil(line:find("Cider", 1, true))
    end
  end)

  it("leaves the album row empty for a single without one", function()
    local single = vim.tbl_extend("force", song, { album = "" })
    assert.equal("", panel.panel(single, view()).lines[4])
  end)

  it("drops the lyrics and their divider when they are hidden", function()
    local layout = panel.panel(song, view({ lyrics = date_night, focus = 1, hide_lyrics = true }))
    assert.equal(panel.height(true), #layout.lines)
    assert.same({}, layout.marks.lyrics)
    assert.truthy(layout.lines[panel.ROWS.lyrics]:find("◈", 1, true))
    assert.truthy(layout.lines[#layout.lines]:find("󰝚 l", 1, true))
  end)

  it("leaves the cover's columns empty so the image lands on blank space", function()
    local layout = panel.panel(song, view())
    local beside = layout.cover.col + layout.cover.width
    for row = 1, layout.cover.height do
      assert.equal("", vim.trim(layout.lines[row]:sub(1, beside)))
    end
  end)

  it("keeps each moving piece's marks on its own rows", function()
    local layout = panel.panel(song, view({ lyrics = date_night, focus = 1 }))
    for _, mark in ipairs(layout.marks.equalizer) do
      assert.is_true(mark.row == panel.ROWS.equalizer or mark.row == panel.ROWS.equalizer + 1)
    end
    for _, mark in ipairs(layout.marks.progress) do
      assert.equal(panel.ROWS.progress, mark.row)
    end
    for _, mark in ipairs(layout.marks.lyrics) do
      assert.is_true(mark.row >= panel.ROWS.lyrics)
      assert.is_true(mark.row < panel.ROWS.lyrics + panel.LYRIC_ROWS)
    end
  end)

  it("keeps the same height whether the lyrics arrived or not", function()
    local waiting = panel.panel(song, view())
    local synced = panel.panel(song, view({ lyrics = date_night, focus = 1 }))
    assert.equal(#waiting.lines, #synced.lines)
  end)

  it("keeps every line inside the panel in both franchises", function()
    local long = vim.tbl_extend("force", song, { title = ("Malenia "):rep(10) })
    local long_verse = { kind = "synced", lines = { { time = 1, text = ("Inde "):rep(40) } } }
    for _, lore in ipairs({ elden, evil }) do
      for _, lyrics in ipairs({ date_night, long_verse }) do
        local looks = view({ lyrics = lyrics, focus = 1, eq_ms = 900, style = lore.skin.music })
        for _, line in ipairs(panel.panel(long, looks).lines) do
          assert.is_true(vim.fn.strdisplaywidth(line) <= panel.WIDTH)
        end
      end
    end
  end)
end)
