local later = require("core.later.actions")

describe("pending", function()
  it("keeps the queue order for Claire's plugins still waiting", function()
    local plugins = { ["noice.nvim"] = { _ = {} }, ["flash.nvim"] = { _ = {} } }
    assert.same(
      { "noice.nvim", "flash.nvim" },
      later.pending(plugins, { "noice.nvim", "flash.nvim" })
    )
  end)

  it("skips a plugin Malenia's keys already loaded", function()
    local plugins = { ["flash.nvim"] = { _ = { loaded = { time = 1 } } } }
    assert.same({}, later.pending(plugins, { "flash.nvim" }))
  end)

  it("skips a plugin this machine does not have, like Inde's back-to-basics clone", function()
    assert.same({}, later.pending({}, { "back-to-basics" }))
  end)
end)
