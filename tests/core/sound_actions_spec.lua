local actions = require("core.sound.actions")

local files = { "died.wav", "died_2.mp3", "door.aiff", "notes.txt", "died_story.wav" }

describe("candidates", function()
  it("finds the event and its numbered variants", function()
    local found = actions.candidates(files, "died")
    table.sort(found)
    assert.same({ "died.wav", "died_2.mp3" }, found)
  end)

  it("ignores files that are not audio", function()
    assert.same({}, actions.candidates({ "title.txt" }, "title"))
  end)
end)

describe("pick", function()
  it("plays the door Jill pushes open", function()
    assert.equal("door.aiff", actions.pick(files, "door", function() return 1 end))
  end)

  it("stays quiet for an event without a file", function()
    assert.is_nil(actions.pick(files, "merchant", function() return 1 end))
  end)
end)

describe("command", function()
  it("uses afplay on macOS", function()
    local function only_afplay(name) return name == "afplay" end
    assert.same({ "afplay", "/love/inde.wav" }, actions.command("/love/inde.wav", only_afplay))
  end)

  it("falls back to ffplay with no window", function()
    local function only_ffplay(name) return name == "ffplay" end
    assert.equal("ffplay", actions.command("/love/inde.wav", only_ffplay)[1])
  end)

  it("admits when nothing can play it", function()
    assert.is_nil(actions.command("/love/inde.wav", function() return false end))
  end)
end)
