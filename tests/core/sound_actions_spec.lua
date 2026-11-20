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
    assert.equal(
      "door.aiff",
      actions.pick(files, "door", function()
        return 1
      end)
    )
  end)

  it("stays quiet for an event without a file", function()
    assert.is_nil(actions.pick(files, "merchant", function()
      return 1
    end))
  end)

  it("never plays the same variant of Malenia's death twice in a row", function()
    local first = function()
      return 1
    end
    assert.equal("died_2.mp3", actions.pick(files, "died", first, "died.wav"))
    assert.equal("died.wav", actions.pick(files, "died", first, "died_2.mp3"))
  end)

  it("replays the only door Claire has, there is nothing else to pick", function()
    assert.equal(
      "door.aiff",
      actions.pick(files, "door", function()
        return 1
      end, "door.aiff")
    )
  end)
end)

describe("channel", function()
  it("keeps every inventory sound on the HUD's channel", function()
    assert.equal("hud", actions.channel("hud_move"))
    assert.equal("moment", actions.channel("felled"))
  end)

  it("keeps Claire's tab and page turns on the inventory's own channel", function()
    for _, event in ipairs({ "hud_tab", "hud_page", "hud_menu", "hud_check", "hud_combine" }) do
      assert.equal("hud", actions.channel(event))
    end
  end)

  it("plays Malenia's saves among the moments", function()
    assert.equal("moment", actions.channel("save"))
  end)
end)

describe("arbitrate", function()
  it("plays Inde's banner when nothing else is sounding", function()
    assert.same({ true, false }, { actions.arbitrate("felled", nil) })
  end)

  it("cuts the last tick when Claire moves through the inventory again", function()
    assert.same({ true, true }, { actions.arbitrate("hud_move", "hud_select") })
  end)

  it("lets Malenia's death cut a boss theme short", function()
    assert.same({ true, true }, { actions.arbitrate("died", "boss") })
  end)

  it("keeps a zone chime quiet while Malenia is being felled", function()
    assert.same({ false, false }, { actions.arbitrate("zone", "felled") })
  end)

  it("lets a moment replace another of the same weight", function()
    assert.same({ true, true }, { actions.arbitrate("great", "felled") })
  end)

  it("lets the stamp on Inde's pushed love letter cut a yank short", function()
    assert.same({ true, true }, { actions.arbitrate("pushed", "yank") })
  end)

  it("keeps a yank quiet while the APPROVED stamp lands", function()
    assert.same({ false, false }, { actions.arbitrate("yank", "pushed") })
  end)
end)

describe("EVENTS", function()
  it("lists the phantom Malenia summons beside Inde", function()
    assert.is_true(vim.tbl_contains(actions.EVENTS, "phantom"))
  end)

  it("lists the zone Claire discovers on their date", function()
    assert.is_true(vim.tbl_contains(actions.EVENTS, "zone"))
  end)

  it("lists the continue that brings Malenia back to Inde's repo", function()
    assert.is_true(vim.tbl_contains(actions.EVENTS, "continue"))
  end)

  it("lists every inventory sound Claire hears while packing Inde's gift", function()
    for _, event in ipairs({ "hud_open", "hud_close", "hud_move", "hud_select", "hud_back" }) do
      assert.is_true(vim.tbl_contains(actions.EVENTS, event))
    end
  end)

  it("lists what Claire does at the desk: saving, yanking and the git chores", function()
    for _, event in ipairs({ "save", "yank", "branch", "pulled", "pushed", "stash", "unstash" }) do
      assert.is_true(vim.tbl_contains(actions.EVENTS, event))
    end
  end)

  it(
    "gives the Raccoon City safe room a sound for every event but the other worlds' travels",
    function()
      local folder = vim.fn.getcwd() .. "/sounds/resident_evil"
      local present = vim.fn.readdir(folder)
      local travels_elsewhere = { fog = true, curtain = true }
      for _, event in ipairs(actions.EVENTS) do
        if not travels_elsewhere[event] then
          assert.is_true(#actions.candidates(present, event) > 0, event .. " has no file")
        end
      end
    end
  )
end)

describe("debounce_ms", function()
  it("keeps up with Claire flipping through the inventory", function()
    assert.equal(60, actions.debounce_ms("hud_move"))
  end)

  it("lets Malenia's death toll only once", function()
    assert.equal(400, actions.debounce_ms("died"))
  end)
end)

describe("first_available", function()
  local files = { "summon.wav", "hud_open.wav", "grace.wav" }

  it("rings the bell when Malenia's folder has one", function()
    assert.equal("summon", actions.first_available(files, { "summon", "hud_open" }))
  end)

  it("falls back to the next event Claire's folder does have", function()
    assert.equal("hud_open", actions.first_available({ "hud_open.wav" }, { "summon", "hud_open" }))
  end)

  it("stays quiet when no event has a file", function()
    assert.is_nil(actions.first_available({ "grace.wav" }, { "summon", "hud_open" }))
  end)
end)

describe("command", function()
  it("plays every sound below full volume so nothing startles", function()
    assert.is_true(actions.VOLUME > 0 and actions.VOLUME < 1)
  end)

  it("uses afplay on macOS", function()
    local function only_afplay(name)
      return name == "afplay"
    end
    assert.same(
      { "afplay", "-v", tostring(actions.VOLUME), "/love/inde.wav" },
      actions.command("/love/inde.wav", only_afplay)
    )
  end)

  it("falls back to ffplay with no window", function()
    local function only_ffplay(name)
      return name == "ffplay"
    end
    assert.equal("ffplay", actions.command("/love/inde.wav", only_ffplay)[1])
  end)

  it("admits when nothing can play it", function()
    assert.is_nil(actions.command("/love/inde.wav", function()
      return false
    end))
  end)
end)

describe("player_line", function()
  it("asks the resident player for Jill's door on the moments' channel", function()
    assert.are.equal(
      "play moment 7 0.6 /sounds/resident_evil/door.wav\n",
      actions.player_line("moment", 7, "/sounds/resident_evil/door.wav")
    )
  end)
end)

describe("finished", function()
  it("reads every sound the player says is over, even two in one chunk", function()
    assert.are.same(
      { { channel = "hud", token = "3" }, { channel = "moment", token = "4" } },
      actions.finished("done hud 3\ndone moment 4\n")
    )
  end)

  it("ignores anything else the player prints", function()
    assert.are.same({}, actions.finished("warming up\n"))
  end)
end)

describe("needs_build", function()
  it("builds the player the first time Claire opens nvim", function()
    assert.is_true(actions.needs_build(100, nil))
  end)

  it("builds it again after its source changed", function()
    assert.is_true(actions.needs_build(200, 100))
  end)

  it("keeps the build that is newer than its source", function()
    assert.is_false(actions.needs_build(100, 200))
  end)
end)
