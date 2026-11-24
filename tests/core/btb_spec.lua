-- The bridge's reactions to the events back-to-basics fires, with sound, voice and runes stubbed.
local stubbed = { "core.sound", "core.voice", "core.runes" }

describe("btb bridge", function()
  local played, said, spent
  local saved = {}

  before_each(function()
    played, said, spent = {}, {}, 0
    for _, name in ipairs(stubbed) do
      saved[name] = package.loaded[name]
    end
    package.loaded["core.sound"] = {
      play_first = function(events)
        table.insert(played, events[1])
      end,
    }
    package.loaded["core.voice"] = {
      say = function(moment)
        table.insert(said, moment)
        return true
      end,
    }
    package.loaded["core.runes"] = {
      spend = function(amount)
        spent = spent + amount
      end,
    }
    package.loaded["core.btb"] = nil
    require("core.btb").setup()
  end)

  after_each(function()
    for _, name in ipairs(stubbed) do
      package.loaded[name] = saved[name]
    end
    package.loaded["core.btb"] = nil
    pcall(vim.api.nvim_del_augroup_by_name, "eldentree_btb")
  end)

  it("has Claire say her line when Inde buys a hint", function()
    vim.api.nvim_exec_autocmds("User", { pattern = "BtbHint", data = { cost = 5 } })
    assert.are.same({ "hint" }, said)
    assert.are.same({ "hud_select" }, played)
  end)

  it("still takes the hint's price out of the runes", function()
    vim.api.nvim_exec_autocmds("User", { pattern = "BtbHint", data = { cost = 5 } })
    assert.are.equal(5, spent)
  end)
end)
