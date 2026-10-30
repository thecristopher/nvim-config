local actions = require("core.conflicts.actions")

describe("count_markers", function()
  it("counts every conflict Leon left in the file", function()
    local lines = {
      "<<<<<<< HEAD",
      "local date = 'Friday'",
      "=======",
      "local date = 'Saturday'",
      ">>>>>>> claire/anniversary",
      "<<<<<<<",
      "x",
      ">>>>>>>",
    }
    assert.equal(2, actions.count_markers(lines))
  end)

  it("ignores lines that only look like markers", function()
    assert.equal(0, actions.count_markers({ "-- <<<<<<< not a conflict", "<<<<<<<<<< banner" }))
  end)
end)

describe("unmerged_files", function()
  it("counts the conflicted files git listed", function()
    assert.equal(2, actions.unmerged_files("love_note.lua\nplaylist.lua\n"))
    assert.equal(0, actions.unmerged_files(""))
  end)
end)

describe("boss_name", function()
  local words = { boss = "Godrick the Grafted", left = "%d files still grafted" }

  it("says how many files Malenia still has to ungraft", function()
    assert.equal("Godrick the Grafted  ·  3 files still grafted", actions.boss_name(words, 3))
  end)

  it("keeps the name alone on the last file", function()
    assert.equal("Godrick the Grafted", actions.boss_name(words, 1))
  end)
end)
