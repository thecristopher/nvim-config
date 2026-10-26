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
