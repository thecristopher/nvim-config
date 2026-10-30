local actions = require("core.palette.actions")

describe("ENTRIES", function()
  it("gives every entry a name, a description and a command", function()
    for _, entry in ipairs(actions.ENTRIES) do
      assert.is_truthy(entry.name ~= "" and entry.desc ~= "" and entry.cmd ~= "", entry.name)
    end
  end)

  it("never lists the same key twice", function()
    local seen = {}
    for _, entry in ipairs(actions.ENTRIES) do
      if entry.key then
        assert.is_nil(seen[entry.key], entry.key)
        seen[entry.key] = true
      end
    end
  end)
end)

describe("wants_args", function()
  it("sends Claire's sound preview to the command line for its event", function()
    assert.is_true(actions.wants_args({ cmd = "Sound " }))
  end)

  it("runs Malenia's map right away", function()
    assert.is_false(actions.wants_args({ cmd = "Map" }))
  end)
end)

describe("search_text", function()
  it("matches on the name, what it does and the key", function()
    local entry = { name = "Map", desc = "Folders as rooms", key = "<leader>fM" }
    assert.equal("Map Folders as rooms <leader>fM", actions.search_text(entry))
  end)
end)
