local actions = require("core.results.actions")

local function run(hours, saves, fixes)
  return { seconds = math.floor(hours * 3600), saves = saves, fixes = fixes }
end

describe("rank", function()
  it("gives Claire an S for a busy hour of fixes", function()
    assert.equal("S", actions.rank(run(1, 15, 20)))
  end)

  it("gives a steady afternoon an A", function()
    assert.equal("A", actions.rank(run(2, 30, 10)))
  end)

  it("gives a quiet session a D", function()
    assert.equal("D", actions.rank(run(3, 2, 0)))
  end)

  it("never lets a two minute sprint look like a marathon", function()
    assert.are_not.equal("S", actions.rank(run(0.04, 2, 1)))
  end)
end)

describe("duration", function()
  it("counts minutes under an hour", function()
    assert.equal("45m", actions.duration(45 * 60))
  end)

  it("shows hours and padded minutes past an hour", function()
    assert.equal("2h 05m", actions.duration(2 * 3600 + 5 * 60))
  end)
end)

describe("worth_saving", function()
  it("forgets a quick peek at a file", function()
    assert.is_false(actions.worth_saving({ seconds = 30 }))
  end)

  it("remembers a real run", function()
    assert.is_true(actions.worth_saving({ seconds = 600 }))
  end)
end)

describe("fixed", function()
  it("counts the errors that went away", function()
    assert.equal(2, actions.fixed(5, 3))
  end)

  it("never counts new errors as fixes", function()
    assert.equal(0, actions.fixed(1, 4))
  end)

  it("counts nothing the first time a buffer is read", function()
    assert.equal(0, actions.fixed(nil, 3))
  end)
end)

describe("summary", function()
  local last = { seconds = 2 * 3600 + 13 * 60, saves = 14, fixes = 9, rank = "A" }

  it("reads like the results screen Inde and Claire share", function()
    local words = { last_run = "Last run", rank = "Rank", saves = "saves", fixes = "fixes" }
    assert.equal(
      "Last run  ·  Rank A  ·  2h 13m  ·  14 saves  ·  9 fixes",
      actions.summary(words, last)
    )
  end)

  it("speaks the franchise's words for Malenia's last take", function()
    local words =
      { last_run = "Last take", rank = "Review", saves = "rehearsals", fixes = "retakes" }
    assert.equal(
      "Last take  ·  Review A  ·  2h 13m  ·  14 rehearsals  ·  9 retakes",
      actions.summary(words, last)
    )
  end)
end)

describe("active_after", function()
  it("counts the minute Claire spent writing Inde's love note", function()
    assert.equal(60000, actions.active_after(0, 1000, 61000))
  end)

  it("leaves out the night Malenia left the editor open", function()
    assert.equal(30000, actions.active_after(30000, 0, 8 * 3600 * 1000))
  end)

  it("counts a gap right at the limit as work", function()
    assert.equal(actions.IDLE_GAP_MS, actions.active_after(0, 0, actions.IDLE_GAP_MS))
  end)

  it("ignores a clock that did not move", function()
    assert.equal(500, actions.active_after(500, 2000, 2000))
  end)
end)
