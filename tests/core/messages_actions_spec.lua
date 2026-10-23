local actions = require("core.messages.actions")

local repo = "/home/claire/terrasave"

describe("compose", function()
  it("fills the blank of a template", function()
    assert.equal("Be wary of Wesker", actions.compose("Be wary of %s", "Wesker"))
  end)

  it("capitalizes templates that open with the blank", function()
    assert.equal("Anniversary dinner ahead", actions.compose("%s ahead", "anniversary dinner"))
  end)

  it("writes nothing when Inde leaves the blank empty", function()
    assert.is_nil(actions.compose("Praise the %s!", "   "))
    assert.is_nil(actions.compose("Praise the %s!", nil))
  end)
end)

describe("relative", function()
  it("returns the path inside the repo", function()
    assert.equal("notes/love_letter.lua", actions.relative(repo, repo .. "/notes/love_letter.lua"))
  end)

  it("ignores a trailing slash on the repo", function()
    assert.equal("playlist.lua", actions.relative(repo .. "/", repo .. "/playlist.lua"))
  end)

  it("refuses files from Malenia's repo next door", function()
    assert.is_nil(actions.relative(repo, "/home/claire/terrasave_old/playlist.lua"))
  end)
end)

describe("put", function()
  it("leaves a message on a line", function()
    local store = actions.put({}, repo, "date.lua", 7, "Try kissing, but hole")
    assert.same({ { line = 7, text = "Try kissing, but hole" } }, actions.for_file(store, repo, "date.lua"))
  end)

  it("replaces the old message on the same line", function()
    local store = actions.put({}, repo, "date.lua", 7, "Be wary of Wesker")
    actions.put(store, repo, "date.lua", 7, "Praise the playlist!")
    assert.same({ { line = 7, text = "Praise the playlist!" } }, actions.for_file(store, repo, "date.lua"))
  end)
end)

describe("for_file", function()
  it("sorts Claire's notes to Inde by line", function()
    local store = actions.put({}, repo, "date.lua", 30, "Visions of dessert...")
    actions.put(store, repo, "date.lua", 4, "Time for flowers")
    assert.same({ 4, 30 }, vim.tbl_map(function(m) return m.line end, actions.for_file(store, repo, "date.lua")))
  end)

  it("returns nothing for a file without messages", function()
    assert.same({}, actions.for_file({}, repo, "empty.lua"))
  end)
end)

describe("erase", function()
  it("erases the message on a line and prunes the empty repo", function()
    local store, erased = actions.erase(actions.put({}, repo, "date.lua", 7, "Seek Malenia"), repo, "date.lua", 7)
    assert.is_true(erased)
    assert.same({}, store)
  end)

  it("reports when nothing was written on that line", function()
    local _, erased = actions.erase(actions.put({}, repo, "date.lua", 7, "Seek Malenia"), repo, "date.lua", 8)
    assert.is_false(erased)
  end)
end)

describe("replace", function()
  it("moves messages to the lines edits pushed them to", function()
    local store = actions.put({}, repo, "date.lua", 7, "Praise the playlist!")
    actions.replace(store, repo, "date.lua", { { line = 12, text = "Praise the playlist!" } })
    assert.same({ { line = 12, text = "Praise the playlist!" } }, actions.for_file(store, repo, "date.lua"))
  end)
end)

describe("list", function()
  it("lists every message in the repo by file then line", function()
    local store = actions.put({}, repo, "raccoon_city.lua", 1, "Behold, Leon!")
    actions.put(store, repo, "anniversary.lua", 9, "If only I had a ring...")
    actions.put(store, repo, "anniversary.lua", 2, "Time for roses")
    local entries = actions.list(store, repo)
    assert.same(
      { "anniversary.lua:2", "anniversary.lua:9", "raccoon_city.lua:1" },
      vim.tbl_map(function(e) return e.file .. ":" .. e.line end, entries)
    )
  end)
end)
