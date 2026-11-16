local actions = require("core.map.actions")

local root = "/home/claire/terrasave"
local files =
  { "README.md", "lua/core/notes.lua", "lua/core/dates.lua", "tests/core/notes_spec.lua" }

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
    assert.same(
      { "lua/core", "tests/core" },
      vim.tbl_map(function(room)
        return room.key
      end, rooms)
    )
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
    local cleared, total =
      actions.progress({ { cleared = true }, { cleared = false }, { cleared = true } })
    assert.equal(2, cleared)
    assert.equal(3, total)
  end)
end)

describe("wings", function()
  it("gathers Claire's lone top folders into the grounds and keeps real wings apart", function()
    local rooms = actions.rooms(
      root,
      { "docs/a.md", "lua/core/a.lua", "lua/plugins/b.lua" },
      {},
      {}
    )
    local wings = actions.wings(rooms)
    assert.same({ actions.GROUNDS, "lua" }, {
      wings[1].name,
      wings[2].name,
    })
    assert.equal(2, #wings[2].rooms)
  end)
end)

describe("layout", function()
  local glyphs = { left = "◇", cleared = "◆" }
  local rooms = actions.rooms(root, files, { ["lua/core/dates.lua"] = 1 }, {})

  it("draws every room as a box under its wing", function()
    local drawn = actions.layout(rooms, { width = 80, glyphs = glyphs })
    assert.equal(2, #drawn.rooms)
    assert.is_truthy(drawn.lines[2]:find("╭", 1, true))
  end)

  it("marks the room Malenia stands in", function()
    local drawn = actions.layout(rooms, { width = 80, here = "lua/core", glyphs = glyphs })
    assert.is_truthy(table.concat(drawn.lines, "\n"):find(actions.HERE, 1, true))
  end)

  it("keeps every line inside a narrow window", function()
    local drawn = actions.layout(rooms, { width = 24, glyphs = glyphs })
    for _, line in ipairs(drawn.lines) do
      assert.is_true(vim.fn.strdisplaywidth(line) <= 24)
    end
  end)

  it("finds the room under Inde's cursor on any row of its box", function()
    local drawn = actions.layout(rooms, { width = 80, glyphs = glyphs })
    local spot = drawn.rooms[1]
    assert.equal(spot.key, actions.room_at(drawn.rooms, spot.row + 1, spot.col + 3))
    assert.is_nil(actions.room_at(drawn.rooms, 0, 0))
  end)
end)
