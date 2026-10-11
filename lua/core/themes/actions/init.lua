-- Region palettes and the pure color math that turns them into UI colors.
-- Every palette fills the same catppuccin slots, so the highlight rules never change.
-- yellow is the region accent, rosewater is functions, lavender is types, green is strings.
local M = {}

M.DEFAULT = "leyndell"

M.REGIONS = {
  {
    name = "leyndell",
    character = "Marika",
    portrait = "marika.jpg",
    title = "Leyndell",
    tagline = "gold on ash stone",
    palette = {
      base = "#0D0B09", mantle = "#090705", crust = "#060403",
      surface0 = "#1C1815", surface1 = "#252019", surface2 = "#312B22",
      overlay0 = "#4A4340", overlay1 = "#6B5E54", overlay2 = "#8C7A6E",
      subtext0 = "#A89278", subtext1 = "#C4AE96", text = "#E0CDA8",
      yellow = "#C9A84C", peach = "#CC8A40", green = "#7DAE68", teal = "#6BA888",
      lavender = "#9B8EC4", mauve = "#A888C8", red = "#B83838", maroon = "#CC4848",
      rosewater = "#DCC0A0", flamingo = "#CC8870", blue = "#6898B8", sapphire = "#5888A8",
      sky = "#68B8C8", pink = "#C488A8",
    },
  },
  {
    name = "haligtree",
    character = "Malenia",
    portrait = "malenia.jpg",
    title = "Haligtree",
    tagline = "Malenia's scarlet rot and bronze",
    palette = {
      base = "#0E0A0B", mantle = "#0A0708", crust = "#060405",
      surface0 = "#1D1517", surface1 = "#271C1F", surface2 = "#33252A",
      overlay0 = "#4E4045", overlay1 = "#6E5A60", overlay2 = "#8E767C",
      subtext0 = "#B0959A", subtext1 = "#CDB2B5", text = "#EBD7D4",
      yellow = "#E07A5F", peach = "#E0A050", green = "#9DB87A", teal = "#7FB5A6",
      lavender = "#B394C8", mauve = "#C9A0DC", red = "#C42B3B", maroon = "#D9485A",
      rosewater = "#D8B48A", flamingo = "#E39A8E", blue = "#7FA6C4", sapphire = "#6E98B8",
      sky = "#9CCFD8", pink = "#E68AA8",
    },
  },
  {
    name = "raya_lucaria",
    character = "Ranni",
    portrait = "ranni.jpg",
    title = "Raya Lucaria",
    tagline = "Rennala's glintstone and full moon",
    palette = {
      base = "#0A0C12", mantle = "#07090E", crust = "#04060A",
      surface0 = "#151A26", surface1 = "#1C2231", surface2 = "#252D3F",
      overlay0 = "#3F4860", overlay1 = "#5C6784", overlay2 = "#7D88A6",
      subtext0 = "#9EA8C4", subtext1 = "#BCC5DD", text = "#DDE3F2",
      yellow = "#7FB2F0", peach = "#E0A86A", green = "#8CC7A4", teal = "#6FC2C2",
      lavender = "#A99AE8", mauve = "#C29BF0", red = "#E05C6B", maroon = "#E87482",
      rosewater = "#C8D4F0", flamingo = "#E2A9C0", blue = "#D8B86A", sapphire = "#5F8FD0",
      sky = "#8FD6E8", pink = "#D99ACB",
    },
  },
  {
    name = "caelid",
    character = "Radahn",
    portrait = "radahn.jpg",
    title = "Caelid",
    tagline = "crimson sky over Radahn's battlefield",
    palette = {
      base = "#110A08", mantle = "#0C0605", crust = "#070303",
      surface0 = "#1F1310", surface1 = "#2A1914", surface2 = "#36201A",
      overlay0 = "#553C34", overlay1 = "#77584D", overlay2 = "#977568",
      subtext0 = "#BE9A88", subtext1 = "#D7B6A3", text = "#EED6C4",
      yellow = "#E8803A", peach = "#F0A848", green = "#A8B060", teal = "#8FA878",
      lavender = "#C08AB0", mauve = "#B070A8", red = "#E03A2E", maroon = "#F05040",
      rosewater = "#E8B48A", flamingo = "#E88A70", blue = "#8AA0C0", sapphire = "#7890B0",
      sky = "#A8C0D0", pink = "#D87A90",
    },
  },
  {
    name = "mohgwyn",
    character = "Mohg",
    portrait = "mohgwyn.jpg",
    title = "Mohgwyn",
    tagline = "bloodflame and the dynasty's gold",
    palette = {
      base = "#0B0607", mantle = "#070304", crust = "#040102",
      surface0 = "#1A0E10", surface1 = "#241215", surface2 = "#30171B",
      overlay0 = "#4D3236", overlay1 = "#6E4A50", overlay2 = "#8F666C",
      subtext0 = "#B38A8F", subtext1 = "#CDA7AA", text = "#E8CFCF",
      -- errors run hotter than the accent so they never blend into the blood
      yellow = "#CF3B4E", peach = "#E8B04A", green = "#B4A86A", teal = "#8FA89A",
      lavender = "#A784C8", mauve = "#C76FA8", red = "#FF5F56", maroon = "#FF7F6E",
      rosewater = "#E5A99A", flamingo = "#E58C8C", blue = "#8F9FC8", sapphire = "#7488B8",
      sky = "#A9C4D8", pink = "#E07AA0",
    },
  },
  {
    name = "ordina",
    character = "Latenna",
    portrait = "latenna.jpg",
    title = "Ordina",
    tagline = "frost on the Consecrated Snowfield",
    palette = {
      base = "#0A0D0F", mantle = "#070A0B", crust = "#040607",
      surface0 = "#141A1E", surface1 = "#1B2328", surface2 = "#232E34",
      overlay0 = "#3E4C55", overlay1 = "#5A6B75", overlay2 = "#7A8C96",
      subtext0 = "#9BADB6", subtext1 = "#BACBD2", text = "#E2EDF0",
      yellow = "#8ED6E0", peach = "#E8B47A", green = "#9CCFA8", teal = "#7CC4B4",
      lavender = "#A8B4E8", mauve = "#C0A8E0", red = "#E06C75", maroon = "#E8848C",
      rosewater = "#D7E6EA", flamingo = "#E0B0B0", blue = "#E6C27A", sapphire = "#6FA8C8",
      sky = "#B4E4F0", pink = "#D8A4C8",
    },
  },
}

function M.names()
  return vim.tbl_map(function(region) return region.name end, M.REGIONS)
end

function M.find(name)
  for _, region in ipairs(M.REGIONS) do
    if region.name == name then return region end
  end
  return nil
end

-- a stale or typo'd saved name should land you somewhere pretty, not on an error
function M.resolve(name)
  return M.find(name) or M.find(M.DEFAULT)
end

-- any region but the last one, so two terminals opened back to back never look alike
function M.random_name(previous, rand)
  local choices = vim.tbl_filter(function(name) return name ~= previous end, M.names())
  return choices[rand(#choices)]
end

-- the region after this one, wrapping around, for quick cycling
function M.next_name(name)
  local names = M.names()
  for index, candidate in ipairs(names) do
    if candidate == name then return names[index % #names + 1] end
  end
  return names[1]
end

local function to_rgb(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

-- mixes fg into bg, alpha 0 is pure bg and 1 is pure fg
function M.blend(fg, bg, alpha)
  local fr, fgreen, fb = to_rgb(fg)
  local br, bgreen, bb = to_rgb(bg)
  local function mix(top, bottom) return math.floor(alpha * top + (1 - alpha) * bottom + 0.5) end
  return ("#%02X%02X%02X"):format(mix(fr, br), mix(fgreen, bgreen), mix(fb, bb))
end

-- tinted backgrounds are derived, so a new region only needs its 26 base colors
function M.derive(p)
  local tint = function(color, alpha) return M.blend(color, p.base, alpha) end
  return {
    cursorline        = tint(p.yellow, 0.06),
    cursorline_insert = tint(p.yellow, 0.16),
    visual            = tint(p.rosewater, 0.15),
    diag_error_bg     = tint(p.red, 0.10),
    diag_warn_bg      = tint(p.peach, 0.10),
    diag_hint_bg      = tint(p.teal, 0.10),
    diag_info_bg      = tint(p.blue, 0.10),
    diff_add          = tint(p.green, 0.12),
    diff_change       = tint(p.yellow, 0.08),
    diff_delete       = tint(p.red, 0.12),
    diff_text         = tint(p.yellow, 0.18),
    indent            = tint(p.overlay0, 0.35),
    indent_scope      = tint(p.yellow, 0.25),
    glance_preview    = tint(p.surface0, 0.45),
    glance_cursorline = tint(p.yellow, 0.08),
    blame             = tint(p.overlay1, 0.85),
  }
end

-- one indent level per color, accent first so the outermost block reads as the region
function M.rainbow(p)
  return { p.yellow, p.lavender, p.teal, p.sky, p.peach, p.red }
end

-- what the cursor line and its number look like in each mode, matching the statusline colors
function M.mode_look(p, tints, mode)
  local first = (mode or "n"):sub(1, 1)
  local looks = {
    i = { cursorline = tints.cursorline_insert, number = p.green },
    v = { cursorline = tints.cursorline, number = p.lavender },
    V = { cursorline = tints.cursorline, number = p.lavender },
    ["\22"] = { cursorline = tints.cursorline, number = p.lavender },
    R = { cursorline = tints.cursorline_insert, number = p.red },
    c = { cursorline = tints.cursorline, number = p.peach },
    t = { cursorline = tints.cursorline, number = p.sky },
  }
  return looks[first] or { cursorline = tints.cursorline, number = p.yellow }
end

function M.lualine_theme(p)
  local function mode(accent)
    return {
      a = { fg = p.base, bg = accent, gui = "bold" },
      b = { fg = p.text, bg = p.surface1 },
      c = { fg = p.subtext0, bg = p.surface0 },
    }
  end
  return {
    normal   = mode(p.yellow),
    insert   = mode(p.green),
    visual   = mode(p.lavender),
    replace  = mode(p.red),
    command  = mode(p.peach),
    terminal = mode(p.sky),
    inactive = {
      a = { fg = p.subtext0, bg = p.base },
      b = { fg = p.subtext0, bg = p.base },
      c = { fg = p.subtext0, bg = p.base },
    },
  }
end

function M.bufferline_highlights(p)
  local bg, bg1, fg, dim, accent = p.base, p.surface0, p.text, p.overlay1, p.yellow
  return {
    fill                  = { bg = bg },
    background            = { fg = dim, bg = bg1 },
    buffer_visible        = { fg = dim, bg = bg1 },
    buffer_selected       = { fg = fg, bg = bg, bold = true },
    indicator_selected    = { fg = accent, bg = bg },
    separator             = { fg = bg, bg = bg1 },
    separator_visible     = { fg = bg, bg = bg1 },
    separator_selected    = { fg = bg, bg = bg },
    modified              = { fg = accent, bg = bg1 },
    modified_selected     = { fg = accent, bg = bg },
    close_button          = { fg = dim, bg = bg1 },
    close_button_selected = { fg = dim, bg = bg },
    numbers               = { fg = dim, bg = bg1 },
    numbers_selected      = { fg = accent, bg = bg, bold = true },
    diagnostic            = { fg = dim, bg = bg1 },
    diagnostic_selected   = { fg = fg, bg = bg },
    error                 = { fg = p.red, bg = bg1 },
    error_selected        = { fg = p.red, bg = bg, bold = true },
    warning               = { fg = p.peach, bg = bg1 },
    warning_selected      = { fg = p.peach, bg = bg, bold = true },
    hint                  = { fg = p.teal, bg = bg1 },
    hint_selected         = { fg = p.teal, bg = bg },
    tab                   = { fg = dim, bg = bg1 },
    tab_selected          = { fg = accent, bg = bg, bold = true },
    tab_close             = { fg = dim, bg = bg },
  }
end

return M
