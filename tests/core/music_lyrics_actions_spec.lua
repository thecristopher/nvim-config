local lyrics = require("core.music.actions.lyrics")

local DATE_NIGHT_LRC = table.concat({
  "[ar:Claire Redfield]",
  "[00:05.50]Meet me at the Terrasave roof",
  "[00:01.00][00:12.00]Inde, my love",
  "",
  "[00:09.25]",
}, "\n")

describe("parse_lrc", function()
  it("sorts Claire's date night verses by the second they are sung", function()
    assert.same({
      { time = 1, text = "Inde, my love" },
      { time = 5.5, text = "Meet me at the Terrasave roof" },
      { time = 9.25, text = "" },
      { time = 12, text = "Inde, my love" },
    }, lyrics.parse_lrc(DATE_NIGHT_LRC))
  end)

  it("gives nothing for text without timestamps", function()
    assert.same({}, lyrics.parse_lrc("[ti:Waterfowl Dance]\nno beat here"))
    assert.same({}, lyrics.parse_lrc(nil))
  end)
end)

describe("parse", function()
  it("prefers the synced lyrics of Malenia's serenade", function()
    local body = vim.json.encode({ plainLyrics = "Inde, my love", syncedLyrics = DATE_NIGHT_LRC })
    local found = lyrics.parse(body)
    assert.equal("synced", found.kind)
    assert.equal(4, #found.lines)
  end)

  it("falls back to plain lyrics when the song has no timing", function()
    local body = '{"plainLyrics":"Rose petals\\nfor Inde","syncedLyrics":null}'
    assert.same(
      { kind = "plain", lines = { { text = "Rose petals" }, { text = "for Inde" } } },
      lyrics.parse(body)
    )
  end)

  it("tells an instrumental apart from a song nobody transcribed", function()
    assert.equal("instrumental", lyrics.parse('{"instrumental":true}').kind)
    assert.is_nil(lyrics.parse('{"plainLyrics":"","syncedLyrics":null}'))
    assert.is_nil(lyrics.parse("Not Found"))
    assert.is_nil(lyrics.parse(nil))
  end)
end)

describe("command", function()
  it("asks LRCLIB by artist and title, letting curl encode them", function()
    local cmd = lyrics.command({ artist = "Claire Redfield", title = "Love & Zombies" })
    assert.is_true(vim.tbl_contains(cmd, "artist_name=Claire Redfield"))
    assert.is_true(vim.tbl_contains(cmd, "track_name=Love & Zombies"))
    assert.equal(lyrics.LRCLIB_URL, cmd[#cmd])
  end)
end)

describe("name", function()
  it("gives each of Inde's songs its own lyrics", function()
    local note = { artist = "Inde Navarrete", title = "Love Note" }
    local date = { artist = "Inde Navarrete", title = "Date Night" }
    assert.are_not.equal(lyrics.name(note), lyrics.name(date))
  end)
end)

describe("line_at", function()
  local lines = lyrics.parse_lrc(DATE_NIGHT_LRC)

  it("waits before the first verse", function()
    assert.equal(0, lyrics.line_at(lines, 0.5))
  end)

  it("follows the verse Claire is singing", function()
    assert.equal(2, lyrics.line_at(lines, 6))
    assert.equal(4, lyrics.line_at(lines, 200))
  end)
end)

describe("sung", function()
  local lines = lyrics.parse_lrc(DATE_NIGHT_LRC)

  it("is halfway through Claire's verse halfway to the next one", function()
    assert.equal(0.5, lyrics.sung(lines, 1, 3.25, nil))
  end)

  it("stays between empty and full", function()
    assert.equal(0, lyrics.sung(lines, 2, 1, nil))
    assert.equal(1, lyrics.sung(lines, 2, 60, nil))
  end)

  it("closes the last verse at the end of the song", function()
    assert.equal(0.5, lyrics.sung(lines, 4, 13, 14))
  end)

  it("does not crawl through the long silence after Inde's last verse", function()
    assert.equal(1, lyrics.sung(lines, 4, 19, 300))
  end)

  it("gives nothing before the first verse", function()
    assert.equal(0, lyrics.sung(lines, 0, 0.5, nil))
  end)
end)
