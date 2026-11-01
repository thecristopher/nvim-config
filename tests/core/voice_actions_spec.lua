local actions = require("core.voice.actions")

local love_notes = {
  "Claire saved Inde the seat behind her on the bike.",
  "Claire left Inde a note on the RPD typewriter.",
  "Claire booked dinner for their anniversary.",
}

describe("pick", function()
  it("lands on the first line at the start of the roll", function()
    assert.equal(love_notes[1], actions.pick(love_notes, 0, nil))
  end)

  it("lands on the last line at the end of the roll", function()
    assert.equal(love_notes[3], actions.pick(love_notes, 0.999, nil))
  end)

  it("never says Claire's last love note twice in a row", function()
    for _, roll in ipairs({ 0, 0.4, 0.999 }) do
      assert.are_not.equal(love_notes[1], actions.pick(love_notes, roll, love_notes[1]))
    end
  end)

  it("repeats the only line Malenia has rather than staying quiet", function()
    local promise = { "Malenia keeps her promise to Inde." }
    assert.equal(promise[1], actions.pick(promise, 0.5, promise[1]))
  end)

  it("says nothing when there are no lines", function()
    assert.is_nil(actions.pick({}, 0.5, nil))
    assert.is_nil(actions.pick(nil, 0.5, nil))
  end)
end)

describe("fill", function()
  it("writes the branch into Claire's line", function()
    assert.equal(
      "anniversary-playlist made it out clean.",
      actions.fill("{branch} made it out clean.", { branch = "anniversary-playlist" })
    )
  end)

  it("leaves a hole it has no value for", function()
    assert.equal("{boss} is down.", actions.fill("{boss} is down.", {}))
  end)

  it("leaves the line alone without values", function()
    assert.equal("All green, Inde.", actions.fill("All green, Inde.", nil))
  end)
end)

describe("line", function()
  local voices = { raccoon_city = { pushed = { "Keep the engine running for Inde." } } }

  it("finds what Claire says in Raccoon City when a push lands", function()
    assert.equal(
      "Keep the engine running for Inde.",
      actions.line(voices, "raccoon_city", "pushed", 0.5, nil)
    )
  end)

  it("stays quiet for a moment Claire has no line for", function()
    assert.is_nil(actions.line(voices, "raccoon_city", "boss_felled", 0.5, nil))
  end)

  it("stays quiet in a region with no voice yet, like a lab Wesker never opened", function()
    assert.is_nil(actions.line(voices, "umbrella_hq", "pushed", 0.5, nil))
  end)

  it("stays quiet in a franchise with no voices at all", function()
    assert.is_nil(actions.line(nil, "haligtree", "pushed", 0.5, nil))
  end)
end)

for _, franchise in ipairs({ "resident_evil", "elden_ring" }) do
  describe(franchise .. " voices", function()
    local lore = require("core.franchise.actions").lore(franchise)

    it("give every region more than one line for every moment", function()
      for _, region in ipairs(lore.regions) do
        for _, moment in ipairs(actions.MOMENTS) do
          local lines = lore.voices[region.name][moment]
          assert.is_true(#lines > 1, region.name .. "." .. moment)
        end
      end
    end)

    it("never use an em dash", function()
      for _, moments in pairs(lore.voices) do
        for _, lines in pairs(moments) do
          for _, line in ipairs(lines) do
            assert.is_nil(line:find("—", 1, true), line)
          end
        end
      end
    end)
  end)
end
