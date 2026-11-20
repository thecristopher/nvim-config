local actions = require("core.chrome.actions")

local chrome = {
  modes = { normal = "SURVIVE", insert = "TYPE", visual = "AIM", command = "RADIO" },
  notify = { info = "Radio", error = "Danger" },
  cmdline = "Typewriter",
  search = "Search",
}

describe("mode_label", function()
  it("calls Claire's normal mode SURVIVE", function()
    assert.equal("SURVIVE", actions.mode_label("n", chrome))
  end)

  it("folds visual line and block into AIM", function()
    assert.equal("AIM", actions.mode_label("V", chrome))
    assert.equal("AIM", actions.mode_label("\22", chrome))
  end)

  it("falls back to the plain name when the franchise has none", function()
    assert.equal("TERMINAL", actions.mode_label("t", chrome))
  end)
end)

describe("notify_title", function()
  it("keeps the title Malenia gave her message", function()
    assert.equal("Scarlet Rot", actions.notify_title("Scarlet Rot", "error", chrome))
  end)

  it("names an untitled error the franchise's way", function()
    assert.equal("Danger", actions.notify_title("", "error", chrome))
  end)

  it("reads numeric levels too", function()
    assert.equal("Radio", actions.notify_title(nil, vim.log.levels.INFO, chrome))
  end)
end)

describe("number_group", function()
  it("leaves the cursor line to CursorLineNr", function()
    assert.is_nil(actions.number_group(0))
  end)

  it("fades with the distance and stops at the last step", function()
    assert.equal("EldenNr1", actions.number_group(1))
    assert.equal("EldenNr5", actions.number_group(42))
  end)
end)

describe("number_color", function()
  local themes = require("core.themes.actions")
  local malenia = themes.find("haligtree").palette

  it("keeps the farthest number Malenia jumps to readable", function()
    local far = actions.number_color(malenia, #actions.GUTTER_STEPS)
    assert.is_true(themes.contrast(far, malenia.base) >= actions.GUTTER_FLOOR)
  end)

  it("still fades the numbers away from Malenia's cursor", function()
    local near = themes.contrast(actions.number_color(malenia, 2), malenia.base)
    local far = themes.contrast(actions.number_color(malenia, #actions.GUTTER_STEPS), malenia.base)
    assert.is_true(near > far)
  end)
end)

describe("paint_number", function()
  it("colors the number snacks put in the column", function()
    local column = "%@click@  %=12 %#GitSign#▎%T"
    assert.equal("%@click@  %=%#EldenNr2#12 %*%#GitSign#▎%T", actions.paint_number(column, 2))
  end)

  it("leaves the cursor line alone", function()
    assert.equal("%=7 ", actions.paint_number("%=7 ", 0))
  end)
end)

describe("frame_layout", function()
  local layout = {
    layout = {
      box = "horizontal",
      { box = "vertical", title = "{title} {live} {flags}" },
      { win = "preview", title = "{preview}" },
    },
  }

  it("frames Inde's picker title in the ornaments", function()
    local framed = actions.frame_layout(layout, { "▐ ", " ▌" }, "Examine")
    assert.equal("▐ {title} ▌ {live} {flags}", framed.layout[1].title)
    assert.equal("center", framed.layout[1].title_pos)
  end)

  it("names an empty preview the franchise's way", function()
    local framed = actions.frame_layout(layout, { "◈ ", " ◈" }, "Inspect")
    assert.equal("◈ {preview:Inspect} ◈", framed.layout[2].title)
  end)

  it("leaves the layout it was given untouched", function()
    actions.frame_layout(layout, { "▐ ", " ▌" }, "Examine")
    assert.equal("{preview}", layout.layout[2].title)
  end)
end)

describe("cmdline_formats", function()
  it("titles the command line and marks it with the skin's glyph", function()
    local formats = actions.cmdline_formats(
      chrome,
      { icon = "󰌌", search = "󰍉" },
      { "▐ ", " ▌" }
    )
    assert.equal(" ▐ Typewriter ▌ ", formats.cmdline.title)
    assert.equal("󰌌", formats.cmdline.icon)
    assert.equal(" ▐ Search ▌ ", formats.search_up.title)
  end)
end)

describe("ruler_limit", function()
  it("follows the buffer's textwidth when Claire set one for her letters", function()
    assert.equal(72, actions.ruler_limit(72))
  end)

  it("falls back to the default when there is none", function()
    assert.equal(actions.RULER_DEFAULT, actions.ruler_limit(0))
  end)
end)

describe("overflow_pattern", function()
  it("matches what runs past the limit", function()
    assert.equal([[\%>100v.\+]], actions.overflow_pattern(100))
  end)

  it("catches the overflow of Inde's long love note and nothing before it", function()
    local line = ("x"):rep(100) .. " and one more promise"
    local start = vim.fn.match(line, actions.overflow_pattern(100))
    assert.equal(100, start)
  end)

  it("leaves a line that fits alone", function()
    assert.equal(-1, vim.fn.match(("x"):rep(100), actions.overflow_pattern(100)))
  end)
end)

describe("number_group out of focus", function()
  it("dims every number of a window Claire is not looking at", function()
    assert.equal("EldenNr" .. #actions.GUTTER_STEPS, actions.number_group(1, false))
  end)

  it("dims the cursor line number too", function()
    assert.equal("EldenNr" .. #actions.GUTTER_STEPS, actions.number_group(0, false))
  end)

  it("keeps the fade in the window in focus", function()
    assert.equal("EldenNr1", actions.number_group(1, true))
  end)
end)

describe("paint_number out of focus", function()
  it("paints Inde's cursor line in the faint step when she looks away", function()
    assert.equal("%=%#EldenNr5#7 %*", actions.paint_number("%=7 ", 0, false))
  end)
end)

describe("language_label", function()
  it("names the language servers next to the filetype icon", function()
    assert.equal("󰢱 lua_ls", actions.language_label("󰢱", "lua", { "lua_ls" }))
  end)

  it("keeps copilot out of Claire's label", function()
    assert.equal(
      "󰛦 vtsls eslint",
      actions.language_label("󰛦", "typescript", { "copilot", "vtsls", "eslint" })
    )
  end)

  it("falls back to the filetype while no server is attached", function()
    assert.equal("\u{F048A} markdown", actions.language_label("\u{F048A}", "markdown", {}))
  end)

  it("says nothing for an empty buffer", function()
    assert.equal("", actions.language_label("", "", {}))
  end)

  it("drops the icon when the filetype has none", function()
    assert.equal("inde_notes", actions.language_label("", "inde_notes", {}))
  end)
end)

describe("terminal_title", function()
  it("names Claire's toggleterm by its shell and number", function()
    assert.equal("zsh #1", actions.terminal_title("term://~/raccoon//4242:/bin/zsh;#toggleterm#1"))
  end)

  it("keeps the command of a plain terminal", function()
    assert.equal("lazygit", actions.terminal_title("term://~/haligtree//77:lazygit"))
  end)

  it("drops the arguments after the command", function()
    assert.equal("claude", actions.terminal_title("term://~/repo//9:claude --continue"))
  end)

  it("says terminal when the name is not a terminal address", function()
    assert.equal("terminal", actions.terminal_title("inde.txt"))
  end)
end)

describe("shows", function()
  it("keeps the music on a wide screen", function()
    assert.is_true(actions.shows("music", 200))
  end)

  it("lets the music go first when Claire splits the screen in half", function()
    assert.is_false(actions.shows("music", 125))
    assert.is_true(actions.shows("language", 125))
  end)

  it("always shows a piece without a minimum", function()
    assert.is_true(actions.shows("mode", 20))
  end)

  it("drops pieces from the least needed to the most", function()
    local min = actions.STATUSLINE_MIN
    assert.is_true(min.music >= min.runes and min.runes > min.status and min.status > min.diff)
    assert.is_true(min.diff > min.ci and min.ci > min.language)
  end)

  it("keeps only mode, path, diagnostics and position below 120 columns", function()
    for piece in pairs(actions.STATUSLINE_MIN) do
      assert.is_false(actions.shows(piece, 119))
    end
    assert.is_true(actions.shows("diagnostics", 80))
  end)
end)

describe("path_budget", function()
  it("gives Claire's path more room the wider the editor, across every tier", function()
    local last = 0
    for columns = 60, 240 do
      assert.is_true(actions.path_budget(columns) >= last)
      last = actions.path_budget(columns)
    end
  end)

  it("never squeezes the path under its minimum", function()
    assert.equal(actions.PATH_MIN, actions.path_budget(30))
  end)
end)

describe("fit_path", function()
  it("leaves a short path to Inde's letter untouched", function()
    assert.equal("notes/inde.md", actions.fit_path("notes/inde.md", 40))
  end)

  it("drops folders from the front so Malenia's file name always shows", function()
    assert.equal("…/haligtree/rot.lua", actions.fit_path("lua/core/haligtree/rot.lua", 20))
  end)

  it("cuts a file name that is too long on its own", function()
    assert.equal("anniversary_…", actions.fit_path("letters/anniversary_with_claire.md", 13))
  end)
end)

describe("short_branch", function()
  it("keeps Claire's short branch whole", function()
    assert.equal("feature/date-night", actions.short_branch("feature/date-night"))
  end)

  it("shortens a long branch with an ellipsis", function()
    local short = actions.short_branch("bugfix/malenia-anniversary-playlist-order")
    assert.equal(actions.BRANCH_MAX, vim.fn.strchars(short))
    assert.equal("…", vim.fn.strcharpart(short, actions.BRANCH_MAX - 1))
  end)
end)

describe("names_itself", function()
  it("names Inde's files and help pages", function()
    assert.is_true(actions.names_itself(""))
    assert.is_true(actions.names_itself("help"))
  end)

  it("stays quiet for the HUD and other scratch screens", function()
    assert.is_false(actions.names_itself("nofile"))
    assert.is_false(actions.names_itself("prompt"))
  end)
end)

describe("ruler_applies", function()
  it("keeps the column in code that does not wrap", function()
    assert.is_true(actions.ruler_applies(0, false))
  end)

  it("leaves Inde's wrapped love letter alone", function()
    assert.is_false(actions.ruler_applies(0, true))
  end)

  it("keeps a commit message's 72 even while it wraps", function()
    assert.is_true(actions.ruler_applies(72, true))
  end)
end)

describe("level_word", function()
  local chrome = { notify = { info = "Message", warn = "Omen" } }

  it("lists Malenia's warning by the franchise's word", function()
    assert.equal("Omen", actions.level_word("warn", chrome))
  end)

  it("takes the level as a number too", function()
    assert.equal("Message", actions.level_word(vim.log.levels.INFO, chrome))
  end)

  it("keeps the plain level when the lore has no word for it", function()
    assert.equal("error", actions.level_word("error", chrome))
  end)
end)

describe("history_lines", function()
  local chrome = { notify = { info = "Message", warn = "Omen" } }
  local added = os.time({ year = 2026, month = 11, day = 14, hour = 21, min = 5 })

  it("lists Claire's warning under the franchise's word", function()
    local lines =
      actions.history_lines({ { level = "warn", msg = "Inde left a note", added = added } }, chrome)
    assert.equal("21:05 Omen Inde left a note", lines[1])
  end)

  it("marks the level with its snacks highlight", function()
    local _, marks = actions.history_lines({ { level = "warn", msg = "x", added = added } }, chrome)
    assert.same({ row = 0, first = 6, last = 10, group = "SnacksNotifierTitleWarn" }, marks[2])
  end)

  it("gives a notification without a glyph the franchise's one", function()
    local notif = { level = "warn", icon = "", msg = "Malenia is near", added = added }
    local lines = actions.history_lines({ notif }, chrome, { warn = "󰀪" })
    assert.equal("21:05 󰀪 Omen Malenia is near", lines[1])
  end)

  it("indents the later lines of a long message under the first", function()
    local notif =
      { level = "info", title = "Malenia", msg = "first date\nsecond date", added = added }
    local lines = actions.history_lines({ notif }, chrome)
    assert.equal("21:05 Message Malenia first date", lines[1])
    assert.equal("                      " .. "second date", lines[2])
  end)
end)

describe("completion_columns", function()
  it("shows each label with its kind while Claire writes code", function()
    assert.equal(2, #actions.completion_columns("default"))
  end)

  it("drops the kind in the command line, where everything is a Property", function()
    local columns = actions.completion_columns("cmdline")
    assert.equal(1, #columns)
    assert.equal("label", columns[1][1])
  end)
end)
