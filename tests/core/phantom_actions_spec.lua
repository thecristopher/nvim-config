local actions = require("core.phantom.actions")

local LEON_BLAME = {
  "4f9c2a1b8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b 12 12 1",
  "author Leon Kennedy",
  "author-mail <leon@rpd.gov>",
  "author-time 1700000000",
  "author-tz -0700",
  "summary Fix null session crash before the DB lookup",
  "filename lua/core/rpd.lua",
  "\tlocal session = nil",
}

describe("parse_porcelain", function()
  it("reads who wrote the line, when and why", function()
    local info = actions.parse_porcelain(LEON_BLAME)
    assert.equal("Leon Kennedy", info.author)
    assert.equal("leon@rpd.gov", info.mail)
    assert.equal(1700000000, info.time)
    assert.equal("Fix null session crash before the DB lookup", info.summary)
  end)

  it("marks a line Claire has not committed yet as unwritten", function()
    local info = actions.parse_porcelain({ "0000000000000000000000000000000000000000 3 3 1", "author Not Committed Yet" })
    assert.is_true(info.unwritten)
  end)

  it("gives up on output that is not blame", function()
    assert.is_nil(actions.parse_porcelain({ "fatal: no such path" }))
    assert.is_nil(actions.parse_porcelain({}))
  end)
end)

describe("relative_time", function()
  it("says moments ago for a fresh line", function()
    assert.equal("moments ago", actions.relative_time(20))
  end)

  it("counts the days since Malenia's last visit", function()
    assert.equal("3 days ago", actions.relative_time(3 * 24 * 3600 + 50))
  end)

  it("keeps a single unit singular", function()
    assert.equal("1 hour ago", actions.relative_time(3600))
  end)

  it("reaches back years for legacy code", function()
    assert.equal("2 years ago", actions.relative_time(2 * 365 * 24 * 3600))
  end)
end)

describe("kind", function()
  local leon = actions.parse_porcelain(LEON_BLAME)

  it("calls another author's line a phantom", function()
    assert.equal("other", actions.kind(leon, { name = "Claire Redfield", mail = "claire.redfield@terrasave.org" }))
  end)

  it("recognizes your own bloodstain by email", function()
    assert.equal("self", actions.kind(leon, { name = "Someone Else", mail = "leon@rpd.gov" }))
  end)

  it("recognizes your own bloodstain by name when the email changed", function()
    assert.equal("self", actions.kind(leon, { name = "Leon Kennedy", mail = "leon@new.job" }))
  end)

  it("treats uncommitted lines as unwritten before anything else", function()
    assert.equal("unwritten", actions.kind({ unwritten = true, author = "Inde Navarrete", mail = "" }, { name = "Inde Navarrete" }))
  end)
end)

describe("describe", function()
  local leon = actions.parse_porcelain(LEON_BLAME)

  it("names the phantom in the title", function()
    assert.equal(" ◈ Phantom of Leon Kennedy ", actions.describe(leon, "other", 1700000000 + 3600).title)
  end)

  it("tells when and which commit on the first line", function()
    assert.equal("1 hour ago · 4f9c2a1", actions.describe(leon, "other", 1700000000 + 3600).lines[1])
  end)

  it("carries the commit message on the second line", function()
    assert.equal(leon.summary, actions.describe(leon, "self", 1700000000).lines[2])
  end)

  it("speaks of your past self for your own lines", function()
    assert.equal(" ◈ Bloodstain of your past self ", actions.describe(leon, "self", 1700000000).title)
  end)
end)

describe("untracked", function()
  it("spots a file git has never seen", function()
    assert.is_true(actions.untracked("fatal: no such path 'ada/notes.lua' in HEAD\n"))
  end)

  it("does not mistake a folder outside any repo for an untracked file", function()
    assert.is_false(actions.untracked("fatal: not a git repository (or any of the parent directories): .git"))
  end)

  it("treats a missing message as nothing to report", function()
    assert.is_false(actions.untracked(nil))
  end)
end)
