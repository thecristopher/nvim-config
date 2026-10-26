-- How __title__ dresses every component.
return {
  -- vim.o.winborder: "rounded", "double", "single", "solid" or "shadow"
  border = "rounded",
  -- wrapped around float titles
  ornament = { "◈ ", " ◈" },
  statusline = {
    section = { left = "", right = "" },
    component = { left = "", right = "" },
  },
  -- bufferline separator_style: "slant", "slope", "thick", "thin" or "padded_slant"
  tabs = "slant",
  signs = { error = "●", warn = "▲", hint = "◆", info = "◇" },
  -- the HUD style, see core/hud/views: "roundtable" or "inventory"
  dashboard = "roundtable",
  -- style: "shimmer" or "drip"
  title = { text = "__title__", subtitle = "press any key", color = "#D8B45A", style = "shimmer" },
  -- the now playing panel: progress bar, dividers around the lyrics, marks around the sung line
  music = {
    bar = { done = "━", head = "◈", left = "─" },
    divider = { line = "─", gem = "◈" },
    sung = { "▸ ", " ◂" },
  },
  -- ghostty takes any Ghostty config keys, written to ~/.config/ghostty/eldentree
  terminal = {
    iterm_profile = "Eldentree __title__",
    kitty_opacity = 1.0,
    ghostty = { ["background-opacity"] = 1 },
  },
}
