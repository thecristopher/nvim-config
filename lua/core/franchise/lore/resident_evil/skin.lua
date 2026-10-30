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
  signs = { error = "☣", warn = "▲", hint = "◆", info = "◇" },
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
  -- the now playing panel: the progress bar runs like a tape counter, dividers frame the lyrics
  -- and the marks wrap the sung line
  music = {
    bar = { done = "▰", head = "▶", left = "▱" },
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
