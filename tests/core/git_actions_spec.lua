local actions = require("core.git.actions")

describe("slug", function()
  it("turns Claire's note into a branch friendly slug", function()
    assert.equal("anniversary-note-for-inde", actions.slug("  Anniversary note_for Inde! "))
  end)

  it("collapses repeated separators", function()
    assert.equal("malenia-playlist", actions.slug("malenia -- playlist"))
  end)
end)

describe("branch_name", function()
  it("adds the chosen prefix", function()
    assert.equal("feature/shared-playlist", actions.branch_name("feature", "Shared playlist"))
  end)

  it("keeps a prefix Malenia already typed", function()
    assert.equal("bugfix/love-letter", actions.branch_name("feature", "bugfix/love letter"))
  end)

  it("gives up on an empty name", function()
    assert.is_nil(actions.branch_name("feature", "  !! "))
  end)
end)

describe("parse_status", function()
  it("reads modified, untracked and renamed entries", function()
    local raw = " M lua/claire.lua\0?? notes/inde.md\0R  lua/date.lua\0lua/old_date.lua\0"
    assert.same({
      { code = " M", path = "lua/claire.lua" },
      { code = "??", path = "notes/inde.md" },
      { code = "R ", path = "lua/date.lua" },
    }, actions.parse_status(raw))
  end)

  it("returns nothing for a clean tree", function()
    assert.same({}, actions.parse_status(""))
  end)
end)

describe("related", function()
  it("stages code but leaves secrets and noise behind", function()
    local stage, skipped = actions.related({
      { code = " M", path = "lua/malenia.lua" },
      { code = "??", path = "lua/inde.lua" },
      { code = "??", path = ".env" },
      { code = "??", path = "logs/wesker.log" },
      { code = "??", path = ".DS_Store" },
    })
    assert.same({ "lua/malenia.lua", "lua/inde.lua" }, stage)
    assert.same({ ".env", "logs/wesker.log", ".DS_Store" }, skipped)
  end)

  it("keeps env templates since they belong in the repo", function()
    local stage = actions.related({ { code = "??", path = ".env.example" } })
    assert.same({ ".env.example" }, stage)
  end)

  it("stages a tracked file even if its name looks like noise", function()
    local stage = actions.related({ { code = " M", path = "config/claire.key" } })
    assert.same({ "config/claire.key" }, stage)
  end)

  it("stages deletions", function()
    local stage = actions.related({ { code = " D", path = "lua/radahn.lua" } })
    assert.same({ "lua/radahn.lua" }, stage)
  end)
end)

describe("push_args", function()
  it("plain push once the branch tracks a remote", function()
    assert.same({ "push" }, actions.push_args(true))
  end)

  it("sets the upstream on the first push", function()
    assert.same({ "push", "-u", "origin", "HEAD" }, actions.push_args(false))
  end)
end)
