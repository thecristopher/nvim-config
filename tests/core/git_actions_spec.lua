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

  it("leaves out Claire's love note deletion once it is already staged", function()
    local stage, skipped = actions.related({
      { code = "D ", path = "notes/claire_to_inde.lua" },
      { code = "M ", path = "lua/malenia_playlist.lua" },
    })
    assert.same({}, stage)
    assert.same({}, skipped)
  end)

  it("still stages a file edited again after it was staged", function()
    local stage = actions.related({ { code = "MM", path = "lua/anniversary.lua" } })
    assert.same({ "lua/anniversary.lua" }, stage)
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

describe("QUICK_KEYS", function()
  it("never gives two actions the same key", function()
    local seen = {}
    for _, entry in ipairs(actions.QUICK_KEYS) do
      assert.is_nil(seen[entry.key], "duplicate key " .. entry.key)
      seen[entry.key] = true
    end
  end)

  it("points every key at a function core.git really has", function()
    package.loaded["core.git"] = nil
    local git = require("core.git")
    for _, entry in ipairs(actions.QUICK_KEYS) do
      assert.is_function(git[entry.fn], entry.fn)
    end
  end)
end)

describe("terminal_hint", function()
  local keys = {
    { key = "j", short = "pull" },
    { key = "k", short = "push" },
  }

  it("tells Claire to leave terminal mode first", function()
    assert.truthy(actions.terminal_hint(keys):find("<Esc> then <Space>g", 1, true))
  end)

  it("lists each key next to its short name, in order", function()
    local hint = actions.terminal_hint(keys)
    local pull = hint:find("j%* pull", 1, true)
    local push = hint:find("k%* push", 1, true)
    assert.truthy(pull and push and pull < push)
  end)
end)

describe("checkout_args", function()
  it("switches to Claire's local branch as is", function()
    assert.same({ "switch", "feature/love-notes" }, actions.checkout_args("feature/love-notes"))
  end)

  it("tracks Malenia's remote branch under its own name", function()
    assert.same(
      { "switch", "-c", "feature/haligtree", "--track", "origin/feature/haligtree" },
      actions.checkout_args("remotes/origin/feature/haligtree")
    )
  end)
end)

describe("trim_diff", function()
  local function file_diff(name, lines)
    local out = { "diff --git a/" .. name .. " b/" .. name, "@@ -1 +1 @@" }
    for index = 1, lines do
      table.insert(out, "+line " .. index .. " of the love letter")
    end
    return table.concat(out, "\n")
  end

  it("keeps Claire's small diff whole", function()
    local diff = file_diff("claire.lua", 3)
    assert.equal(diff, actions.trim_diff(diff, 6000))
  end)

  it("gives Inde's small file its place next to Malenia's huge one", function()
    local diff = file_diff("malenia.lua", 400) .. "\n" .. file_diff("inde.lua", 2)
    local trimmed = actions.trim_diff(diff, 2000)
    assert.truthy(trimmed:find("diff --git a/inde.lua", 1, true))
    assert.truthy(trimmed:find("+line 2 of the love letter", 1, true))
    assert.truthy(trimmed:find("more lines of this file left out", 1, true))
    assert.is_true(#trimmed <= 2200)
  end)
end)

describe("left_out_comments", function()
  it("lists the files Claire left out as comments git ignores", function()
    assert.same(
      { "", "# Left out of this commit:", "#   .env", "#   debug.log" },
      actions.left_out_comments({ ".env", "debug.log" })
    )
  end)

  it("adds nothing when every change of Inde's made it in", function()
    assert.same({}, actions.left_out_comments({}))
  end)
end)
