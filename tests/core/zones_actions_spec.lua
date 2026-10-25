local actions = require("core.zones.actions")

local ROOT = "/realms/haligtree"

describe("zone_key", function()
  it("names Malenia's folder by its first two levels", function()
    assert.equal("lua/core", actions.zone_key(ROOT .. "/lua/core/rot/bloom.lua", ROOT))
  end)

  it("keeps a single level folder as it is", function()
    assert.equal("docs", actions.zone_key(ROOT .. "/docs/love_letter.md", ROOT))
  end)

  it("has no zone for files at the root", function()
    assert.is_nil(actions.zone_key(ROOT .. "/README.md", ROOT))
  end)

  it("has no zone outside the repo, or without one", function()
    assert.is_nil(actions.zone_key("/elsewhere/notes.md", ROOT))
    assert.is_nil(actions.zone_key(ROOT .. "/lua/x.lua", nil))
  end)

  it("does not mistake a sibling folder with the same prefix for the repo", function()
    assert.is_nil(actions.zone_key("/realms/haligtree-old/lua/x.lua", ROOT))
  end)
end)

describe("zone_name", function()
  it("buries tests in the Stranded Graveyard, wherever they nest", function()
    assert.equal("Stranded Graveyard", actions.zone_name("tests/core"))
  end)

  it("sinks node_modules into the Lake of Rot", function()
    assert.equal("Lake of Rot", actions.zone_name("node_modules"))
  end)

  it("gives any other folder a place that never changes", function()
    assert.equal(actions.zone_name("lua/core"), actions.zone_name("lua/core"))
    assert.is_truthy(vim.tbl_contains(require("core.franchise").current().places, actions.zone_name("lua/core")))
  end)
end)

describe("should_announce", function()
  local fresh = { key = "lua/core", seen = {}, now = 100000, busy = false }

  it("announces a zone Claire has not walked into yet", function()
    assert.is_true(actions.should_announce(fresh))
  end)

  it("stays quiet in a zone already seen this session", function()
    assert.is_false(actions.should_announce(vim.tbl_extend("force", fresh, { seen = { ["lua/core"] = true } })))
  end)

  it("waits out the cooldown after the last zone", function()
    local opts = vim.tbl_extend("force", fresh, { last_shown = fresh.now - actions.COOLDOWN_MS + 1 })
    assert.is_false(actions.should_announce(opts))
  end)

  it("never talks over another banner, like a grace Inde just found", function()
    assert.is_false(actions.should_announce(vim.tbl_extend("force", fresh, { busy = true })))
  end)

  it("has nothing to say without a zone", function()
    assert.is_false(actions.should_announce({ key = nil, seen = {}, now = fresh.now, busy = false }))
  end)
end)
