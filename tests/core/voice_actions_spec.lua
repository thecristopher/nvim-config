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

describe("pick with a memory", function()
  it("skips every love note Claire said lately while others remain", function()
    local lines = { "a", "b", "c", "d" }
    assert.equal("d", actions.pick(lines, 0, { "a", "b", "c" }))
  end)

  it("lets the oldest memory go when Malenia has few lines", function()
    assert.equal("a", actions.pick({ "a", "b" }, 0, { "b", "a" }))
  end)
end)

describe("remember", function()
  it("puts Inde's newest line first and keeps only a few", function()
    local recent = actions.remember({ "c", "b", "a", "z" }, "d")
    assert.same({ "d", "c", "b", "a" }, recent)
  end)

  it("never keeps the same line twice", function()
    assert.same({ "a", "b" }, actions.remember({ "b", "a" }, "a"))
  end)
end)

describe("admit", function()
  it("plays at once when nobody is speaking", function()
    assert.equal("play", actions.admit(nil, "map_opened"))
  end)

  it("lets a failed CI cut Claire while she talks about the push", function()
    assert.equal("play", actions.admit(actions.NORMAL, "ci_failed"))
  end)

  it("makes the push wait for Malenia to finish the commit", function()
    assert.equal("queue", actions.admit(actions.NORMAL, "pushed"))
  end)

  it("keeps the map quiet while Leon is speaking", function()
    assert.equal("drop", actions.admit(actions.NORMAL, "map_opened"))
  end)
end)

describe("enqueue", function()
  it("keeps the louder moment waiting over a newer quieter one", function()
    local waiting = actions.enqueue({ moment = "ci_failed" }, { moment = "pushed" })
    assert.equal("ci_failed", waiting.moment)
  end)

  it("lets the newest moment wait when it is as loud", function()
    local waiting = actions.enqueue({ moment = "committed" }, { moment = "pushed" })
    assert.equal("pushed", waiting.moment)
  end)
end)

describe("still_fresh", function()
  it("drops a moment that waited too long for Claire to finish", function()
    assert.is_true(actions.still_fresh(0, actions.QUEUE_TTL_MS))
    assert.is_false(actions.still_fresh(0, actions.QUEUE_TTL_MS + 1))
  end)
end)

describe("context", function()
  it("names a Friday evening in Inde's playlist repo", function()
    local vars = actions.context({ hour = 19, wday = 6 }, "anniversary-playlist")
    assert.same({ weekday = "Friday", daypart = "evening", repo = "anniversary playlist" }, vars)
  end)

  it("calls the small hours night", function()
    assert.equal("night", actions.context({ hour = 2, wday = 1 }).daypart)
  end)
end)

describe("linger", function()
  it("keeps a short line up as long as a written one", function()
    assert.equal(actions.SHOWN_MIN_MS - 1000, actions.linger(1000))
  end)

  it("leaves a moment to read after a long voice", function()
    assert.equal(actions.LINGER_MS, actions.linger(9000))
  end)
end)

describe("reading_ms", function()
  it("keeps Claire's short note up as long as any written line", function()
    assert.equal(actions.SHOWN_MIN_MS, actions.reading_ms("Te quiero, Inde."))
  end)

  it("gives Malenia's long love letter time to be read", function()
    local letter = string.rep("Inde, I would wait at the Haligtree for you. ", 4)
    assert.equal(vim.fn.strchars(letter) * actions.READ_MS_PER_CHAR, actions.reading_ms(letter))
  end)
end)

describe("dialogue_place", function()
  it("sits Claire's line right above the statusline", function()
    local place = actions.dialogue_place("Happy anniversary, Inde.", "Claire", 200, 50, 1)
    -- 50 rows, minus the statusline, the gap, the line and the frame
    assert.equal(50 - 1 - actions.DIALOGUE_GAP - 1 - 2, place.row)
    assert.equal(1, place.height)
  end)

  it("centers the box across the editor", function()
    local place = actions.dialogue_place("Happy anniversary, Inde.", "Claire", 200, 50, 1)
    assert.equal(math.floor((200 - place.width - 2) / 2), place.col)
  end)

  it("pads Malenia's line with a cell on each side", function()
    local line = "I wrote you a letter, Inde, sealed with scarlet rot and longing."
    local place = actions.dialogue_place(line, "Malenia", 200, 50, 1)
    assert.equal(" " .. line, place.lines[1])
    assert.equal(#line + 2, place.width)
  end)

  it("wraps a long love letter within its share of the editor", function()
    local letter = string.rep("Inde, you are my favorite playlist. ", 6)
    local place = actions.dialogue_place(letter, "Malenia", 100, 50, 1)
    assert.is_true(place.height > 1)
    assert.is_true(place.width <= math.floor(100 * actions.DIALOGUE_SHARE))
  end)

  it("never makes a short line narrower than the box's minimum", function()
    local place = actions.dialogue_place("Yes.", "Leon", 200, 50, 1)
    assert.equal(actions.DIALOGUE_MIN_WIDTH, place.width)
  end)

  it("leaves room for a name longer than the line", function()
    local name = "Claire Redfield of TerraSave, keeper of every love note"
    local place = actions.dialogue_place("Yes.", name, 200, 50, 1)
    assert.equal(#name + 4, place.width)
  end)
end)
