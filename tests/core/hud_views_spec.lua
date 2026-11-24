local roundtable = require("core.hud.views.roundtable")
local inventory = require("core.hud.views.inventory")
local wardrobe = require("core.hud.views.wardrobe")

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
        icon = "󱌣",
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

-- the zero based row where a text first shows up
local function line_of(view, needle)
  for index, line in ipairs(view.lines) do
    if line:find(needle, 1, true) then
      return index - 1
    end
  end
  return nil
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

  it("keeps the portrait on half of a laptop screen, like Inde snapping it aside", function()
    assert.is_truthy(render(model({ width = 79, height = 43, portrait = true })).anchors.portrait)
  end)

  it("keeps the portrait on the smallest laptop split, 80 by 24", function()
    assert.is_truthy(render(model({ width = 80, height = 24, portrait = true })).anchors.portrait)
  end)

  it("gives up grid slots so the portrait stays big beside a Claude split", function()
    local split = render(model({ width = 99, height = 39, portrait = true })).anchors.portrait
    assert.is_true(split.height >= 20)
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

  it("gives up the quest's changes before Malenia's inventory drops to one row", function()
    local small = roundtable.render(model({ width = 100, height = 30, portrait = true }))
    assert.is_true(small.plan.grid_rows >= roundtable.GRID_ROWS.comfort)
    assert.equal(0, small.plan.quest_rows)
  end)

  it("keeps the quest's changes when the screen has room for both", function()
    local roomy = roundtable.render(model({ width = 210, height = 56, portrait = true }))
    assert.is_true(roomy.plan.quest_rows > 0)
  end)

  it("titles the open tab and draws every tab icon", function()
    assert.is_truthy(text(view):find("Tools", 1, true))
    assert.is_truthy(text(view):find("󱌣", 1, true))
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

  it("carves Malenia's name right under a portrait standing above the inventory", function()
    local narrow = roundtable.render(model({ width = 79, height = 43, portrait = true }))
    local portrait = narrow.anchors.portrait
    assert.equal(portrait.row + portrait.height, line_of(narrow, "M  A  L  E  N  I  A"))
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
    assert.is_truthy(text(view):find("Raccoon City", 1, true))
  end)

  it("leaves the CONDITION monitor to the statusline", function()
    assert.is_falsy(text(view):find("CONDITION", 1, true))
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

  it("reserves the portrait's cells inside the STATUS frame", function()
    local framed = inventory.render(model({ portrait = true }))
    local portrait = framed.anchors.portrait
    local line = framed.lines[portrait.row + 1]
    local before = vim.fn.strcharpart(line, 0, portrait.col)
    local after = vim.fn.strcharpart(line, portrait.col + portrait.width)
    assert.is_truthy(before:find("║", 1, true))
    assert.is_truthy(after:find("║", 1, true))
  end)

  it("stands the portrait above the survivor when STATUS cannot fit beside the items", function()
    local narrow = inventory.render(model({ width = 60, portrait = true }))
    local portrait = narrow.anchors.portrait
    assert.is_truthy(portrait)
    assert.is_true(narrow.plan.stacked)
    assert.equal(portrait.row + portrait.height + 1, line_of(narrow, "CLAIRE REDFIELD"))
  end)

  it("lets the changed files go before the portrait on a short narrow screen", function()
    local short = inventory.render(model({ width = 70, height = 30, portrait = true }))
    assert.is_truthy(short.anchors.portrait)
    assert.equal(0, short.plan.change_rows)
  end)

  it("keeps the survivor when the screen is too small for any portrait", function()
    local cramped = inventory.render(model({ width = 60, height = 24, portrait = true }))
    assert.is_nil(cramped.anchors.portrait)
    assert.is_truthy(text(cramped):find("CLAIRE REDFIELD", 1, true))
  end)

  it("starts the plates on STATUS's top edge and ends DATA on its bottom edge", function()
    local wide = inventory.render(model({ width = 210, height = 56, portrait = true }))
    local status_top = line_of(wide, "STATUS")
    local plates = line_of(wide, "Tools")
    assert.equal(status_top, plates)
    -- the bottom of a frame is the last line with ╚ in the column its ╔ opened
    local function bottom_of(label)
      local top = line_of(wide, label) + 1
      local line = wide.lines[top]
      local column = vim.fn.strchars(line:sub(1, line:find(label, 1, true) - 1)) - 3
      local bottom
      for index = top, #wide.lines do
        if vim.fn.strcharpart(wide.lines[index], column, 1) == "╚" then
          bottom = index
        end
      end
      return bottom
    end
    assert.is_truthy(bottom_of("DATA"))
    assert.equal(bottom_of("STATUS"), bottom_of("DATA"))
  end)

  behaves_on_any_screen(inventory.render)
end)

describe("wardrobe", function()
  local view = wardrobe.render(model({ hub = "Dressing Room", character = "Scarlet Witch" }))

  it("hangs every tab from the rail and titles the open one", function()
    assert.is_truthy(line_of(view, "┳"))
    assert.is_truthy(line_of(view, "Tools"))
  end)

  it("lists every piece on the rack by name", function()
    assert.is_truthy(line_of(view, "Love letter"))
    assert.is_truthy(line_of(view, "Roses"))
  end)

  it("lists each stage with its branch", function()
    assert.equal(line_of(view, "haligtree"), line_of(view, "anniversary-dinner"))
  end)

  it("marks the selected piece and puts the cursor on its icon", function()
    local row = line_of(view, "▸")
    assert.equal(line_of(view, "Playlist"), row)
    assert.equal(row + 1, view.cursor.row)
  end)

  it("walks the rack one piece per row", function()
    assert.equal(1, view.grids.items.columns)
    assert.equal(3, view.grids.items.count)
  end)

  it("says so when the rack is empty", function()
    assert.is_truthy(line_of(wardrobe.render(model({ tab = 2 })), "Nothing here yet"))
  end)

  it("rings the mirror with hearts on the left of the rack and the stages", function()
    local roomy = wardrobe.render(model({ width = 200, height = 50, portrait = true }))
    assert.is_false(roomy.plan.stacked)
    assert.is_true(has_mark(roomy, "EldenHudHeart"))
    local mirror = roomy.anchors.portrait
    assert.is_true(
      mirror.col + mirror.width < roomy.plan.indent + roomy.plan.stage_width - roomy.plan.body_width
    )
  end)

  it("stands the mirror above both lists when they cannot fit beside it", function()
    local narrow = wardrobe.render(model({ width = 60, height = 50, portrait = true }))
    assert.is_true(narrow.plan.stacked)
    assert.is_true(narrow.anchors.portrait.row < line_of(narrow, "Love letter"))
  end)

  it("carves Malenia's name under the mirror", function()
    local roomy = wardrobe.render(model({ width = 200, height = 50, portrait = true }))
    local name = require("core.hub.actions").spaced("Malenia")
    assert.is_truthy(line_of(roomy, name))
  end)

  it("keeps her on the left beside a Claude split", function()
    local split = wardrobe.render(model({ width = 99, height = 39, portrait = true }))
    assert.equal("left", split.plan.shape)
    assert.equal(split.plan.indent, split.anchors.portrait.col - 2)
  end)

  it(
    "stands her whole figure on the left of a wide screen, the sign and the rail beside her",
    function()
      local wide =
        wardrobe.render(model({ width = 160, height = 48, portrait = true, figure = true }))
      assert.equal("left", wide.plan.shape)
      assert.equal(wide.plan.indent + 2, wide.anchors.portrait.col)
      assert.is_true(line_of(wide, "R O U N D T A B L E") < line_of(wide, "Current Quest"))
    end
  )

  it("gives her photo every row the mirror leaves", function()
    local wide =
      wardrobe.render(model({ width = 160, height = 48, portrait = true, figure = true }))
    local room = 48 - 2 - 3 - wardrobe.MIRROR_ROWS - wardrobe.NAME_ROWS
    assert.equal(room, wide.anchors.portrait.height)
  end)

  it("never lets her photo grow past its tallest", function()
    local huge =
      wardrobe.render(model({ width = 400, height = 120, portrait = true, figure = true }))
    assert.equal(wardrobe.PORTRAIT.max, huge.anchors.portrait.height)
  end)

  it("never gives her less than the share of the tallest photo any shape allows", function()
    for _, size in ipairs({ { 120, 40 }, { 160, 48 }, { 200, 50 }, { 99, 39 } }) do
      local view = wardrobe.render(
        model({ width = size[1], height = size[2], portrait = true, figure = true })
      )
      local room = size[2] - 2 - 3 - wardrobe.MIRROR_ROWS - wardrobe.NAME_ROWS
      assert.is_true(
        view.anchors.portrait.height >= math.floor(room * wardrobe.LEFT_SHARE),
        size[1] .. "x" .. size[2]
      )
    end
  end)

  it("shows her whole figure, taller than wide, when the region has one", function()
    local mirror = wardrobe.render(
      model({ width = 200, height = 50, portrait = true, figure = true })
    ).anchors.portrait
    assert.is_true(mirror.height * 2 > mirror.width * 1.5)
  end)

  it("frames a figure narrower than a portrait of the same height", function()
    local portrait = wardrobe.render(model({ width = 200, height = 50, portrait = true }))
    local figure =
      wardrobe.render(model({ width = 200, height = 50, portrait = true, figure = true }))
    assert.is_true(figure.plan.mirror_width < portrait.plan.mirror_width)
  end)

  it("leaves the mirror out when the terminal cannot draw it", function()
    assert.is_nil(view.anchors.portrait)
    assert.is_false(has_mark(view, "EldenHudDesk"))
  end)

  it("rings the marquee sign over the rail with hearts", function()
    assert.is_true(line_of(view, "D R E S S I N G") < line_of(view, "┳"))
    assert.is_truthy(view.lines[line_of(view, "D R E S S I N G") + 1]:find(wardrobe.HEART, 1, true))
  end)

  it("tells which tab hangs out of how many", function()
    assert.is_truthy(line_of(view, "1 / 2"))
  end)

  it("frames the rack in gold while it has the focus", function()
    local rack_top = line_of(view, "╭─ Tools")
    local gold = false
    for _, mark in ipairs(view.marks) do
      gold = gold or (mark[1] == rack_top and mark[4] == "EldenHudFrameSel")
    end
    assert.is_true(gold)
  end)

  it("counts what is left under the rack when it does not all fit", function()
    local many = {}
    for index = 1, 30 do
      many[index] = item("Love note " .. index)
    end
    local tabs = { { title = "Tools", icon = "󱌣", items = many } }
    local crowded = wardrobe.render(model({ width = 120, height = 32, tabs = tabs }))
    assert.is_truthy(line_of(crowded, "▼ "))
  end)

  it("describes the selected piece in its close up", function()
    local close_up = line_of(view, "Close up")
    assert.is_truthy(view.lines[close_up + 2]:find("Playlist", 1, true))
  end)

  behaves_on_any_screen(wardrobe.render)
end)

describe("typewriter and player", function()
  local views = { roundtable = roundtable, inventory = inventory, wardrobe = wardrobe }
  local song = {
    title = "Lullaby for Malenia",
    artist = "Inde Navarrete",
    elapsed = 60,
    duration = 120,
    playing = true,
    bar = { done = "━", head = "◈", left = "─" },
  }

  for name, view in pairs(views) do
    it(name .. " types the Playlist note in a few letters at a time", function()
      local typing = text(view.render(model({ typed = 6 })))
      assert.is_truthy(typing:find("A note", 1, true))
      assert.is_falsy(typing:find("A note for", 1, true))
      assert.is_truthy(text(view.render(model())):find("A note for Inde", 1, true))
    end)

    it(name .. " shows the song Claire is playing", function()
      local playing = view.render(model({ music = song, stats = "Neovim 0.12" }))
      assert.is_truthy(text(playing):find("Lullaby for Malenia", 1, true))
      assert.is_true(has_mark(playing, "EldenMusicBarHead"))
    end)
  end

  it("lets the song take the stats' row and gives it back when the music stops", function()
    assert.is_falsy(
      text(roundtable.render(model({ music = song, stats = "Neovim 0.12" }))):find(
        "Neovim 0.12",
        1,
        true
      )
    )
    assert.is_truthy(
      text(roundtable.render(model({ stats = "Neovim 0.12" }))):find("Neovim 0.12", 1, true)
    )
  end)
end)

describe("image_for", function()
  local actions = require("core.hud.actions")
  local westview =
    { portrait = "elizabeth_scarlet_witch.jpg", figure = "elizabeth_scarlet_witch_figure.jpg" }

  it("hands the dressing room her whole figure", function()
    assert.same(
      { "elizabeth_scarlet_witch_figure.jpg", true },
      { actions.image_for(westview, true) }
    )
  end)

  it("keeps the portrait for views that frame a face", function()
    assert.same({ "elizabeth_scarlet_witch.jpg", false }, { actions.image_for(westview, false) })
  end)

  it("falls back to Malenia's portrait when she has no figure", function()
    assert.same({ "malenia.jpg", false }, { actions.image_for({ portrait = "malenia.jpg" }, true) })
  end)
end)

describe("words", function()
  local parts = require("core.hud.views.parts")

  it("speaks the plain line when the model brings no words", function()
    assert.equal("Current Quest", parts.word({}, "quest"))
  end)

  it("speaks the franchise's word when the model brings one", function()
    assert.equal("Tonight's Scene", parts.word({ words = { quest = "Tonight's Scene" } }, "quest"))
  end)

  it("fills the sites into the plain line", function()
    assert.is_truthy(parts.word({ sites = "Stages" }, "no_quest"):find("Stages", 1, true))
  end)

  it("writes the hints in the franchise's words", function()
    local hints = parts.hints(
      { words = { hint_use = "Wear" } },
      { { "⏎", "use" }, { "q", "quit" } }
    )
    assert.same({ "⏎ Wear", "q Quit" }, hints)
  end)

  it("titles the dressing room's call sheet with Elizabeth's words", function()
    local view =
      wardrobe.render(model({ words = { quest = "Tonight's Scene", hint_use = "Wear" } }))
    assert.is_truthy(line_of(view, "Tonight's Scene"))
    assert.is_truthy(line_of(view, "⏎ Wear"))
  end)
end)

describe("each world's own look", function()
  it("lays the Roundtable's item out with its category and a line of lore", function()
    local tools = {
      {
        title = "Tools",
        icon = "󱌣",
        items = {
          item(
            "Seek the Realm",
            { category = "Tool", flavor = "Even a lost letter leaves a trace." }
          ),
        },
      },
    }
    local view = roundtable.render(model({ tabs = tools, cursor = { items = 1, chest = 1 } }))
    local name_row = view.lines[line_of(view, " Seek the Realm") + 1]
    assert.is_truthy(vim.trim(name_row):match("Tool$"))
    assert.is_truthy(line_of(view, "Even a lost letter leaves a trace."))
    assert.is_true(has_mark(view, "EldenHudFlavor"))
  end)

  it("keeps the runes held in the Roundtable's corner", function()
    local view = roundtable.render(model())
    assert.equal(line_of(view, "R O U N D T A B L E"), line_of(view, "₧ 600"))
  end)

  it("runs the glint along Malenia's selected frame", function()
    assert.is_true(has_mark(roundtable.render(model({ glint = 0.5 })), "EldenHudGlint"))
    assert.is_false(has_mark(roundtable.render(model()), "EldenHudGlint"))
  end)

  it("stands Malenia's attributes under her plaque on a tall screen", function()
    local attributes = { { "Level", "S" }, { "Vigor", "14" }, { "Mind", "2" }, { "Arcane", "5" } }
    local tall = roundtable.render(
      model({ width = 220, height = 70, portrait = true, attributes = attributes })
    )
    assert.is_true(tall.plan.attributes)
    assert.is_truthy(line_of(tall, "Vigor"))
  end)

  it("gives the attributes the footer's row when the plaque has no room for them", function()
    local attributes = { { "Level", "S" }, { "Vigor", "14" } }
    local short = roundtable.render(
      model({ width = 140, height = 45, portrait = true, attributes = attributes })
    )
    assert.is_false(short.plan.attributes)
    assert.is_truthy(line_of(short, "Vigor"))
  end)

  it("never cuts a word on Malenia's plaque, however narrow it gets", function()
    local attributes = { { "Level", "C" }, { "Runes", "0" }, { "Vigor", "1" }, { "Mind", "1" } }
    for _, size in ipairs({ { 75, 30 }, { 90, 26 }, { 110, 30 }, { 190, 50 } }) do
      local view = roundtable.render(model({
        width = size[1],
        height = size[2],
        portrait = true,
        attributes = attributes,
        greeting = "The night is long, Tarnished",
        date = "Monday 16 November  ·  00:59",
        date_short = "Mon 16  ·  00:59",
        date_day = "Mon 16",
        clock = "00:59",
      }))
      for _, line in ipairs(view.lines) do
        local cut = line:find("…", 1, true)
          and (line:find("Mon", 1, true) or line:find("night", 1, true) or line:find("Le", 1, true))
        assert.is_falsy(cut, ("%dx%d: %s"):format(size[1], size[2], line))
      end
    end
  end)

  it("lets the greeting go when it cannot fit whole in two rows", function()
    local view = roundtable.render(model({
      width = 75,
      height = 30,
      portrait = true,
      greeting = "The night is long, Tarnished",
    }))
    if view.plan.portrait and view.plan.portrait.width < 14 then
      assert.is_falsy(line_of(view, "The night is"))
    end
  end)

  it("draws Claire's attaché case as one lattice of shared walls", function()
    local case = {
      {
        title = "ITEM",
        items = {
          item("Love letter", { size = { w = 2, h = 1 } }),
          item("Playlist", { count = 12 }),
          item("Roses"),
        },
      },
    }
    local view = inventory.render(model({ tabs = case, width = 160 }))
    local drawn = text(view)
    assert.is_truthy(drawn:find("╦", 1, true))
    assert.is_truthy(drawn:find("╬", 1, true))
    assert.is_true(has_mark(view, "EldenHudAmmo"))
    assert.is_true(has_mark(view, "EldenHudCase"))
    assert.truthy(view.grids.items.case)
  end)

  it("prints the survivor's condition under her name in STATUS", function()
    local view =
      inventory.render(model({ condition = { word = "CAUTION", hl = "EldenHudCaution" } }))
    assert.is_truthy(line_of(view, "CAUTION"))
    assert.is_true(has_mark(view, "EldenHudCaution"))
  end)

  it("counts the ink ribbons on the banner and strikes the typewriter's caret", function()
    local view =
      inventory.render(model({ ribbons = { word = "INK RIBBON", count = 3 }, typed = 4 }))
    assert.is_truthy(line_of(view, "INK RIBBON ×3"))
    assert.is_truthy(line_of(view, "A no▌"))
  end)

  it("keeps accents whole when the banner spaces a name", function()
    local files = { { title = "FILE", items = { item("Cuándo disparar") } } }
    local view = inventory.render(model({ tabs = files, cursor = { items = 1, chest = 1 } }))
    assert.is_truthy(line_of(view, "C U Á N D O"))
  end)

  it("fills Elizabeth's call sheet with scene, cast, location and call", function()
    local view = wardrobe.render(model({
      character = "Scarlet Witch",
      session_start = "21:40",
      hud = { stats = { scene = "SCENE", cast = "CAST", location = "LOCATION", call = "CALL" } },
    }))
    assert.equal(line_of(view, "SCENE"), line_of(view, "feature/claire-and-inde"))
    assert.equal(line_of(view, "CAST"), line_of(view, "Scarlet Witch"))
    assert.equal(line_of(view, "LOCATION"), line_of(view, "love-letters"))
    assert.is_truthy(line_of(view, "since 21:40"))
  end)

  it("starts every stage's branch in the same column", function()
    local chest = {
      title = "Stages",
      items = {
        item("haligtree", { key = "1", branch = "anniversary-dinner" }),
        item("raccoon-city-letters", { key = "2", branch = "first-date" }),
      },
    }
    local view = wardrobe.render(model({ chest = chest, width = 160 }))
    local function column_of(needle)
      local line = view.lines[line_of(view, needle) + 1]
      return vim.api.nvim_strwidth(line:sub(1, line:find(needle, 1, true) - 1))
    end
    assert.equal(column_of("anniversary"), column_of("first-da"))
  end)

  it("lets the spotlight spill onto the pieces beside the selected one", function()
    assert.is_true(has_mark(wardrobe.render(model()), "EldenHudSpotNear"))
  end)
end)

describe("whole words", function()
  local hud = require("core.hud.actions")

  it("cuts Inde's branch only where it breaks", function()
    assert.equal("bugfix/…", hud.fit_words("bugfix/elizabeth-portraits", 12))
    assert.equal("bugfix/elizabeth-…", hud.fit_words("bugfix/elizabeth-portraits", 19))
    assert.is_nil(hud.fit_words("anniversary", 5))
  end)

  it("shortens the date to the day before it would cut it", function()
    assert.equal("Mon 16", hud.first_fit({ "Monday 16 November", "Mon 16" }, 10))
    assert.is_nil(hud.first_fit({ "Monday 16 November" }, 5))
  end)

  it("keeps Claire's greeting whole in two rows or not at all", function()
    assert.same(
      { "The night is", "long, Claire" },
      hud.wrap_whole("The night is long, Claire", 12, 2)
    )
    assert.is_nil(hud.wrap_whole("The night is long, Claire", 8, 2))
  end)

  it("ends a long letter to Malenia on a whole word", function()
    local lines = hud.wrap_rows("one two three four five six", 9, 2)
    assert.same({ "one two", "three…" }, lines)
  end)

  it("knows when Malenia's attributes fit whole beside each other", function()
    assert.is_true(hud.stat_rows_fit({ { "Vigor", "14" } }, 22))
    assert.is_false(hud.stat_rows_fit({ { "Endurance", "120" } }, 13))
  end)

  it("keeps the stage's name whole and lets its branch go on a narrow rack", function()
    local chest = {
      title = "Stages",
      items = {
        item("nvim-config", { key = "1", branch = "bugfix/elizabeth-portraits", count = 201 }),
      },
    }
    local view = wardrobe.render(model({ chest = chest, width = 75, height = 30 }))
    assert.is_truthy(line_of(view, "nvim-config"))
    assert.is_falsy(line_of(view, "nvim-conf…"))
    assert.is_falsy(line_of(view, " b…"))
  end)

  it("drops the changes from the call time before cutting it", function()
    local view = wardrobe.render(model({ width = 75, height = 30, session_start = "00:59" }))
    for _, line in ipairs(view.lines) do
      if line:find("since", 1, true) then
        assert.is_falsy(line:find("…", 1, true), line)
      end
    end
  end)
end)

describe("forms that do not apply", function()
  it("skips a date form left out and lands on Malenia's hour", function()
    local hud = require("core.hud.actions")
    assert.equal("00:59", hud.first_fit({ nil, "Mon 16  ·  00:59", nil, "00:59" }, 6))
  end)
end)
