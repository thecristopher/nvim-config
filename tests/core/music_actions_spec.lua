local actions = require("core.music.actions")

local CLAIRE_SONG = vim.json.encode({
  status = "ok",
  info = {
    name = "Anniversary Waltz",
    artistName = "Claire Redfield",
    albumName = "Notes for Inde",
    currentPlaybackTime = 61.5,
    durationInMillis = 193000,
    artwork = { url = "https://is1-ssl.mzstatic.com/image/thumb/terrasave/{w}x{h}bb.jpg" },
  },
})

describe("cider_command", function()
  it("asks Cider what is playing without a token when auth is off", function()
    local cmd = actions.cider_command("now-playing", "GET", nil)
    assert.same(
      { "curl", "-s", "--max-time", "1", "-X", "GET", actions.CIDER_URL .. "/now-playing" },
      cmd
    )
  end)

  it("sends Inde's token in both header spellings", function()
    local cmd = actions.cider_command("next", "POST", "inde-loves-claire")
    assert.is_true(vim.tbl_contains(cmd, "apptoken: inde-loves-claire"))
    assert.is_true(vim.tbl_contains(cmd, "apitoken: inde-loves-claire"))
    assert.equal(actions.CIDER_URL .. "/next", cmd[#cmd])
  end)
end)

describe("parse_cider_playing", function()
  it("tells Malenia's playlist is playing", function()
    assert.is_true(actions.parse_cider_playing('{"status":"ok","is_playing":true}'))
  end)

  it("tells it is paused", function()
    assert.is_false(actions.parse_cider_playing('{"status":"ok","is_playing":false}'))
  end)

  it("gives nil when Cider is closed or answers garbage", function()
    assert.is_nil(actions.parse_cider_playing(nil))
    assert.is_nil(actions.parse_cider_playing(""))
    assert.is_nil(actions.parse_cider_playing("Unauthorized"))
  end)
end)

describe("parse_cider_track", function()
  it("reads the song Claire picked for their date", function()
    assert.same({
      title = "Anniversary Waltz",
      artist = "Claire Redfield",
      album = "Notes for Inde",
      cover = "https://is1-ssl.mzstatic.com/image/thumb/terrasave/300x300bb.jpg",
      playing = true,
      position = 61.5,
      duration = 193,
    }, actions.parse_cider_track(CLAIRE_SONG, true))
  end)

  it("leaves the cover out when the song has no artwork", function()
    local track = actions.parse_cider_track('{"status":"ok","info":{"name":"Love Note"}}', false)
    assert.is_nil(track.cover)
    assert.equal("", track.album)
  end)

  it("gives nil when nothing is loaded", function()
    assert.is_nil(actions.parse_cider_track('{"status":"ok","info":{}}', false))
    assert.is_nil(actions.parse_cider_track(nil, false))
  end)
end)

describe("music_control_command", function()
  it("skips the song only when Music is already open", function()
    local cmd = actions.music_control_command("next")
    assert.equal("osascript", cmd[1])
    assert.equal(
      'if application "Music" is running then tell application "Music" to next track',
      cmd[3]
    )
  end)

  it("refuses a control Wesker made up", function()
    assert.is_nil(actions.music_control_command("self_destruct"))
  end)
end)

describe("parse_music", function()
  it("reads the love song Malenia left playing", function()
    assert.same({
      title = "Scarlet Bloom",
      artist = "Malenia",
      album = "Haligtree Serenades",
      playing = true,
      position = 42.25,
      duration = 215,
    }, actions.parse_music("playing\t42.25\t215\tScarlet Bloom\tMalenia\tHaligtree Serenades\n"))
  end)

  it("knows when the song is paused", function()
    assert.is_false(actions.parse_music("paused\t1\t215\tScarlet Bloom\tMalenia\t").playing)
  end)

  it("reads the position with a decimal comma, the way a Spanish Mac writes it", function()
    local track = actions.parse_music("playing\t12,5\t180,75\tCarta para Inde\tClaire Redfield\t")
    assert.equal(12.5, track.position)
    assert.equal(180.75, track.duration)
  end)

  it("gives nil when Music is closed or stopped", function()
    assert.is_nil(actions.parse_music("closed\n"))
    assert.is_nil(actions.parse_music("stopped\n"))
    assert.is_nil(actions.parse_music(nil))
  end)
end)

describe("label", function()
  it("shows artist and title with the playing icon", function()
    local track = { title = "Shared Playlist", artist = "Inde Navarrete", playing = true }
    assert.equal("󰎈 Inde Navarrete · Shared Playlist", actions.label(track, 40))
  end)

  it("shows the pause icon and leaves the artist out when there is none", function()
    assert.equal(
      "󰏤 Love Note",
      actions.label({ title = "Love Note", artist = "", playing = false }, 40)
    )
  end)

  it("cuts a long title so the statusline keeps its room", function()
    local track = { title = "A Very Long Song For Claire", artist = "Leon", playing = true }
    assert.equal("󰎈 Leon · A Very…", actions.label(track, 14))
  end)

  it("stays empty when nothing plays", function()
    assert.equal("", actions.label(nil, 40))
  end)
end)

describe("cover_url", function()
  it("fills the size Apple Music leaves open", function()
    assert.equal("https://art/300x300bb.jpg", actions.cover_url("https://art/{w}x{h}bb.jpg", 300))
  end)

  it("keeps a URL that already has its size", function()
    assert.equal("https://art/640x640sr.jpg", actions.cover_url("https://art/640x640sr.jpg", 300))
  end)
end)

describe("url_extension", function()
  it("reads the extension of Claire's cover", function()
    assert.equal("png", actions.url_extension("https://art/claire.PNG"))
  end)

  it("falls back to jpg when the URL does not say", function()
    assert.equal("jpg", actions.url_extension("https://art/cover"))
  end)
end)

describe("cover_extension", function()
  it("names the formats Music reports", function()
    assert.equal("png", actions.cover_extension("«class PNG »"))
    assert.equal("jpg", actions.cover_extension("JPEG picture"))
  end)

  it("gives nil when the song has no cover", function()
    assert.is_nil(actions.cover_extension(""))
    assert.is_nil(actions.cover_extension(nil))
  end)
end)

describe("music_cover_command", function()
  it("writes the cover where it is told, with quotes escaped", function()
    local script = actions.music_cover_command('/tmp/inde "mixtape"')[3]
    assert.truthy(script:find('POSIX file "/tmp/inde \\"mixtape\\""', 1, true))
  end)
end)

describe("cover_name", function()
  it("shares one cover for every song of Malenia's album", function()
    local first = { artist = "Malenia", album = "Haligtree Serenades", title = "Scarlet Bloom" }
    local second = { artist = "Malenia", album = "Haligtree Serenades", title = "Waterfowl Dance" }
    assert.equal(actions.cover_name(first), actions.cover_name(second))
  end)

  it("tells singles apart by title when there is no album", function()
    local note = { artist = "Inde Navarrete", album = "", title = "Love Note" }
    local date = { artist = "Inde Navarrete", album = "", title = "Date Night" }
    assert.are_not.equal(actions.cover_name(note), actions.cover_name(date))
  end)
end)
