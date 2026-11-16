-- How Raccoon City dresses every component: the inventory HUD, hard double frames and solid blocks.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "double",
  -- wrapped around float titles, like the tabs of the inventory screen
  ornament = { "▐ ", " ▌" },
  statusline = {
    section = { left = "▌", right = "▐" },
    component = { left = "│", right = "│" },
  },
  -- bufferline separator_style
  tabs = "thick",
  signs = { error = "󰂧", warn = "▲", hint = "◆", info = "◇" },
  -- statusline, tabs and notifications: the ECG pulse, an alarm, the typewriter's files and a green herb
  icons = {
    error = "󰗶",
    warn = "󰀦",
    info = "󰼭",
    hint = "󰌪",
    debug = "󰒄",
    trace = "󰏫",
  },
  -- the cursor's guicursor shapes: the typewriter's caret underlines what you type
  cursor = { normal = "block", insert = "hor15", replace = "block-blinkon200-blinkoff200" },
  -- the small marks everywhere else: hard guides, a quiet dot where whitespace trails, the save room's arrows and a tape reel spinning
  glyphs = {
    indent = "┆",
    scope = "┃",
    list = { tab = "▸ ", trail = "·", nbsp = "␣" },
    fold = { open = "▼", close = "▶" },
    diff = "░",
    prompt = "▶ ",
    keys = { breadcrumb = "▶", separator = "▸", group = "▪ " },
    scrollbar = { "▀", "▄" },
    spinner = { frames = { "▖", "▘", "▝", "▗" }, interval = 100 },
    -- past the end of the buffer, and the lines between windows
    eob = " ",
    split = { vert = "║", horiz = "═" },
  },
  -- the explorer: hard guides like the map's corridors, typewriter files and rooms marked on the map
  tree = {
    indent = "┆",
    last = "└",
    collapsed = "▶",
    expanded = "▼",
    folder = { closed = "󰉋", open = "󰝰", empty = "󰉖" },
    thread = "󰍩",
    message = "󰼭",
    left = "□",
    cleared = "■",
  },
  -- the code's own signature: a typewriter writes upright, so no italics anywhere, bold keywords and
  -- types stamped on the page, strings in herb green
  syntax = {
    italic = false,
    keyword = { color = "keyword", style = { "bold" } },
    ["function"] = { color = "func", style = {} },
    type = { color = "sky", style = { "bold" } },
    string = { color = "green", style = {} },
    constant = { color = "peach", style = {} },
    comment = { color = "comment", style = {} },
    property = { color = "func", style = {} },
  },
  -- the snacks picker layout, see lua/plugins/snacks.lua: the item list beside what you examine
  picker = "inventory",
  -- the command line popup's glyphs
  cmdline = { icon = "󰌌", search = "󰍉" },
  -- which inventory the HUD draws, see core/hud/views
  dashboard = "inventory",
  -- the title screen keeps the franchise's own colors whatever region you stand in
  title = {
    text = "RESIDENT EVIL",
    subtitle = "Enter the survival horror",
    color = "#C8202C",
    style = "drip",
  },
  -- the now playing panel: the progress bar fills one block at a time, dividers frame the lyrics
  -- and the marks wrap the sung line
  music = {
    bar = { done = "█", head = "▶", left = "░" },
    divider = { line = "═", gem = "■" },
    sung = { "▶ ", " ◀" },
  },
  terminal = {
    iterm_profile = "Eldentree Resident Evil",
    kitty_opacity = 1.0,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "SemiBold",
      ["font-size"] = 16,
      ["background-opacity"] = 1,
      ["background-blur"] = false,
    },
  },
}
