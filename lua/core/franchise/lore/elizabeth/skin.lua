-- How Elizabeth dresses every component: a dressing room. Square frames like a stage set, tabs that
-- slope like a curtain's edge, a vanity mirror ringed with bulbs and her name on a marquee.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "single",
  -- wrapped around float titles
  ornament = { "󰋑 ", " 󰋑" },
  -- rounded pills, like the bulbs around her mirror
  statusline = {
    section = { left = "", right = "" },
    component = { left = "", right = "" },
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
    kitty_opacity = 0.96,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "Medium",
      ["font-size"] = 16,
      ["background-opacity"] = 0.92,
      ["background-blur"] = 14,
    },
  },
}
