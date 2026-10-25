local roundtable = require("core.hud.views.roundtable")
local inventory = require("core.hud.views.inventory")

local function item(name, extra)
  return vim.tbl_extend(
    "force",
    { icon = "◈", name = name, desc = "A note for Inde about " .. name },
    extra or {}
  )
end

local function model(overrides)
  return vim.tbl_extend("force", {
    width = 140,
    height = 45,
    tab = 1,
    focus = "items",
    cursor = { items = 2, chest = 1 },
    offset = { items = 0, chest = 0 },
    tabs = {
      {
        title = "Tools",
        icon = "⚒",
        items = {
          item("Love letter", { key = "f" }),
          item("Playlist", { count = 12 }),
          item("Roses"),
        },
      },
      { title = "Recent", icon = "◈", items = {} },
    },
    chest = {
      title = "Sites of Grace",
      items = { item("haligtree", { key = "1", branch = "anniversary-dinner", count = 3 }) },
    },
    message = '"Praise the green test!"',
    character = "Malenia",
    area = "Haligtree",
    hub = "Roundtable Hold",
    sites = "Sites of Grace",
    greeting = "Good evening, Inde",
    date = "Saturday, October 24",
    status = {
      character = "Claire Redfield",
      area = "Raccoon City",
      purse = "₧ 600",
      project = "love-letters",
      branch = "feature/claire-and-inde",
      last_file = "notes/anniversary.md",
      last_ready = true,
      changes = { " M notes/anniversary.md", "?? playlists/road-trip.txt" },
    },
  }, overrides or {})
end

local function has_mark(view, group)
  for _, mark in ipairs(view.marks) do
    if mark[4] == group then
      return true
    end
  end
  return false
end

local function text(view)
  return table.concat(view.lines, "\n")
end

describe("changes", function()
  it("shows the page holding the selected change instead of counting the rest", function()
    local parts = require("core.hud.views.parts")
    local many = {}
    for index = 1, 9 do
      many[index] = (" M letters/claire-%d.md"):format(index)
    end
    local drawn =
      table.concat(require("core.hud.actions").compose(parts.changes(many, 60, 2, 6)), "\n")
    assert.is_truthy(drawn:find("claire-6.md", 1, true))
    assert.is_falsy(drawn:find("more", 1, true))
  end)

  local parts = require("core.hud.views.parts")
  local lines = {
    " M notes/claire.md",
    " M notes/inde.md",
    "?? playlists/malenia.txt",
    " M dates/october.md",
    " D old/letters.md",
  }

  it("fills two columns and counts what did not fit in the last cell", function()
    local drawn =
      table.concat(require("core.hud.actions").compose(parts.changes(lines, 60, 2)), "\n")
    assert.is_truthy(drawn:find("notes/claire.md", 1, true))
    assert.is_truthy(drawn:find("+2 more", 1, true))
    assert.is_falsy(drawn:find("old/letters.md", 1, true))
  end)

  it("never runs past its width", function()
    for _, line in ipairs(require("core.hud.actions").compose(parts.changes(lines, 60, 2))) do
      assert.is_true(vim.api.nvim_strwidth(line) <= 60)
    end
  end)
end)

local function widest(view)
  local width = 0
  for _, line in ipairs(view.lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end
  return width
end

-- what every hub owes the screen, whichever franchise draws it
local function behaves_on_any_screen(render)
  it("centers the stage, the same margin on both sides", function()
    local view = render(model({ width = 200, portrait = true }))
    local plan = view.plan
    assert.is_true(math.abs((200 - plan.stage_width - plan.indent) - plan.indent) <= 1)
  end)

  it("never draws past the edge, from a laptop split to an ultrawide", function()
    for _, size in ipairs({ { 80, 24 }, { 80, 30 }, { 100, 35 }, { 140, 45 }, { 220, 60 } }) do
      local view = render(model({ width = size[1], height = size[2], portrait = true }))
      assert.is_true(widest(view) <= size[1], ("too wide at %dx%d"):format(size[1], size[2]))
      assert.is_true(#view.lines <= size[2], ("too tall at %dx%d"):format(size[1], size[2]))
    end
  end)

  it("keeps the portrait on a laptop screen", function()
    assert.is_truthy(render(model({ width = 110, height = 35, portrait = true })).anchors.portrait)
  end)

  it("grows the portrait on a taller screen", function()
    local small = render(model({ width = 200, height = 40, portrait = true })).anchors.portrait
    local tall = render(model({ width = 200, height = 60, portrait = true })).anchors.portrait
    assert.is_true(tall.height > small.height)
  end)

  it("keeps the same shape on every tab, so switching never shakes the screen", function()
    local first = render(model({ portrait = true }))
    local empty = render(model({ portrait = true, tab = 2 }))
    assert.equal(#first.lines, #empty.lines)
    assert.same(first.anchors.portrait, empty.anchors.portrait)
  end)

  it("shows the quest Claire and Inde left open", function()
    local drawn = text(render(model()))
    assert.is_truthy(drawn:find("love-letters", 1, true))
    assert.is_truthy(drawn:find("feature/claire-and-inde", 1, true))
    assert.is_truthy(drawn:find("2 changed", 1, true))
    assert.is_truthy(drawn:find("notes/anniversary.md", 1, true))
    assert.is_truthy(drawn:find("playlists/road-trip.txt", 1, true))
  end)

  it("tells how to walk into the quest", function()
    assert.is_truthy(text(render(model())):find("j ", 1, true))
  end)

  it("puts the cursor on the last file when the quest takes the focus", function()
    local view = render(model({ focus = "quest", cursor = { items = 1, chest = 1, quest = 1 } }))
    assert.is_truthy(
      view.lines[view.cursor.row]:find("anniversary.md", 1, true)
        or view.lines[view.cursor.row]:find("last", 1, true)
    )
    assert.equal(3, view.grids.quest.count)
  end)

  it("walks on to Inde's playlist among the changes", function()
    local view = render(model({ focus = "quest", cursor = { items = 1, chest = 1, quest = 3 } }))
    assert.is_truthy(view.lines[view.cursor.row]:find("playlists/road-trip.txt", 1, true))
  end)

  it("writes the message whole, so the quill can find it", function()
    assert.is_truthy(text(render(model())):find('"Praise the green test!"', 1, true))
  end)
end

describe("roundtable", function()
  local view = roundtable.render(model())

  it("titles the open tab and draws every tab icon", function()
    assert.is_truthy(text(view):find("Tools", 1, true))
    assert.is_truthy(text(view):find("⚒", 1, true))
  end)

  it("frames the selected slot in heavy gold", function()
    assert.is_truthy(text(view):find("┏", 1, true))
    assert.is_true(has_mark(view, "EldenHudFrameSel"))
  end)

  it("prints a slot's count in its frame", function()
    assert.is_truthy(
      text(view):find("─12─┘", 1, true) or text(view):find("━12━┛", 1, true)
    )
  end)

  it("names every item in its slot, not only the selected one", function()
    assert.is_truthy(text(view):find("Love letter", 1, true))
    assert.is_truthy(text(view):find("Roses", 1, true))
  end)

  it("lists each site of grace with its branch and changes", function()
    assert.is_truthy(text(view):find("haligtree", 1, true))
    assert.is_truthy(text(view):find("anniversary-dinner", 1, true))
    assert.is_truthy(text(view):find("● 3", 1, true))
  end)

  it("carves the champion's name under the portrait", function()
    local drawn = text(roundtable.render(model({ width = 200, portrait = true })))
    assert.is_truthy(drawn:find("M  A  L  E  N  I  A", 1, true))
    assert.is_truthy(drawn:find("Good evening, Inde", 1, true))
  end)

  it("describes the selected item underneath", function()
    assert.is_truthy(text(view):find("A note for Inde about Playlist", 1, true))
  end)

  it("puts the cursor on the selected slot's icon", function()
    local line = view.lines[view.cursor.row]
    assert.equal("◈", vim.fn.strcharpart(line, view.cursor.col, 1))
  end)

  it("knows how many slots each row holds, so hjkl can walk them", function()
    assert.equal(3, view.grids.items.count)
    assert.is_true(view.grids.items.columns >= 3)
  end)

  it("says so when a tab is empty", function()
    assert.is_truthy(text(roundtable.render(model({ tab = 2 }))):find("Nothing here yet", 1, true))
  end)

  it("leaves the portrait out when the terminal cannot draw it", function()
    assert.is_nil(view.anchors.portrait)
    assert.is_truthy(roundtable.render(model({ width = 180, portrait = true })).anchors.portrait)
  end)

  behaves_on_any_screen(roundtable.render)
end)

describe("inventory", function()
  local view = inventory.render(model())

  it("opens the STATUS panel with the survivor's data", function()
    assert.is_truthy(text(view):find("STATUS", 1, true))
    assert.is_truthy(
      text(view):find("C  L  A  I  R  E", 1, true) or text(view):find("C L A I R E", 1, true)
    )
    assert.is_truthy(text(view):find("CONDITION", 1, true))
  end)

  it("raises the selected item's name in the banner", function()
    assert.is_truthy(text(view):find("P L A Y L I S T", 1, true))
  end)

  it("hides the COMMAND menu until Enter opens it", function()
    assert.is_falsy(text(view):find("COMMAND", 1, true))
    local menu = {
      index = 2,
      entries = {
        { label = "EQUIP", enabled = true },
        { label = "CHECK", enabled = true },
        { label = "COMBN", enabled = false },
      },
    }
    local opened = text(inventory.render(model({ menu = menu })))
    assert.is_truthy(opened:find("COMMAND", 1, true))
    assert.is_truthy(opened:find("▶CHECK", 1, true))
  end)

  it("puts the cursor on the selected slot's icon", function()
    local line = view.lines[view.cursor.row]
    assert.equal("◈", vim.fn.strcharpart(line, view.cursor.col, 1))
  end)

  it("points the ECG monitor inside the CONDITION box", function()
    local line = view.lines[view.anchors.ecg.row + 1]
    assert.equal("│", vim.fn.strcharpart(line, view.anchors.ecg.col - 2, 1))
  end)

  it("reserves the portrait's cells inside the STATUS frame", function()
    local framed = inventory.render(model({ portrait = true }))
    local portrait = framed.anchors.portrait
    local line = framed.lines[portrait.row + 1]
    local before = vim.fn.strcharpart(line, 0, portrait.col)
    local after = vim.fn.strcharpart(line, portrait.col + portrait.width)
    assert.is_truthy(before:find("║", 1, true))
    assert.is_truthy(after:find("║", 1, true))
  end)

  it("drops the portrait but keeps the survivor on a narrow screen", function()
    local narrow = inventory.render(model({ width = 80, portrait = true }))
    assert.is_nil(narrow.anchors.portrait)
    assert.is_truthy(text(narrow):find("CLAIRE REDFIELD", 1, true))
    assert.is_truthy(narrow.anchors.ecg)
  end)

  behaves_on_any_screen(inventory.render)
end)
