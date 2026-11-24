local modules = require("eldentree.modules")

describe("selected", function()
  it("sets up every module for Claire by default, in order", function()
    assert.same(modules.ORDER, modules.selected())
  end)

  it("keeps only the modules Malenia asked for, plus the required ones", function()
    assert.same({ "franchise", "skin", "motion", "boss" }, modules.selected({ only = { "boss" } }))
  end)

  it("leaves out the music when Inde skips it", function()
    local chosen = modules.selected({ skip = { "music" } })
    assert.is_false(vim.tbl_contains(chosen, "music"))
    assert.equal(#modules.ORDER - 1, #chosen)
  end)

  it("never skips the world everything reads", function()
    assert.is_true(vim.tbl_contains(modules.selected({ skip = { "franchise" } }), "franchise"))
  end)
end)

describe("unknown", function()
  it("catches a module name Wesker made up", function()
    assert.same({ "umbrella" }, modules.unknown({ "boss", "umbrella" }))
  end)
end)

describe("ORDER", function()
  it("names only modules that exist and can be set up", function()
    for _, name in ipairs(modules.ORDER) do
      local source = table.concat(vim.fn.readfile("lua/core/" .. name .. "/init.lua"), "\n")
      assert.is_truthy(source:find("function M.setup", 1, true), name)
    end
  end)

  it("sets up every core module with a setup except the ones set up elsewhere", function()
    -- init.lua runs the first three on its own, the plugin specs set up the rest with their plugin
    local own =
      { whitespace = true, spell = true, vscode = true, btb = true, copilot = true, themes = true }
    for _, path in ipairs(vim.fn.glob("lua/core/*/init.lua", false, true)) do
      local name = path:match("lua/core/([%w_]+)/init.lua")
      local source = table.concat(vim.fn.readfile(path), "\n")
      if source:find("function M.setup", 1, true) and not own[name] then
        assert.is_true(vim.tbl_contains(modules.ORDER, name), name)
      end
    end
  end)
end)
