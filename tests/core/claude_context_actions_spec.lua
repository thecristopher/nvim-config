local actions = require("core.claude_context.actions")

-- a stand in for a tree-sitter node: its type, zero based rows and parent
local function node(kind, first, last, parent)
  return {
    type = function()
      return kind
    end,
    range = function()
      return first, 0, last, 0
    end,
    parent = function()
      return parent
    end,
  }
end

local function diagnostic(severity, lnum, message)
  return { severity = severity, lnum = lnum, message = message }
end

describe("claude_context.actions", function()
  describe("enclosing_function", function()
    it("climbs from Claire's love note to the function that writes it", function()
      local letter = node("function_declaration", 9, 19, nil)
      local note = node("string", 12, 12, node("return_statement", 12, 12, letter))
      local first, last = actions.enclosing_function(note)
      assert.are.equal(10, first)
      assert.are.equal(20, last)
    end)

    it("stops at the closest function when Malenia's playlist nests one", function()
      local outer = node("function_declaration", 0, 40, nil)
      local shuffle = node("arrow_function", 5, 8, outer)
      assert.are.same({ 6, 9 }, { actions.enclosing_function(node("identifier", 6, 6, shuffle)) })
    end)

    it("gives nothing outside any function or without a node", function()
      assert.is_nil(actions.enclosing_function(node("comment", 3, 3, nil)))
      assert.is_nil(actions.enclosing_function(nil))
    end)
  end)

  describe("diagnostics_prompt", function()
    local severity = vim.diagnostic.severity

    it("lists Inde's errors before warnings, each on its line", function()
      local prompt = actions.diagnostics_prompt({
        diagnostic(severity.WARN, 2, "unused anniversary"),
        diagnostic(severity.ERROR, 30, "date is nil"),
        diagnostic(severity.ERROR, 4, "no gift"),
      }, "lua/dates.lua")
      assert.are.equal(
        "Fix these diagnostics in lua/dates.lua: L5 error: no gift; L31 error: date is nil; L3 warn: unused anniversary",
        prompt
      )
    end)

    it("keeps the ask on one line when Wesker's message spans several", function()
      local prompt =
        actions.diagnostics_prompt({ diagnostic(severity.HINT, 0, "too\n  smug ") }, "a.lua")
      assert.are.equal("Fix these diagnostics in a.lua: L1 hint: too smug", prompt)
    end)

    it("has nothing to ask on a clean buffer", function()
      assert.is_nil(actions.diagnostics_prompt({}, "clean.lua"))
    end)
  end)
end)
