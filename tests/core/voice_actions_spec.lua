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

describe("MOMENTS", function()
  it("asks every region for the new moments Claire and Malenia speak at", function()
    for _, moment in ipairs({
      "committed",
      "pr_opened",
      "region_arrived",
      "morning",
      "conflicts_cleared",
      "woke",
    }) do
      assert.truthy(vim.tbl_contains(actions.MOMENTS, moment), moment)
    end
  end)
end)

describe("SPOKEN", function()
  it("lets Claire speak up when Inde opens the map, the bestiary or a PR draft", function()
    for _, moment in ipairs({
      "pr_drafting",
      "trial_started",
      "claude_asked",
      "map_opened",
      "bestiary_opened",
      "chronicle_opened",
      "message_written",
      "title_shown",
    }) do
      assert.truthy(vim.tbl_contains(actions.SPOKEN, moment), moment)
    end
  end)

  it("never asks Malenia to write a line for a moment only heard out loud", function()
    for _, moment in ipairs(actions.SPOKEN) do
      assert.is_false(vim.tbl_contains(actions.MOMENTS, moment), moment)
    end
  end)
end)

describe("morning_due", function()
  it("greets Inde on the first nvim of the day", function()
    assert.is_true(actions.morning_due("2026-11-15", "2026-11-16"))
    assert.is_true(actions.morning_due(nil, "2026-11-16"))
  end)

  it("says good morning to Claire only once a day", function()
    assert.is_false(actions.morning_due("2026-11-16\n", "2026-11-16"))
  end)
end)

describe("fill", function()
  it("writes the number of Inde's pull request into Malenia's line", function()
    assert.equal(
      "PR #42 stands before the judges.",
      actions.fill("PR #{number} stands before the judges.", { number = "42" })
    )
  end)

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

describe("clip", function()
  local voices = {
    raccoon_city = {
      spoken = {
        lesson_done = {
          lesson_done = "Umbrella is going down, Inde.",
          lesson_done_2 = "Another day behind us, Inde.",
        },
      },
    },
  }

  it("finds the clip Claire says when Inde's lesson ends, with its words", function()
    local clip, line = actions.clip(voices, "raccoon_city", "lesson_done", 0, nil)
    assert.equal("lesson_done", clip)
    assert.equal("Umbrella is going down, Inde.", line)
  end)

  it("never plays the clip Claire just said twice in a row", function()
    for _, roll in ipairs({ 0, 0.5, 0.999 }) do
      assert.equal(
        "lesson_done_2",
        (actions.clip(voices, "raccoon_city", "lesson_done", roll, "lesson_done"))
      )
    end
  end)

  it("stays quiet at a moment Claire has no clip for", function()
    assert.is_nil(actions.clip(voices, "raccoon_city", "solved", 0.5, nil))
  end)

  it("stays quiet in a region nobody recorded, like the Haligtree", function()
    assert.is_nil(actions.clip(voices, "haligtree", "lesson_done", 0.5, nil))
    assert.is_nil(actions.clip(nil, "haligtree", "lesson_done", 0.5, nil))
  end)
end)

describe("clip_file", function()
  local extensions = { mp3 = true, wav = true }

  it("finds Claire's morning clip whatever its extension", function()
    assert.equal(
      "morning.mp3",
      actions.clip_file({ "hint.mp3", "morning.mp3" }, "morning", extensions)
    )
  end)

  it("never takes a variant or a file that is not audio for the clip", function()
    assert.is_nil(actions.clip_file({ "morning_2.mp3", "morning.txt" }, "morning", extensions))
  end)
end)

for _, franchise in ipairs({ "resident_evil", "elden_ring" }) do
  describe(franchise .. " voices", function()
    local lore = require("core.franchise.actions").lore(franchise)

    it("keep every spoken clip on a known moment and beside its file", function()
      local moments = vim.list_extend(vim.deepcopy(actions.MOMENTS), actions.SPOKEN)
      for region, lines in pairs(lore.voices) do
        local folder = ("%s/sounds/%s/voices/%s"):format(vim.fn.getcwd(), franchise, region)
        local files = vim.fn.isdirectory(folder) == 1 and vim.fn.readdir(folder) or {}
        for moment, clips in pairs(lines.spoken or {}) do
          assert.truthy(vim.tbl_contains(moments, moment), region .. "." .. moment)
          for clip, line in pairs(clips) do
            assert.is_nil(line:find("—", 1, true), line)
            assert.truthy(
              actions.clip_file(files, clip, { mp3 = true, wav = true }),
              region .. "/" .. clip
            )
          end
        end
      end
    end)

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
