local actions = require("core.keys.actions")

describe("steals_terminal_typing", function()
  it("flags a leader mapping since every space would stall", function()
    assert.is_true(actions.steals_terminal_typing("<leader>ac"))
  end)

  it("flags plain brackets Leon types into his shell", function()
    assert.is_true(actions.steals_terminal_typing("]]"))
  end)

  it("flags <C-\\> because it blocks <C-\\><C-n>", function()
    assert.is_true(actions.steals_terminal_typing("<C-\\>"))
  end)

  it("lets a control chord through", function()
    assert.is_false(actions.steals_terminal_typing("<C-h>"))
  end)
end)

describe("terminal_thieves", function()
  it("ignores normal mode only keys", function()
    assert.same({}, actions.terminal_thieves({ { keys = { { "]]", "x" } } } }))
  end)

  it("catches Wesker's leader key in terminal mode", function()
    local specs = { { keys = { { "<leader>ac", "x", mode = { "n", "t" } } } } }
    assert.same({ "<leader>ac" }, actions.terminal_thieves(specs))
  end)

  it("finds none across the real plugin specs", function()
    local specs = {}
    for _, file in ipairs(vim.api.nvim_get_runtime_file("lua/plugins/*.lua", true)) do
      local spec = dofile(file)
      if type(spec[1]) == "string" then spec = { spec } end
      vim.list_extend(specs, spec)
    end
    assert.same({}, actions.terminal_thieves(specs))
  end)
end)
