local history = require("core.music.actions.history")

local function song(title, artist)
  return { title = title, artist = artist }
end

describe("record", function()
  it("counts every time Claire and Inde put their song on", function()
    local store = {}
    history.record(store, "2026", "the cure|lovesong", song("Lovesong", "The Cure"))
    history.record(store, "2026", "the cure|lovesong", song("Lovesong", "The Cure"))
    assert.equal(2, store["2026"]["the cure|lovesong"].plays)
  end)

  it("keeps each year's plays apart", function()
    local store = history.record({}, "2025", "a|b", song("B", "A"))
    history.record(store, "2026", "a|b", song("B", "A"))
    assert.equal(1, store["2025"]["a|b"].plays)
    assert.equal(1, store["2026"]["a|b"].plays)
  end)
end)

describe("top", function()
  it("finds the song Malenia played the most that year", function()
    local store = {
      ["2026"] = {
        ["a|one"] = { title = "One", artist = "A", plays = 3 },
        ["b|two"] = { title = "Two", artist = "B", plays = 9 },
      },
    }
    assert.same({ title = "Two", artist = "B", plays = 9 }, history.top(store, "2026"))
  end)

  it("has no song for a silent year", function()
    assert.is_nil(history.top({}, "2026"))
  end)
end)
