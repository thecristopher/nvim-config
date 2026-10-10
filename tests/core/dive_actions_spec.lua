local actions = require("core.dive.actions")

local function find(maps, lhs)
  for _, map in ipairs(maps) do
    if map.lhs == lhs then return map end
  end
end

describe("dive bindings", function()
  local maps = actions.expand(actions.bindings)

  it("sends F12 to go to definition", function()
    assert.equal("definition", find(maps, "<F12>").action)
  end)

  it("treats the F24 terminal code the same as Shift F12", function()
    assert.equal(find(maps, "<S-F12>").action, find(maps, "<F24>").action)
  end)

  it("treats the F36 terminal code the same as Ctrl F12", function()
    assert.equal(find(maps, "<C-F12>").action, find(maps, "<F36>").action)
  end)

  it("peeks the definition on Alt F12", function()
    assert.equal("peek_definition", find(maps, "<M-F12>").action)
  end)

  it("renames on F2", function()
    assert.equal("rename", find(maps, "<F2>").action)
  end)

  it("defaults to normal mode", function()
    assert.equal("n", find(maps, "gd").mode)
  end)

  it("keeps the custom mode for code actions", function()
    assert.same({ "n", "x" }, find(maps, "<leader>ca").mode)
  end)

  it("never binds the same key twice", function()
    local seen = {}
    for _, map in ipairs(maps) do
      assert.is_nil(seen[map.lhs], "duplicate binding for " .. map.lhs)
      seen[map.lhs] = true
    end
  end)

  it("has a handler for every action", function()
    package.loaded["core.dive"] = nil
    local handlers = require("core.dive").handlers
    for _, map in ipairs(maps) do
      assert.is_function(handlers[map.action], "missing handler for " .. map.action)
    end
  end)
end)
