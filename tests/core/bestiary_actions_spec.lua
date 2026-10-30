local actions = require("core.bestiary.actions")

local repo = "/home/malenia/haligtree"

describe("key", function()
  it("knows a diagnostic by its source and code", function()
    assert.equal("typescript 2345", actions.key({ source = "typescript", code = 2345 }))
    assert.equal(
      "Lua Diagnostics undefined-field",
      actions.key({ source = "Lua Diagnostics.", code = "undefined-field" })
    )
  end)

  it("falls back to the source, and gives up without either", function()
    assert.equal("selene", actions.key({ source = "selene" }))
    assert.is_nil(actions.key({}))
  end)
end)

describe("tally", function()
  it("counts Claire's diagnostics per key", function()
    local counts = actions.tally({
      { source = "ts", code = 1 },
      { source = "ts", code = 1 },
      { source = "ts", code = 2 },
      {},
    })
    assert.same({ ["ts 1"] = 2, ["ts 2"] = 1 }, counts)
  end)
end)

describe("felled", function()
  it("counts every foe that left between two readings", function()
    local kills = actions.felled({ ["ts 1"] = 3, ["ts 2"] = 1 }, { ["ts 1"] = 1, ["ts 3"] = 4 })
    assert.same({ ["ts 1"] = 2, ["ts 2"] = 1 }, kills)
  end)

  it("fells nothing on the first reading", function()
    assert.same({}, actions.felled(nil, { ["ts 1"] = 1 }))
  end)
end)

describe("record", function()
  it("adds Malenia's kills to the repo's bestiary", function()
    local store = actions.record({}, repo, { ["ts 1"] = 2 }, "2026-10-28")
    store = actions.record(store, repo, { ["ts 1"] = 1 }, "2026-10-29")
    assert.same({ kills = 3, last = "2026-10-29" }, store[repo]["ts 1"])
  end)
end)

describe("enemy", function()
  local enemies = { "Zombie", "Licker", "Hunter" }

  it("names the same foe every time for the same key", function()
    assert.equal(actions.enemy("ts 2345", enemies), actions.enemy("ts 2345", enemies))
  end)

  it("always picks one of the franchise's enemies", function()
    assert.is_true(vim.tbl_contains(enemies, actions.enemy("lua_ls undefined-field", enemies)))
  end)
end)

describe("entries", function()
  it("lists the most felled foes first", function()
    local store =
      { [repo] = { ["a"] = { kills = 1, last = "x" }, ["b"] = { kills = 7, last = "y" } } }
    local entries = actions.entries(store, repo, { "Crucible Knight" })
    assert.same(
      { "b", "a" },
      vim.tbl_map(function(e)
        return e.key
      end, entries)
    )
    assert.equal("Crucible Knight", entries[1].enemy)
  end)

  it("has nothing for a repo Inde never fought in", function()
    assert.same({}, actions.entries({}, repo, { "x" }))
  end)
end)
