-- How Elizabeth dresses every component: soft rounded frames tied with hearts, like a velvet cape.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "rounded",
  -- wrapped around float titles
  ornament = { "󰋑 ", " 󰋑" },
  statusline = {
    section = { left = "", right = "" },
    component = { left = "", right = "" },
  },
  -- bufferline separator_style
  tabs = "slant",
  signs = { error = "󰋔", warn = "▲", hint = "◆", info = "◇" },
  -- the snacks picker layout, see lua/plugins/snacks.lua
  picker = "grace",
  -- the command line popup's glyphs: her staff, and the crown for searching
  cmdline = { icon = "󱡄", search = "󰆥" },
  -- which inventory the HUD draws, see core/hud/views: her wardrobe, one tab per kind of thing
  dashboard = "roundtable",
  -- the title screen keeps the franchise's own colors whatever stage you stand on
  title = {
    text = "ELIZABETH",
    subtitle = "Every role, one heart",
    color = "#E8466A",
    style = "shimmer",
  },
  -- the now playing panel: the progress bar runs like a ribbon, a heart keeps the time
  music = {
    bar = { done = "━", head = "󰋑", left = "─" },
    divider = { line = "─", gem = "󰋑" },
    sung = { "▸ ", " ◂" },
  },
  terminal = {
    iterm_profile = "Eldentree Elizabeth",
    kitty_opacity = 0.97,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "Regular",
      ["font-size"] = 16,
      ["background-opacity"] = 0.95,
      ["background-blur"] = 8,
    },
  },
}
