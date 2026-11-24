-- How Elizabeth dresses every component: a dressing room. Square frames like a stage set, tabs that
-- slope like a curtain's edge, a vanity mirror ringed with bulbs and her name on a marquee.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "single",
  -- wrapped around float titles
  ornament = { "󰋑 ", " 󰋑" },
  -- rounded pills, like the bulbs around her mirror
  statusline = {
    section = { left = "\u{E0B4}", right = "\u{E0B6}" },
    component = { left = "\u{E0B5}", right = "\u{E0B7}" },
  },
  -- bufferline separator_style
  tabs = "slope",
  signs = { error = "󰋔", warn = "▲", hint = "◆", info = "◇" },
  -- statusline, tabs and notifications: a broken heart, the drama masks, her crown and a lipstick
  icons = {
    error = "󰋔",
    warn = "󰴂",
    info = "󰆥",
    hint = "󱎵",
    debug = "󰒄",
    trace = "󰏫",
  },
  -- the cursor's guicursor shapes: it blinks like the bulbs around her mirror
  cursor = {
    normal = "block-blinkwait900-blinkon600-blinkoff300",
    insert = "ver25-blinkwait700-blinkon500-blinkoff250",
    replace = "hor20",
  },
  -- the small marks everywhere else: dotted guides like a hem, hearts for folds and the prompt, and the mirror's bulbs chasing while servers load
  glyphs = {
    indent = "┊",
    scope = "│",
    list = { tab = "› ", trail = "∙", nbsp = "␣" },
    fold = { open = "󰋑", close = "󰋕" },
    diff = "╱",
    prompt = "󰋑 ",
    keys = { breadcrumb = "󰋕", separator = "›", group = "󰋑 " },
    scrollbar = { "◉" },
    spinner = { frames = { "◉○○", "○◉○", "○○◉", "○◉○" }, interval = 160 },
    -- past the end of the buffer, and the lines between windows
    eob = " ",
    split = { vert = "┊", horiz = "┈" },
  },
  -- the explorer: a hem of dotted guides, lipstick notes and hearts that fill once a room is cleared
  tree = {
    indent = "┊",
    last = "╰",
    collapsed = "▸",
    expanded = "▾",
    folder = { closed = "󰉋", open = "󰝰", empty = "󰉖" },
    thread = "󰍩",
    message = "󱎵",
    left = "󰋕",
    cleared = "󰋑",
  },
  -- the code's own signature: keywords in her pinks, bold functions like names in lights, strings
  -- and comments in a soft italic like lines of a script
  syntax = {
    keyword = { color = "pink", style = {} },
    ["function"] = { color = "func", style = { "bold" } },
    type = { color = "mauve", style = {} },
    string = { color = "green", style = { "italic" } },
    constant = { color = "peach", style = {} },
    comment = { color = "comment", style = { "italic" } },
    property = { color = "rosewater", style = {} },
  },
  -- the snacks picker layout, see lua/plugins/snacks.lua: the preview is the vanity mirror
  picker = "vanity",
  -- the command line popup's glyphs: her staff, and the crown for searching
  cmdline = { icon = "󱡄", search = "󰆥" },
  -- which inventory the HUD draws, see core/hud/views: her dressing room, the mirror between racks
  dashboard = "wardrobe",
  -- the title screen keeps the franchise's own colors whatever stage you stand on
  title = {
    text = "ELIZABETH",
    subtitle = "Every role, one heart",
    color = "#F2B36B",
    style = "marquee",
  },
  -- the now playing panel: the progress bar runs like a ribbon, a heart keeps the time
  music = {
    bar = { done = "━", head = "󰋑", left = "─" },
    divider = { line = "─", gem = "󰋑" },
    sung = { "▸ ", " ◂" },
  },
  terminal = {
    iterm_profile = "Eldentree Elizabeth",
    kitty_opacity = 0.92,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "Medium",
      ["font-size"] = 16,
      ["background-opacity"] = 0.88,
      ["background-blur"] = 14,
    },
  },
}
