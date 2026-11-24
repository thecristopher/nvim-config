-- The bridge's reactions to the events back-to-basics fires, with sound, voice and runes stubbed.
local stubbed = { "core.sound", "core.voice", "core.runes", "core.utils" }

describe("btb bridge", function()
  local played, said, spent, talking, cut
  local saved = {}

  before_each(function()
    played, said, spent, talking, cut = {}, {}, 0, false, {}
    for _, name in ipairs(stubbed) do
      saved[name] = package.loaded[name]
    end
    -- the shop remembers its greeting in state, never in the real one
    package.loaded["core.utils"] = setmetatable({ write_state = function() end }, {
      __index = require("core.utils"),
    })
    package.loaded["core.sound"] = {
      play_first = function(events)
        table.insert(played, events[1])
      end,
      play = function(event)
        table.insert(played, event)
        return {
          kill = function()
            table.insert(cut, event)
          end,
        }
      end,
      speaking = function()
        return talking
      end,
    }
    package.loaded["core.voice"] = {
      say = function(moment)
        table.insert(said, moment)
        return talking
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

  it("keeps the HUD click quiet while Claire talks Inde through the hint", function()
    talking = true
    vim.api.nvim_exec_autocmds("User", { pattern = "BtbHint", data = { cost = 5 } })
    assert.are.same({}, played)
  end)

  it("has Claire cut the merchant's thanks when Inde buys a hint", function()
    talking = true
    local select = vim.ui.select
    vim.ui.select = function(items, _, choose)
      choose(items[1])
    end
    require("core.btb").before_hint({ id = "love-letter", hints_left = 2, cost = 5 }, function()
      vim.api.nvim_exec_autocmds("User", { pattern = "BtbHint", data = { cost = 5 } })
    end)
    vim.ui.select = select
    assert.are.same({ "bought" }, cut)
  end)

  it("still takes the hint's price out of the runes", function()
    vim.api.nvim_exec_autocmds("User", { pattern = "BtbHint", data = { cost = 5 } })
    assert.are.equal(5, spent)
  end)
end)
