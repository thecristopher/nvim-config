-- How the Lands Between dress every component: soft rounded frames, gold ornaments, a quiet statusline.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "rounded",
  -- wrapped around float titles
  ornament = { "◈ ", " ◈" },
  -- slanted edges, cut like the tabs above them
  statusline = {
    section = { left = "\u{E0BC}", right = "\u{E0BA}" },
    component = { left = "\u{E0BD}", right = "\u{E0BB}" },
  },
  -- bufferline separator_style
  tabs = "slant",
  -- the gutter stays empty, tiny-inline-diagnostic speaks for the errors
  signs = { error = " ", warn = " ", hint = " ", info = " " },
  -- statusline, tabs and notifications: death, a warning, the grace's guidance and the rot's bloom
  icons = {
    error = "󰚌",
    warn = "󰀪",
    info = "󰫢",
    hint = "󰧰",
    debug = "󰒄",
    trace = "󰏫",
  },
  -- the cursor's guicursor shapes: a thin blade while writing
  cursor = { normal = "block", insert = "ver25", replace = "hor20" },
  -- the small marks everywhere else: dashed guides like a golden thread, the grace at the prompt and a gem that turns while servers load
  glyphs = {
    indent = "╎",
    scope = "│",
    list = { tab = "› ", trail = "·", nbsp = "␣" },
    fold = { open = "󰅀", close = "󰅂" },
    diff = "╱",
    prompt = "󰫢 ",
    keys = { breadcrumb = "›", separator = "→", group = "◇ " },
    scrollbar = { "◆" },
    spinner = { frames = { "◇", "◈", "◆", "◈" }, interval = 140 },
    -- past the end of the buffer, and the lines between windows
    eob = " ",
    split = { vert = "│", horiz = "─" },
  },
  -- the explorer: golden threads, the grace on ground messages and rooms lit once cleared
  tree = {
    indent = "│",
    last = "╰",
    collapsed = "󰅂",
    expanded = "󰅀",
    folder = { closed = "󰉋", open = "󰝰", empty = "󰉖" },
    thread = "󰍩",
    message = "󰫢",
    left = "◇",
    cleared = "◆",
  },
  -- the code's own signature: gold italic keywords like an inscription, functions a step under the
  -- text, lavender types, comments in a quiet italic
  syntax = {
    keyword = { color = "keyword", style = { "italic" } },
    ["function"] = { color = "func", style = {} },
    type = { color = "lavender", style = { "italic" } },
    string = { color = "green", style = {} },
    constant = { color = "peach", style = {} },
    comment = { color = "comment", style = { "italic" } },
    property = { color = "func", style = {} },
  },
  -- the snacks picker layout, see lua/plugins/snacks.lua: results over the prompt like a grace menu
  picker = "grace",
  -- the command line popup's glyphs
  cmdline = { icon = "󰫢", search = "◎" },
  -- which inventory the HUD draws, see core/hud/views
  dashboard = "roundtable",
  -- the title screen keeps the franchise's own colors whatever region you stand in
  title = {
    text = "ELDEN RING",
    subtitle = "Arise now, ye Tarnished",
    color = "#D8B45A",
    style = "shimmer",
  },
  -- the now playing panel: the progress bar runs like a gold thread, dividers frame the lyrics
  -- and the marks wrap the sung line
  music = {
    bar = { done = "━", head = "◈", left = "─" },
    divider = { line = "─", gem = "◈" },
    sung = { "▸ ", " ◂" },
  },
  terminal = {
    iterm_profile = "Eldentree Elden Ring",
    kitty_opacity = 0.93,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "Light",
      ["font-size"] = 16,
      ["background-opacity"] = 0.90,
      ["background-blur"] = 8,
    },
  },
}
