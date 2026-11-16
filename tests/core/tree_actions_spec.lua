local actions = require("core.tree.actions")

local root = "/home/claire/terrasave"
local tree = { thread = "T", message = "M", left = "L", cleared = "C" }

describe("relative", function()
  it("finds Claire's love notes inside her repo", function()
    assert.equal("notes/inde.md", actions.relative(root, root .. "/notes/inde.md"))
  end)

  it("leaves the root itself and Wesker's files outside it unnamed", function()
    assert.is_nil(actions.relative(root, root))
    assert.is_nil(actions.relative(root, "/home/wesker/plans.md"))
  end)
end)

describe("folder_state", function()
  local rooms = {
    { key = "lua/core", cleared = false },
    { key = "lua/love", cleared = true },
    { key = "tests/core", cleared = true },
  }

  it("marks a folder left while one of its rooms still hides errors or TODOs", function()
    assert.equal("left", actions.folder_state(rooms, "lua"))
    assert.equal("left", actions.folder_state(rooms, "lua/core"))
  end)

  it("marks Malenia's folder cleared once every room inside is", function()
    assert.equal("cleared", actions.folder_state(rooms, "tests"))
    assert.equal("cleared", actions.folder_state(rooms, "lua/love"))
  end)

  it("leaves folders deeper than a room and folders with no room unmarked", function()
    assert.is_nil(actions.folder_state(rooms, "lua/core/dates"))
    assert.is_nil(actions.folder_state(rooms, "docs"))
  end)

  it("does not mistake a folder for one that only shares its prefix", function()
    assert.is_nil(actions.folder_state({ { key = "lua/lovers", cleared = false } }, "lua/love"))
  end)

  it("stays quiet until the first survey lands", function()
    assert.is_nil(actions.folder_state(nil, "lua"))
  end)
end)

describe("count_by_file", function()
  it("counts the review threads on Inde's anniversary page", function()
    local threads =
      { { path = "anniversary.md" }, { path = "anniversary.md" }, { path = "date.lua" } }
    assert.same(
      { ["anniversary.md"] = 2, ["date.lua"] = 1 },
      actions.count_by_file(threads, "path")
    )
  end)

  it("returns nothing when the repo has no PR", function()
    assert.same({}, actions.count_by_file(nil, "path"))
  end)
end)

describe("file_marks", function()
  it("shows the threads with their count and a ground message on Malenia's letter", function()
    local marks = actions.file_marks(
      "letter.md",
      { ["letter.md"] = 2 },
      { ["letter.md"] = 1 },
      tree
    )
    assert.same({
      { text = "T 2 ", highlight = "EldenTreeThread" },
      { text = "M ", highlight = "EldenTreeMessage" },
    }, marks)
  end)

  it("leaves a quiet file bare", function()
    assert.same({}, actions.file_marks("playlist.lua", {}, {}, tree))
    assert.same({}, actions.file_marks(nil, { x = 1 }, {}, tree))
  end)
end)

describe("folder_mark", function()
  it("dresses a room still left in the skin's glyph", function()
    assert.same({ text = "L ", highlight = "EldenTreeLeft" }, actions.folder_mark("left", tree))
  end)

  it("keeps Malenia's cleared rooms bare, so only the folder that needs her stands out", function()
    assert.is_nil(actions.folder_mark("cleared", tree))
  end)

  it("marks nothing for a folder that is no room", function()
    assert.is_nil(actions.folder_mark(nil, tree))
  end)
end)
