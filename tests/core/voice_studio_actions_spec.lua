local actions = require("core.voice.studio.actions")
local budget = require("core.voice.studio.actions.budget")
local fish = require("core.voice.studio.actions.fish")
local writer = require("core.voice.studio.actions.writer")

local date_night = "[warm] Dinner's on me tonight, <emphasis>Inde.</emphasis> [break] I'm driving."

describe("plain", function()
  it("shows Claire's words without her direction or tags", function()
    assert.equal("Dinner's on me tonight, Inde. I'm driving.", actions.plain(date_night))
  end)

  it("leaves a line without markup alone", function()
    assert.equal("Malenia keeps her promise.", actions.plain("Malenia keeps her promise."))
  end)
end)

describe("for_model", function()
  it("keeps Claire's take whole for Drama 3", function()
    assert.equal(date_night, actions.for_model(date_night, "drama-3"))
  end)

  it("turns paired tags into cues before the words for the free model", function()
    assert.equal(
      "[warm] Dinner's on me tonight, [emphasis] Inde. [break] I'm driving.",
      actions.for_model(date_night, "s2.1-pro-free")
    )
  end)

  it("whispers Malenia's vow on the free model too", function()
    assert.equal(
      "Rest. [whispering] Only for you.",
      actions.for_model("Rest. <whisper>Only for you.</whisper>", "s2.1-pro-free")
    )
  end)
end)

describe("speakable_branch", function()
  it("drops the prefix and the ticket key from Inde's branch", function()
    assert.equal(
      "anniversary playlist",
      actions.speakable_branch("feature/SPLT-42-anniversary-playlist")
    )
  end)

  it("reads a plain branch as words", function()
    assert.equal("love notes", actions.speakable_branch("love_notes"))
  end)
end)

describe("pool", function()
  it("joins Claire's script takes and fresh ones, filling the branch", function()
    local lines = actions.pool({ "Pushed {branch}." }, { "Ride's not over." }, { branch = "dates" })
    assert.same({ "Pushed dates.", "Ride's not over." }, lines)
  end)

  it("leaves out a take whose hole Malenia has no value for", function()
    assert.same({ "It is sent." }, actions.pool({ "{boss} falls.", "It is sent." }, nil, nil))
  end)

  it("never lists the same take twice", function()
    assert.same({ "All green." }, actions.pool({ "All green." }, { "All green." }, nil))
  end)

  it("marks the takes that name Inde's push as only worth saying now", function()
    local _, eventful = actions.pool(
      { "Pushed {branch}.", "Happy {weekday}, Inde." },
      nil,
      { branch = "love notes", weekday = "Friday" },
      "pushed"
    )
    assert.is_true(eventful["Pushed love notes."])
    assert.is_nil(eventful["Happy Friday, Inde."])
  end)

  it("remembers the take each of Claire's lines came from", function()
    local _, _, origin = actions.pool({ "Pushed {branch}." }, nil, { branch = "dates" }, "pushed")
    assert.equal("Pushed {branch}.", origin["Pushed dates."])
  end)
end)

describe("written", function()
  it("turns Malenia's takes into words to read when she cannot be heard", function()
    assert.same(
      { "Rise. Again.", "Kneel, Inde." },
      actions.written({ "[firm] Rise. [break] Again." }, { "<soft>Kneel, Inde.</soft>" }, nil)
    )
  end)
end)

describe("without", function()
  it("leaves out the takes Inde banned from Claire's role", function()
    local kept = actions.without({ morning = { "Coffee?", "Rise and shine." } }, { "Coffee?" })
    assert.same({ "Rise and shine." }, kept.morning)
  end)
end)

describe("holes", function()
  it("lets Leon name the branch at a push and the day anywhere", function()
    assert.same({ "branch", "weekday", "daypart", "repo" }, actions.holes("pushed"))
    assert.same({ "weekday", "daypart", "repo" }, actions.holes("morning"))
  end)
end)

describe("on_time", function()
  it("plays Claire's take while the moment still matters, and not after", function()
    assert.is_true(actions.on_time(actions.LATE_MS))
    assert.is_false(actions.on_time(actions.LATE_MS + 1))
  end)
end)

describe("cache_name", function()
  it("caches Claire's take apart per model", function()
    local paid = actions.cache_name("drama-3", date_night)
    local free = actions.cache_name("s2.1-pro-free", date_night)
    assert.truthy(paid:match("^drama%-3%-%x+%-%d+%.mp3$"))
    assert.are_not.equal(paid, free)
  end)
end)

describe("choose", function()
  local lines = { "Heard before.", "Never heard." }
  local cached = { ["Heard before."] = "/voices/claire/heard.mp3" }

  it("plays a cached take at once and voices the unheard one behind it", function()
    local take, voice_first, prefetch =
      actions.choose(lines, cached, { roll = 0, fresh_roll = 0, can_voice = true })
    assert.equal("Heard before.", take)
    assert.is_false(voice_first)
    assert.equal("Never heard.", prefetch)
  end)

  it("waits on the network for a take that names Inde's push right now", function()
    local take, voice_first, prefetch = actions.choose(lines, cached, {
      roll = 0,
      fresh_roll = 0,
      can_voice = true,
      eventful = { ["Never heard."] = true },
    })
    assert.equal("Never heard.", take)
    assert.is_true(voice_first)
    assert.is_nil(prefetch)
  end)

  it("never prefetches while the studio is local", function()
    local _, _, prefetch =
      actions.choose(lines, cached, { roll = 0, fresh_roll = 0, can_voice = false })
    assert.is_nil(prefetch)
  end)

  it("plays a cached take the rest of the time", function()
    local take, voice_first =
      actions.choose(lines, cached, { roll = 0, fresh_roll = 0.9, can_voice = true })
    assert.equal("Heard before.", take)
    assert.is_false(voice_first)
  end)

  it("only plays what is cached when the studio is local", function()
    local take, voice_first =
      actions.choose(lines, cached, { roll = 0, fresh_roll = 0, can_voice = false })
    assert.equal("Heard before.", take)
    assert.is_false(voice_first)
  end)

  it("voices a take when Malenia has nothing cached at all", function()
    local _, voice_first = actions.choose(
      lines,
      {},
      { roll = 0, fresh_roll = 0.9, can_voice = true }
    )
    assert.is_true(voice_first)
  end)

  it("stays quiet with nothing cached and no way to voice", function()
    assert.is_nil((actions.choose(lines, {}, { roll = 0, fresh_roll = 0, can_voice = false })))
  end)
end)

describe("next_to_bake", function()
  local takes = { morning = { "Morning, Inde.", "Coffee first." }, pushed = { "Pushed {branch}." } }

  it("bakes Claire's script in order, skipping what already has paid audio", function()
    local take = actions.next_to_bake({ "morning", "pushed" }, takes, {}, function(text)
      return text == "Morning, Inde."
    end)
    assert.equal("Coffee first.", take)
  end)

  it("leaves takes with holes for the moment they happen", function()
    local take = actions.next_to_bake({ "pushed" }, takes, {}, function()
      return false
    end)
    assert.is_nil(take)
  end)

  it("bakes fresh takes once the script is done", function()
    local take = actions.next_to_bake(
      { "morning" },
      takes,
      { morning = { "A love note." } },
      function(text)
        return text ~= "A love note."
      end
    )
    assert.equal("A love note.", take)
  end)
end)

describe("clip_name", function()
  it("names Claire's first take after the moment and the second with a number", function()
    assert.equal("morning", actions.clip_name("morning", 1))
    assert.equal("morning_2", actions.clip_name("morning", 2))
  end)
end)

describe("recorded", function()
  local takes = { morning = { "Morning, Inde.", "Coffee first." }, woke = { "You're back." } }
  local extensions = { mp3 = true }

  it("finds the script takes Claire recorded by hand in the repo", function()
    local found =
      actions.recorded(takes, { "morning.mp3", "morning_2.mp3", "notes.txt" }, extensions)
    assert.equal("morning.mp3", found["Morning, Inde."])
    assert.equal("morning_2.mp3", found["Coffee first."])
    assert.is_nil(found["You're back."])
  end)
end)

describe("prune_plan", function()
  local month = 30 * 86400
  local live = { ["drama-3-aaa-10.mp3"] = true, ["s2.1-pro-free-aaa-10.mp3"] = true }

  it("deletes Malenia's free take once her paid one exists", function()
    local files = {
      { name = "drama-3-aaa-10.mp3", age_s = 10 },
      { name = "s2.1-pro-free-aaa-10.mp3", age_s = 10 },
    }
    assert.same({ "s2.1-pro-free-aaa-10.mp3" }, actions.prune_plan(files, live, month))
  end)

  it("keeps a branch's take nobody can name until it is a month old", function()
    local files = { { name = "drama-3-bbb-20.mp3", age_s = 3600 } }
    assert.same({}, actions.prune_plan(files, live, month))
  end)

  it("deletes a take nobody says once it is older than a month", function()
    local files = { { name = "drama-3-bbb-20.mp3", age_s = month + 1 } }
    assert.same({ "drama-3-bbb-20.mp3" }, actions.prune_plan(files, live, month))
  end)

  it("keeps an old take Claire still says", function()
    local files = { { name = "drama-3-aaa-10.mp3", age_s = month * 3 } }
    assert.same({}, actions.prune_plan(files, live, month))
  end)
end)

describe("coverage", function()
  it("counts how much of Malenia's role is voiced", function()
    local voiced, total = actions.coverage(
      { solved = { "A clean strike.", "Rise." }, boss_felled = { "{boss} falls." } },
      { solved = { "Kneel." } },
      function(text)
        return text == "Rise."
      end
    )
    assert.equal(1, voiced)
    assert.equal(3, total)
  end)
end)

describe("budget", function()
  local limits = budget.limits()
  local today = budget.rollover(nil, "2026-11-27")

  it("starts Inde's day with nothing spent and the studio live", function()
    assert.equal(0, today.spent)
    assert.equal("live", today.mode)
  end)

  it("starts the spend over on a new day but keeps the balance", function()
    local next_day = budget.rollover({ day = "2026-11-26", spent = 0.4, balance = 4 }, "2026-11-27")
    assert.equal(0, next_day.spent)
    assert.equal(4, next_day.balance)
  end)

  it("lets Drama 3 voice Claire's take while the day has room", function()
    assert.equal(budget.PAID, budget.model(today, 120, limits))
  end)

  it("falls back to the free model once the daily cap is reached", function()
    local spent = vim.tbl_extend("force", today, { spent = limits.daily })
    assert.equal(budget.FREE, budget.model(spent, 120, limits))
  end)

  it("falls back when the balance would dig below the floor", function()
    local low = vim.tbl_extend("force", today, { balance = limits.floor })
    assert.is_false((budget.paid_allowed(low, 120, limits)))
  end)

  it("falls back for the rest of the day once the account is out of credit", function()
    local broke = vim.tbl_extend("force", today, { broke = today.day })
    local allowed, reason = budget.paid_allowed(broke, 120, limits)
    assert.is_false(allowed)
    assert.equal("out of credit", reason)
  end)

  it("writes what Malenia's take cost into the day, the month and the balance", function()
    local after = budget.spend(vim.tbl_extend("force", today, { balance = 5 }), 1000)
    assert.equal(budget.cost(1000), after.spent)
    assert.equal(budget.cost(1000), after.month_spent)
    assert.equal(5 - budget.cost(1000), after.balance)
  end)

  it("asks Claude for fresh takes only a few times a day", function()
    assert.is_true(budget.writer_due(today, limits))
    assert.is_false(
      budget.writer_due(vim.tbl_extend("force", today, { writes = limits.writes }), limits)
    )
  end)

  it("takes the config's cap over the default", function()
    assert.equal(1, budget.limits({ daily = 1 }).daily)
  end)
end)

describe("fish", function()
  it("asks for Claire's take as a small mp3 in her voice", function()
    local body = vim.json.decode(fish.body("Hi, Inde.", "claire-voice"))
    assert.equal("Hi, Inde.", body.text)
    assert.equal("claire-voice", body.reference_id)
    assert.equal(fish.BITRATE, body.mp3_bitrate)
  end)

  it("sends the model as a header and the body on stdin", function()
    local command = fish.tts_command("key", "drama-3", "/tmp/take.mp3")
    assert.truthy(vim.tbl_contains(command, "model: drama-3"))
    assert.truthy(vim.tbl_contains(command, "@-"))
  end)

  it("reads a real take as ok, a 402 as broke and the rest as failed", function()
    assert.equal("ok", fish.outcome(0, "200", 30000))
    assert.equal("broke", fish.outcome(0, "402", 40))
    assert.equal("failed", fish.outcome(0, "200", 40))
    assert.equal("failed", fish.outcome(6, "000", 0))
  end)

  it("reads the balance of Inde's wallet", function()
    assert.equal(5.99147, fish.balance('{"credit":"5.99147","cumulative_top_up":"5"}'))
    assert.is_nil(fish.balance("not json"))
  end)
end)

describe("writer", function()
  local sheet = "# Voices\n\n## Claire Redfield\n\nShort and direct.\n\n## Leon S. Kennedy\n\nDry."

  it("finds Claire's section of the voice sheet by her first name", function()
    assert.equal("## Claire Redfield\n\nShort and direct.\n", writer.sheet_section(sheet, "Claire"))
  end)

  it("finds no section for a character the sheet never wrote", function()
    assert.is_nil(writer.sheet_section(sheet, "Wesker"))
  end)

  it("writes next for the moments with the fewest fresh takes, in script order", function()
    local moments = writer.moments_to_write(
      { "morning", "pushed", "woke" },
      { morning = { "a", "b" }, woke = { "c" } },
      2
    )
    assert.same({ "pushed", "woke" }, moments)
  end)

  it("tells Claude who speaks, what happened and what was already said", function()
    local prompt = writer.prompt({
      character = "Malenia",
      world = "Elphael",
      sheet = "## Malenia\nSolemn.",
      moments = { "boss_felled" },
      takes = { boss_felled = { "Radahn falls." } },
      fresh = {},
    })
    assert.truthy(prompt:find("Malenia (Elphael)", 1, true))
    assert.truthy(prompt:find("he fixed every error and the boss fell", 1, true))
    assert.truthy(prompt:find("{boss}", 1, true))
    assert.truthy(prompt:find("Already said: Radahn falls.", 1, true))
  end)

  it("asks Claude for several candidates and names the shared holes", function()
    local prompt = writer.prompt({
      character = "Claire",
      world = "Raccoon City",
      moments = { "morning" },
      takes = {},
      fresh = {},
      banned = { "Rise and grind, Inde." },
    })
    assert.truthy(prompt:find("array of " .. writer.CANDIDATES, 1, true))
    assert.truthy(prompt:find("{weekday}", 1, true))
    assert.truthy(prompt:find("- Rise and grind, Inde.", 1, true))
  end)

  it("keeps the first of Malenia's candidates that passes the checks", function()
    local answer = '{"morning": ["[a] [b] Too many directions.", "[soft] Morning, Inde."]}'
    assert.same({ morning = "[soft] Morning, Inde." }, writer.parse(answer, { "morning" }))
  end)

  it("throws away a candidate that paraphrases a take Claire already has", function()
    local known = { morning = { "[warm] Coffee is ready, Inde." } }
    local answer = '{"morning": ["[soft] Inde, coffee is ready."]}'
    assert.same({}, writer.parse(answer, { "morning" }, known))
  end)

  it("keeps one take per moment asked from Claude's answer, even inside a code fence", function()
    local answer = '```json\n{"morning": "[warm] Morning, Inde.", "woke": "x", "pushed": ""}\n```'
    assert.same(
      { morning = "[warm] Morning, Inde." },
      writer.parse(answer, { "morning", "pushed" })
    )
  end)

  it("throws away a take with an em dash", function()
    assert.same({}, writer.parse('{"morning": "Morning — Inde."}', { "morning" }))
  end)

  it("finds nothing in an answer that is not JSON", function()
    assert.same({}, writer.parse("Sorry, I can't.", { "morning" }))
  end)

  it("keeps only the newest fresh takes per moment", function()
    local fresh = { morning = { "1", "2", "3", "4", "5", "6" } }
    local merged = writer.merge(fresh, { morning = "7" })
    assert.same({ "2", "3", "4", "5", "6", "7" }, merged.morning)
  end)

  it("lets a take nobody voiced go before one Inde paid for", function()
    local fresh = { morning = { "1", "2", "3", "4", "5", "6" } }
    local merged = writer.merge(fresh, { morning = "7" }, function(take)
      return take == "1"
    end)
    assert.same({ "1", "3", "4", "5", "6", "7" }, merged.morning)
  end)

  it("never lets an import bring back a take Inde banned", function()
    local joined = writer.join(
      {},
      { ["elden_ring/haligtree"] = { solved = { "Rise.", "Kneel." } } },
      { ["elden_ring/haligtree"] = { "Rise." } }
    )
    assert.same({ "Kneel." }, joined["elden_ring/haligtree"].solved)
  end)

  it("joins an imported library into Malenia's without repeating a take", function()
    local joined = writer.join(
      { ["elden_ring/haligtree"] = { solved = { "Rise." } } },
      { ["elden_ring/haligtree"] = { solved = { "Rise.", "Kneel." } } }
    )
    assert.same({ "Rise.", "Kneel." }, joined["elden_ring/haligtree"].solved)
  end)
end)

for _, franchise in ipairs({ "elden_ring", "resident_evil", "elizabeth" }) do
  describe(franchise .. " script", function()
    local lore = require("core.franchise.actions").lore(franchise)
    local voice = require("core.voice.actions")
    local moments = vim.list_extend(vim.deepcopy(voice.MOMENTS), voice.SPOKEN)
    local named =
      { pushed = "branch", pr_opened = "number", boss_felled = "boss", morning = "weekday" }

    it("gives every role at least two takes for every moment, without em dashes", function()
      for region, role in pairs(lore.script) do
        for _, moment in ipairs(moments) do
          local takes = role.takes[moment]
          assert.is_true((takes and #takes or 0) >= 2, region .. "." .. moment)
          for _, take in ipairs(takes) do
            assert.is_nil(take:find("—", 1, true), take)
          end
        end
      end
    end)

    it("uses only holes each moment can fill, and markup the studio reads", function()
      local check = require("core.voice.studio.actions.check")
      for region, role in pairs(lore.script) do
        for moment, takes in pairs(role.takes) do
          for _, take in ipairs(takes) do
            assert.is_true(check.holes_ok(take, moment), region .. "." .. moment .. ": " .. take)
          end
        end
      end
    end)

    it(
      "names what happened in a third take at a push, a PR, a felled boss and the morning",
      function()
        for region, role in pairs(lore.script) do
          for moment, hole in pairs(named) do
            local takes = table.concat(role.takes[moment], "\n")
            assert.truthy(takes:find("{" .. hole .. "}", 1, true), region .. "." .. moment)
          end
        end
      end
    )

    it("casts only regions the franchise has", function()
      local regions = {}
      for _, region in ipairs(lore.regions) do
        regions[region.name] = true
      end
      for region in pairs(lore.script) do
        assert.truthy(regions[region], region)
      end
    end)
  end)
end

describe("check", function()
  local check = require("core.voice.studio.actions.check")

  it("takes Malenia's direction first, a break and one closed tag", function()
    assert.is_true(check.markup_ok("[low] Rise. [break] <whisper>Inde waits.</whisper>"))
  end)

  it("refuses a direction in the middle of Claire's line", function()
    assert.is_false(check.markup_ok("Pushed. [grinning] Let's ride."))
  end)

  it("refuses a tag left open or one the studio cannot voice", function()
    assert.is_false(check.markup_ok("<whisper>Inde, come here."))
    assert.is_false(check.markup_ok("<shout>Inde!</shout>"))
  end)

  it("refuses two shaped words in one of Leon's lines", function()
    assert.is_false(check.markup_ok("<soft>Easy</soft>, <emphasis>Inde</emphasis>."))
  end)

  it("lets the day name any moment but the branch only a push", function()
    assert.is_true(check.holes_ok("Happy {weekday}, Inde.", "solved"))
    assert.is_false(check.holes_ok("Solved on {branch}.", "solved"))
    assert.is_true(check.holes_ok("{branch} is out.", "pushed"))
  end)

  it("hears the same words in another order as the same line", function()
    assert.equal(1, check.similarity("Coffee is ready, Inde.", "[soft] Inde, coffee is ready."))
  end)

  it("keeps a take that says something new to Claire", function()
    assert.is_true(check.new_enough("Your playlist is pushed.", { "Morning, Inde." }))
  end)

  it("refuses a take longer than the prompt allows", function()
    local long = ("love "):rep(check.MAX_WORDS + 1)
    assert.is_false(check.usable(long, "morning", {}))
  end)
end)
