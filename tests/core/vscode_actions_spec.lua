local actions = require("core.vscode.actions")

describe("vscode allowed plugins", function()
  it("keeps flash for motions", function()
    assert.is_true(actions.allowed({ name = "flash.nvim" }))
  end)

  it("keeps treesitter textobjects", function()
    assert.is_true(actions.allowed({ name = "nvim-treesitter-textobjects" }))
  end)

  it("drops the dashboard and UI plugins", function()
    assert.is_false(actions.allowed({ name = "snacks.nvim" }))
  end)

  it("drops the cursor trail", function()
    assert.is_false(actions.allowed({ name = "smear-cursor.nvim" }))
  end)
end)

describe("vscode bindings", function()
  local function command_for(lhs)
    for _, binding in ipairs(actions.bindings) do
      if binding.lhs == lhs then
        return binding.command
      end
    end
  end

  it("sends gd to the editor's go to definition", function()
    assert.equal("editor.action.revealDefinition", command_for("gd"))
  end)

  it("sends gp to the editor's peek window", function()
    assert.equal("editor.action.peekDefinition", command_for("gp"))
  end)

  it("never binds the same key twice", function()
    local seen = {}
    for _, binding in ipairs(actions.bindings) do
      assert.is_nil(seen[binding.lhs], "duplicate binding for " .. binding.lhs)
      seen[binding.lhs] = true
    end
  end)
end)
