local actions = require("core.map.actions")

local root = "/home/claire/terrasave"
local files = { "README.md", "lua/core/notes.lua", "lua/core/dates.lua", "tests/core/notes_spec.lua" }

describe("parse_counts", function()
  it("reads git grep counts per file", function()
    local counts = actions.parse_counts("lua/core/notes.lua:2\ntests/core/notes_spec.lua:1\n")
    assert.same({ ["lua/core/notes.lua"] = 2, ["tests/core/notes_spec.lua"] = 1 }, counts)
  end)

  it("keeps paths that contain a colon", function()
    assert.same({ ["love:notes.lua"] = 3 }, actions.parse_counts("love:notes.lua:3"))
  end)

  it("returns nothing when git found nothing", function()
    assert.same({}, actions.parse_counts(""))
  end)
end)

describe("rooms", function()
  it("turns every folder into one room and leaves root files out", function()
    local rooms = actions.rooms(root, files, {}, {})
    assert.same({ "lua/core", "tests/core" }, vim.tbl_map(function(room) return room.key end, rooms))
  end)

  it("keeps a room red while Inde's TODO is still in it", function()
    local rooms = actions.rooms(root, files, { ["lua/core/dates.lua"] = 1 }, {})
    assert.is_false(rooms[1].cleared)
    assert.equal(1, rooms[1].todos)
  end)

  it("keeps a room red while an open buffer in it has errors", function()
    local rooms = actions.rooms(root, files, {}, { [root .. "/tests/core/notes_spec.lua"] = 2 })
    assert.is_false(rooms[2].cleared)
    assert.equal(2, rooms[2].errors)
  end)

  it("turns a room blue once nothing is left in it", function()
    assert.is_true(actions.rooms(root, files, {}, {})[1].cleared)
  end)

  it("ignores errors in files outside the project", function()
    local rooms = actions.rooms(root, files, {}, { ["/tmp/wesker/plan.lua"] = 5 })
    assert.is_true(rooms[1].cleared and rooms[2].cleared)
  end)
end)

describe("leftovers", function()
  it("lists errors before TODOs", function()
    assert.equal("2 errors, 1 TODO", actions.leftovers({ errors = 2, todos = 1 }))
  end)

  it("says nothing about a cleared room", function()
    assert.equal("", actions.leftovers({ errors = 0, todos = 0 }))
  end)
end)

describe("progress", function()
  it("counts the cleared rooms out of all of them", function()
    local cleared, total = actions.progress({ { cleared = true }, { cleared = false }, { cleared = true } })
    assert.equal(2, cleared)
    assert.equal(3, total)
  end)
end)
