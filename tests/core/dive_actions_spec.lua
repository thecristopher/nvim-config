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

describe("item_category", function()
  it("calls a method a sorcery", function()
    assert.equal("Sorcery", actions.item_category({ "function.method.call" }))
  end)

  it("calls a plain function an incantation", function()
    assert.equal("Incantation", actions.item_category({ "function.call" }))
  end)

  it("files a type away as a talisman", function()
    assert.equal("Talisman", actions.item_category({ "type.builtin" }))
  end)

  it("reads the innermost capture first, like Claire's name inside a love letter", function()
    assert.equal("Ash of War", actions.item_category({ "variable", "variable.parameter" }))
  end)

  it("does not confuse a prefix with a different capture", function()
    assert.equal("Item", actions.item_category({ "typedefinitely_not_a_type" }))
  end)

  it("falls back to a plain item with nothing under the cursor", function()
    assert.equal("Item", actions.item_category({}))
  end)
end)
