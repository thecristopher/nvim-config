-- The answers btb promises in its contracts/, fed to this config's own views. The samples live in the
-- btb clone, so a change on either side that breaks the other shows up here.
local actions = require("core.btb.actions")

local root = vim.g.eldentree_btb_dir or vim.fn.expand("~/Documents/GitHub/back-to-basics")
local found = vim.fn.filereadable(root .. "/lua/back-to-basics/contract.lua") == 1

if not found then
  describe("btb contracts", function()
    it("needs the back-to-basics clone to check them", function()
      pending("no back-to-basics clone at " .. root)
    end)
  end)
  return
end

vim.opt.rtp:append(root)
local contract = require("back-to-basics.contract")

describe("btb contracts", function()
  for _, name in ipairs({ "today", "status", "hint" }) do
    it("finds the " .. name .. " sample within its contract", function()
      local schema, sample = contract.load(root, name)
      assert.are.same({}, contract.problems(schema, sample))
    end)
  end

  it("reads what is left of the sampled day", function()
    local _, today = contract.load(root, "today")
    local status = actions.day_status(today)
    assert.are.equal(today.streak, status.streak)
    assert.is_truthy(actions.day_line(status))
  end)

  it("draws the sampled path with every concept of the current level", function()
    local _, status = contract.load(root, "status")
    local lines = actions.path_map(status)
    local track = status.tracks[1]
    local text = table.concat(lines, "\n")
    assert.is_truthy(text:find(track.title, 1, true))
    for _, item in ipairs(track.levels[track.current].items) do
      assert.is_truthy(text:find(item.title, 1, true), item.title)
    end
  end)

  it("draws the sampled concepts as a map", function()
    local _, status = contract.load(root, "status")
    local lines = actions.concept_map(status.concepts)
    assert.is_truthy(table.concat(lines, "\n"):find(status.concepts[1].concept, 1, true))
  end)
end)
