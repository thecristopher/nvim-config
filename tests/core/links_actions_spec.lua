local actions = require("core.links.actions")

local VITE_LOCAL = "  ➜  Local:   http://localhost:5173/"

describe("links_in", function()
  it("finds the portfolio Claire is building for Inde", function()
    assert.same(
      { { url = "http://localhost:5173/", first = 17, last = 38 } },
      actions.links_in(VITE_LOCAL)
    )
  end)

  it("leaves the period after Malenia's love letter link out", function()
    local links = actions.links_in("Read it at https://haligtree.co/letters/inde.")
    assert.equal("https://haligtree.co/letters/inde", links[1].url)
  end)

  it("finds nothing in a plain line", function()
    assert.same({}, actions.links_in("press h + enter to show help"))
  end)
end)

describe("url_at", function()
  it("opens the link Leon clicked on, past the multibyte arrow", function()
    assert.equal("http://localhost:5173/", actions.url_at(VITE_LOCAL, 30))
  end)

  it("opens nothing when the click lands on the label", function()
    assert.is_nil(actions.url_at(VITE_LOCAL, 8))
  end)
end)

describe("link_at", function()
  it("tells where the link Ada hovers starts and ends", function()
    assert.same(
      { url = "http://localhost:5173/", first = 17, last = 38 },
      actions.link_at(VITE_LOCAL, 17)
    )
  end)
end)

describe("last_url", function()
  it("picks the newest link of the anniversary playlist server", function()
    local lines = {
      "Playlist at http://localhost:3000/claire",
      "restarted",
      "Playlist at http://localhost:3001/inde",
      "",
    }
    assert.equal("http://localhost:3001/inde", actions.last_url(lines))
  end)

  it("returns nil when Wesker printed no links", function()
    assert.is_nil(actions.last_url({ "yarn run v1.22.22", "$ vite" }))
  end)
end)

describe("file references", function()
  it("finds the file and line Claude points Claire to", function()
    local links = actions.links_in("Fixed in `lua/core/btb/init.lua:42`, take a look")
    assert.same({ { path = "lua/core/btb/init.lua", row = 42, first = 11, last = 34 } }, links)
  end)

  it("reads the column after the line when there is one", function()
    local link = actions.link_at("see /tmp/inde.lua:7:3", 6)
    assert.same({ path = "/tmp/inde.lua", row = 7, col = 3, first = 5, last = 21 }, link)
  end)

  it("takes a bare file with no line too, like Malenia's README.md", function()
    assert.same(
      { path = "README.md", first = 8, last = 16 },
      actions.link_at("Update README.md.", 9)
    )
  end)

  it("leaves the paths inside a url to the url", function()
    local links = actions.links_in("PR at https://github.com/leon/raccoon/pull/27.diff")
    assert.equal(1, #links)
    assert.equal("https://github.com/leon/raccoon/pull/27.diff", links[1].url)
  end)

  it("skips an email, it is not a file Ada can open", function()
    assert.same({}, actions.links_in("write to ada@wong.com"))
  end)

  it("keeps the urls and the files in the order they were printed", function()
    local links = actions.links_in("plugins/ui.lua:63 and http://localhost:5173/")
    assert.equal("plugins/ui.lua", links[1].path)
    assert.equal("http://localhost:5173/", links[2].url)
  end)

  it("never offers a file as the last url", function()
    assert.is_nil(actions.last_url({ "Edited lua/core/links/init.lua:12" }))
  end)
end)

describe("resolve", function()
  it("puts a relative path under the terminal's folder", function()
    assert.equal("/repo/lua/a.lua", actions.resolve("lua/a.lua", "/repo"))
  end)

  it("keeps an absolute path", function()
    assert.equal("/tmp/claire.md", actions.resolve("/tmp/claire.md", "/repo"))
  end)

  it("expands the home folder", function()
    assert.equal(vim.fs.normalize("~/notes.md"), actions.resolve("~/notes.md", "/repo"))
  end)
end)
