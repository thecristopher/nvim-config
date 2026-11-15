local background = require("core.hud.background")

describe("get", function()
  before_each(function()
    background.forget()
  end)

  it("has nothing to show while Inde's letters are still on their way", function()
    assert.is_nil(background.get("letters", function() end))
  end)

  it("serves the letters from the cache once they arrived", function()
    local fetches = 0
    local fetch = function(done)
      fetches = fetches + 1
      done({ "dear claire" })
    end
    background.get("letters", fetch)
    assert.same({ "dear claire" }, background.get("letters", fetch))
    assert.equal(1, fetches)
  end)

  it("starts no second fetch while one is still running", function()
    local fetches = 0
    local fetch = function()
      fetches = fetches + 1
    end
    background.get("dates", fetch)
    background.get("dates", fetch)
    assert.equal(1, fetches)
  end)

  it("fetches again after forget", function()
    local fetches = 0
    local fetch = function(done)
      fetches = fetches + 1
      done({})
    end
    background.get("songs", fetch)
    background.forget()
    background.get("songs", fetch)
    assert.equal(2, fetches)
  end)
end)
