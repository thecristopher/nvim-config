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

describe("column_widths", function()
  it("takes the longest name and description", function()
    local entries = {
      { name = "HUD", desc = "The inventory" },
      { name = "Chronicle", desc = "Claire and Inde's weeks" },
    }
    assert.same({ name = 9, desc = 23, key = 0 }, actions.column_widths(entries))
  end)

  it("never grows past its cap", function()
    local entries = { { name = ("Malenia"):rep(10), desc = ("blade of Miquella "):rep(10) } }
    local widths = actions.column_widths(entries)
    assert.equal(actions.MAX_NAME, widths.name)
    assert.equal(actions.MAX_DESC, widths.desc)
  end)
end)

describe("fit", function()
  it("pads a short name to its column", function()
    assert.equal("HUD   ", actions.fit("HUD", 6))
  end)

  it("cuts a long description with an ellipsis and keeps the width", function()
    local fitted = actions.fit("A love letter from Inde to Claire", 12)
    assert.equal("A love lett…", fitted)
    assert.equal(12, vim.fn.strdisplaywidth(fitted))
  end)

  it("counts wide characters by their cells", function()
    assert.equal(6, vim.fn.strdisplaywidth(actions.fit("₧ 453", 6)))
  end)
end)

describe("column_widths keys", function()
  it("measures the longest key", function()
    local entries =
      { { name = "HUD", desc = "x", key = "<leader>jh" }, { name = "Map", desc = "y" } }
    assert.equal(10, actions.column_widths(entries).key)
  end)
end)

describe("window_width", function()
  it("fits every column of Claire's palette", function()
    assert.equal(10 + 30 + 10 + 12, actions.window_width({ name = 10, desc = 30, key = 10 }, 200))
  end)

  it("never runs wider than the screen", function()
    assert.equal(76, actions.window_width({ name = 22, desc = 42, key = 12 }, 80))
  end)
end)

describe("command_names", function()
  it("reads the commands Claire's module defines, on one line or two", function()
    local source = table.concat({
      'vim.api.nvim_create_user_command("Anniversary", open, {})',
      "vim.api.nvim_create_user_command(",
      '  "LoveNote",',
      "  write,",
    }, "\n")
    assert.same({ "Anniversary", "LoveNote" }, actions.command_names(source))
  end)
end)

describe("missing_commands", function()
  local entries = { { cmd = "Anniversary" }, { cmd = "Music " } }

  it("finds the command Inde added without a palette row", function()
    assert.same(
      { "LoveNote" },
      actions.missing_commands({ "Anniversary", "Music", "LoveNote" }, entries, {})
    )
  end)

  it("respects the commands Malenia keeps out on purpose", function()
    assert.same({}, actions.missing_commands({ "LoveNote" }, entries, { LoveNote = "internal" }))
  end)
end)

describe("every core command", function()
  it("has a palette row or a reason to stay out", function()
    local names = {}
    for _, file in ipairs(vim.fn.globpath("lua/core", "**/*.lua", false, true)) do
      vim.list_extend(names, actions.command_names(table.concat(vim.fn.readfile(file), "\n")))
    end
    assert.is_true(#names > 20)
    assert.same({}, actions.missing_commands(names, actions.ENTRIES, actions.UNLISTED))
  end)
end)
