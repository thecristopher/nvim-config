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
  -- statusline, tabs and notifications, one glyph per level
  icons = {
    error = "󰅚",
    warn = "󰊌",
    info = "󰋽",
    hint = "󰌶",
    debug = "󰒄",
    trace = "󰏫",
  },
  -- the cursor's guicursor shapes per mode, a blink may ride along ("ver25-blinkon500-blinkoff500")
  cursor = { normal = "block", insert = "ver25", replace = "hor20" },
  -- the small marks everywhere else: indent guides and the scope, whitespace, folds, the diff filler, the picker prompt, which-key, the scrollbar thumb and the loading spinner
  glyphs = {
    indent = "│",
    scope = "│",
    list = { tab = "→ ", trail = "·", nbsp = "␣" },
    fold = { open = "▾", close = "▸" },
    diff = "╱",
    prompt = " ",
    keys = { breadcrumb = "»", separator = "→", group = "+" },
    scrollbar = { "•" },
    spinner = { frames = { "◇", "◈", "◆", "◈" }, interval = 140 },
  },
  -- the snacks picker layout, see lua/plugins/snacks.lua: "grace", "inventory", "vanity" or "default"
  picker = "default",
  -- the command line popup's glyphs
  cmdline = { icon = "", search = "󰍉" },
  -- the HUD style, see core/hud/views: "roundtable", "inventory" or "wardrobe"
  dashboard = "roundtable",
  -- style: "shimmer", "drip" or "marquee"
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
