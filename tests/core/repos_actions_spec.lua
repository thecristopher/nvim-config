local actions = require("core.repos.actions")

local LEYNDELL = "/Users/godrick/Documents/GitHub/leyndell"
local STORMVEIL = "/Users/godrick/Documents/GitHub/stormveil"
local RAYA_LUCARIA = "/Users/godrick/Documents/GitHub/raya-lucaria"

describe("parse_scan_output", function()
  it("turns .git folders into repo roots", function()
    local stdout = LEYNDELL .. "/.git/\n" .. STORMVEIL .. "/.git/\n"
    assert.same({ LEYNDELL, STORMVEIL }, actions.parse_scan_output(stdout))
  end)

  it("accepts .git files from worktrees", function()
    assert.same({ RAYA_LUCARIA }, actions.parse_scan_output(RAYA_LUCARIA .. "/.git\n"))
  end)

  it("skips lines that are not .git entries", function()
    assert.same({}, actions.parse_scan_output("/Users/godrick/notes.txt\n"))
  end)

  it("drops duplicates", function()
    local stdout = LEYNDELL .. "/.git/\n" .. LEYNDELL .. "/.git\n"
    assert.same({ LEYNDELL }, actions.parse_scan_output(stdout))
  end)

  it("returns nothing for empty output", function()
    assert.same({}, actions.parse_scan_output(nil))
  end)
end)

describe("display_path", function()
  it("shortens the home folder to a tilde", function()
    assert.equal("~/Documents/GitHub/leyndell", actions.display_path(LEYNDELL, "/Users/godrick"))
  end)

  it("treats dots in the home path literally", function()
    local path = "/Users/leonXkennedy/raccoon"
    assert.equal(path, actions.display_path(path, "/Users/leon.kennedy"))
  end)

  it("leaves paths outside home alone", function()
    assert.equal("/opt/umbrella", actions.display_path("/opt/umbrella", "/Users/wesker"))
  end)
end)

describe("branch_from_head", function()
  it("reads the branch name from a symbolic ref", function()
    assert.equal("main", actions.branch_from_head("ref: refs/heads/main\n"))
  end)

  it("keeps slashes in branch names", function()
    assert.equal("feature/elden-hub", actions.branch_from_head("ref: refs/heads/feature/elden-hub\n"))
  end)

  it("shortens a detached sha to seven characters", function()
    assert.equal("c266bff", actions.branch_from_head("c266bff0123456789abcdef\n"))
  end)

  it("returns nil for empty contents", function()
    assert.is_nil(actions.branch_from_head(""))
  end)
end)

describe("gitdir_from_file", function()
  it("reads an absolute gitdir from a worktree file", function()
    local contents = "gitdir: /Users/ada/umbrella/.git/worktrees/hive\n"
    assert.equal("/Users/ada/umbrella/.git/worktrees/hive", actions.gitdir_from_file(contents, "/Users/ada/hive"))
  end)

  it("resolves a relative gitdir against the repo", function()
    local contents = "gitdir: ../.git/modules/lab"
    assert.equal("/Users/ada/umbrella/lab/../.git/modules/lab", actions.gitdir_from_file(contents, "/Users/ada/umbrella/lab"))
  end)

  it("returns nil for anything else", function()
    assert.is_nil(actions.gitdir_from_file("not a pointer", "/Users/ada/hive"))
  end)
end)

describe("rank", function()
  it("puts tracked repos first in visit order", function()
    local ranked = actions.rank({ STORMVEIL, LEYNDELL }, { LEYNDELL, RAYA_LUCARIA, STORMVEIL }, {})
    assert.same({ STORMVEIL, LEYNDELL, RAYA_LUCARIA }, ranked)
  end)

  it("sorts scanned repos by most recent activity", function()
    local activity = { [LEYNDELL] = 10, [STORMVEIL] = 30, [RAYA_LUCARIA] = 20 }
    local ranked = actions.rank({}, { LEYNDELL, STORMVEIL, RAYA_LUCARIA }, activity)
    assert.same({ STORMVEIL, RAYA_LUCARIA, LEYNDELL }, ranked)
  end)

  it("respects the limit", function()
    assert.same({ LEYNDELL }, actions.rank({ LEYNDELL }, { STORMVEIL }, {}, 1))
  end)
end)

describe("remember", function()
  it("moves a revisited repo to the front", function()
    assert.same({ LEYNDELL, STORMVEIL }, actions.remember({ STORMVEIL, LEYNDELL }, LEYNDELL))
  end)

  it("caps the list size", function()
    assert.same({ RAYA_LUCARIA, STORMVEIL }, actions.remember({ STORMVEIL, LEYNDELL }, RAYA_LUCARIA, 2))
  end)
end)

describe("is_ignored", function()
  it("ignores files inside node_modules", function()
    assert.is_true(actions.is_ignored(STORMVEIL .. "/node_modules/react/index.js", {}))
  end)

  it("ignores files under a listed folder", function()
    local plugins = "/Users/melina/.local/share/nvim"
    assert.is_true(actions.is_ignored(plugins .. "/lazy/snacks.nvim/init.lua", { plugins }))
  end)

  it("keeps regular project files", function()
    assert.is_false(actions.is_ignored(STORMVEIL .. "/src/gate.ts", { "/Users/melina/.local/share/nvim" }))
  end)
end)

describe("should_change_root", function()
  it("hops to a repo opened from somewhere else", function()
    assert.is_true(actions.should_change_root(STORMVEIL .. "/gate.ts", LEYNDELL, STORMVEIL))
  end)

  it("stays put when the file is under the current folder", function()
    local github = "/Users/godrick/Documents/GitHub"
    assert.is_false(actions.should_change_root(STORMVEIL .. "/gate.ts", github, STORMVEIL))
  end)

  it("stays put when already at the root", function()
    assert.is_false(actions.should_change_root(STORMVEIL .. "/gate.ts", STORMVEIL, STORMVEIL))
  end)

  it("stays put when the file has no repo", function()
    assert.is_false(actions.should_change_root("/tmp/scratch.md", LEYNDELL, nil))
  end)

  it("does not confuse sibling folders sharing a prefix", function()
    assert.is_true(actions.should_change_root("/repo-two/a.lua", "/repo", "/repo-two"))
  end)
end)

describe("folder_from_input", function()
  it("returns nothing when Melina leaves the prompt empty", function()
    assert.is_nil(actions.folder_from_input("   "))
  end)

  it("returns nothing when the prompt is cancelled", function()
    assert.is_nil(actions.folder_from_input(nil))
  end)

  it("trims spaces and the trailing slash", function()
    assert.equal(STORMVEIL, actions.folder_from_input("  " .. STORMVEIL .. "/  "))
  end)
end)
