-- How the Lands Between dress every component: soft rounded frames, gold ornaments, a quiet statusline.
return {
  -- vim.o.winborder, so pickers, hovers and every Eldentree float wear it
  border = "rounded",
  -- wrapped around float titles
  ornament = { "◈ ", " ◈" },
  statusline = {
    section = { left = "", right = "" },
    component = { left = "", right = "" },
  },
  -- bufferline separator_style
  tabs = "slant",
  -- the gutter stays empty, tiny-inline-diagnostic speaks for the errors
  signs = { error = " ", warn = " ", hint = " ", info = " " },
  -- which inventory the HUD draws, see core/hud/views
  dashboard = "roundtable",
  -- the title screen keeps the franchise's own colors whatever region you stand in
  title = {
    text = "ELDEN RING",
    subtitle = "Arise now, ye Tarnished",
    color = "#D8B45A",
    style = "shimmer",
  },
  terminal = {
    iterm_profile = "Eldentree Elden Ring",
    kitty_opacity = 0.97,
    ghostty = {
      ["font-family"] = "JetBrainsMono Nerd Font Mono",
      ["font-style"] = "Light",
      ["font-size"] = 14,
      ["background-opacity"] = 0.94,
      ["background-blur"] = 8,
    },
  },
}
