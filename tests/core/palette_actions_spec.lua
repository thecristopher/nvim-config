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
    local entry = { name = "Map", desc = "Folders as rooms", key = "<leader>jm" }
    assert.equal("Map Folders as rooms <leader>jm", actions.search_text(entry))
  end)
end)

describe("with_bindings", function()
  local journey = { prefix = "j", name = "journey", icon = { icon = "J", color = "yellow" } }
  local function group_of(key)
    return key:sub(1, 1) == "j" and journey or nil
  end

  it("adds a row for a key the curated entries do not show", function()
    local all = actions.with_bindings({}, { { key = "jt", desc = "Title screen" } }, group_of)
    assert.same({
      icon = "J ",
      name = "Title screen",
      desc = "journey",
      key = "<leader>jt",
      feed = "<leader>jt",
    }, all[1])
  end)

  it("keeps Malenia's curated HUD row instead of repeating it", function()
    local hud = { name = "HUD", desc = "Inventory", key = "<leader>jh", cmd = "Hud" }
    local all = actions.with_bindings({ hud }, { { key = "jh", desc = "Inventory HUD" } }, group_of)
    assert.equal(1, #all)
  end)

  it("leaves out visual mode keys and the palette itself", function()
    local bindings = {
      { key = "cp", mode = "x", desc = "Snapshot the selection" },
      { key = "<leader>", desc = "Command palette" },
    }
    assert.same({}, actions.with_bindings({}, bindings, group_of))
  end)
end)

describe("wants_args with a fed key", function()
  it("never sends Claire's anniversary key to the command line", function()
    assert.is_false(actions.wants_args({ feed = "<leader>jt" }))
  end)
end)
