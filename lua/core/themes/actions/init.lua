-- Region lookups and the pure color math that turns palettes into UI colors.
-- The palettes themselves come with the franchise, see core/franchise/lore.
-- Every palette fills the same catppuccin slots, so the highlight rules never change.
local M = {}

--- Returns the regions of the franchise in use, in picker order.
---@return table[]
function M.regions()
  return require("core.franchise").current().regions
end

function M.names()
  return vim.tbl_map(function(region)
    return region.name
  end, M.regions())
end

function M.find(name)
  for _, region in ipairs(M.regions()) do
    if region.name == name then
      return region
    end
  end
  return nil
end

-- a stale or typo'd saved name should land you somewhere pretty, not on an error
function M.resolve(name)
  return M.find(name) or M.regions()[1]
end

-- the region after this one, wrapping around, for quick cycling
function M.next_name(name)
  local names = M.names()
  for index, candidate in ipairs(names) do
    if candidate == name then
      return names[index % #names + 1]
    end
  end
  return names[1]
end

--- Returns the region of the day, the same all day long in every repo and every launch.
---@param day string date as YYYY-MM-DD
---@param franchise string franchise in use, so each world rolls its own region
---@param names string[] region names
---@return string region name
function M.of_the_day(day, franchise, names)
  -- the hash is stable across machines, so a day looks the same everywhere
  return names[require("core.utils").hash(day .. franchise) % #names + 1]
end

--- Writes a pick so it only holds for the day it was made.
---@param day string date as YYYY-MM-DD
---@param name string region name
---@return string
function M.encode_choice(day, name)
  return day .. " " .. name
end

--- Reads a saved pick back, nil when it was made another day or names no region of this franchise.
---@param line string|nil what the state file holds
---@param day string today as YYYY-MM-DD
---@return string|nil region name
function M.choice_for(line, day)
  local saved_day, name = (line or ""):match("^(%S+)%s+(%S+)$")
  if saved_day ~= day or not M.find(name) then
    return nil
  end
  return name
end

local function to_rgb(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

-- mixes fg into bg, alpha 0 is pure bg and 1 is pure fg
function M.blend(fg, bg, alpha)
  local fr, fgreen, fb = to_rgb(fg)
  local br, bgreen, bb = to_rgb(bg)
  local function mix(top, bottom)
    return math.floor(alpha * top + (1 - alpha) * bottom + 0.5)
  end
  return ("#%02X%02X%02X"):format(mix(fr, br), mix(fgreen, bgreen), mix(fb, bb))
end

local function channel_luminance(value)
  local c = value / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = to_rgb(hex)
  return 0.2126 * channel_luminance(r)
    + 0.7152 * channel_luminance(g)
    + 0.0722 * channel_luminance(b)
end

-- WCAG contrast ratio, 1 means identical and 21 is black on white
function M.contrast(a, b)
  local light, dark = luminance(a), luminance(b)
  if light < dark then
    light, dark = dark, light
  end
  return (light + 0.05) / (dark + 0.05)
end

-- accents differ wildly in brightness, so mix until the result reads the same in every region
function M.tint_to_contrast(fg, bg, target)
  for step = 1, 100 do
    local mixed = M.blend(fg, bg, step / 100)
    if M.contrast(mixed, bg) >= target then
      return mixed
    end
  end
  return fg
end

--- Returns a color's hue in degrees and its saturation, the way HSL measures them.
---@param hex string "#RRGGBB"
---@return number hue from 0 to 360, number saturation from 0 to 1
function M.hue(hex)
  local r, g, b = to_rgb(hex)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local delta = max - min
  if delta == 0 then
    return 0, 0
  end
  local lightness = (max + min) / 2
  local saturation = delta / (1 - math.abs(2 * lightness - 1))
  local hue
  if max == r then
    hue = ((g - b) / delta) % 6
  elseif max == g then
    hue = (b - r) / delta + 2
  else
    hue = (r - g) / delta + 4
  end
  return hue * 60, saturation
end

--- Returns how far apart two colors sit on the color wheel, from 0 to 180 degrees.
---@param a string "#RRGGBB"
---@param b string "#RRGGBB"
---@return number
function M.hue_distance(a, b)
  local distance = math.abs(M.hue(a) - M.hue(b)) % 360
  return math.min(distance, 360 - distance)
end

-- a token and an error underline must never be mistaken for each other
M.ERROR_HUE_GAP = 35
-- grays carry no hue, so they never clash with the error color
M.HUELESS = 0.15
-- the colors a color falls back to, in order, when it sits too close to the error color
local AWAY_FROM_ERROR = { "mauve", "lavender", "peach", "sky", "teal", "pink", "blue" }
-- two roles closer than this on the color wheel read as one
M.ROLE_HUE_GAP = 25

--- Tells whether a color reads apart from the region's error color.
---@param p table region palette
---@param color string "#RRGGBB"
---@return boolean
function M.apart_from_error(p, color)
  local _, saturation = M.hue(color)
  return saturation < M.HUELESS or M.hue_distance(color, p.red) >= M.ERROR_HUE_GAP
end

local function saturated(color)
  local _, saturation = M.hue(color)
  return saturation >= M.HUELESS
end

-- whether a color reads apart from every color another role already wears
local function apart_from_taken(color, taken)
  for _, other in ipairs(taken or {}) do
    if saturated(color) and saturated(other) and M.hue_distance(color, other) < M.ROLE_HUE_GAP then
      return false
    end
  end
  return true
end

local function fits(p, color, taken)
  return M.apart_from_error(p, color) and apart_from_taken(color, taken)
end

--- Returns the color itself, or the first fallback that reads apart from the error color and from
--- the colors other roles already wear.
---@param p table region palette
---@param color string "#RRGGBB"
---@param taken? string[] colors other roles already wear
---@param fallbacks? string[] palette slots or colors to try, AWAY_FROM_ERROR by default
---@return string
function M.away_from_error(p, color, taken, fallbacks)
  if fits(p, color, taken) then
    return color
  end
  for _, slot in ipairs(fallbacks or AWAY_FROM_ERROR) do
    local candidate = p[slot] or slot
    if fits(p, candidate, taken) and M.contrast(candidate, p.base) >= 4.5 then
      return candidate
    end
  end
  return color
end

--- Dims a color until its contrast on the background stays under a ceiling, so it never outshines
--- the text.
---@param fg string "#RRGGBB"
---@param bg string "#RRGGBB"
---@param ceiling number contrast ratio it must stay under
---@return string
function M.cap_contrast(fg, bg, ceiling)
  for step = 100, 1, -1 do
    local mixed = M.blend(fg, bg, step / 100)
    if M.contrast(mixed, bg) <= ceiling then
      return mixed
    end
  end
  return fg
end

-- comments read at the WCAG body text minimum even on the cursor line, and stay under the code
M.COMMENT_CONTRAST = 4.5

-- the contrast each palette slot needs where it is read: the grays carry line numbers, delimiters,
-- footers and inlay hints, the accent carries text drawn on it, and red carries the error messages
M.SLOT_FLOORS = { overlay0 = 3.0, overlay1 = 4.0, overlay2 = 4.5, yellow = 4.5, red = 4.5 }

--- Returns the contrast a palette slot reaches where it is read: red on its own diagnostic
--- background, every other slot on the base.
---@param p table region palette
---@param slot string palette slot
---@return number
function M.slot_contrast(p, slot)
  if slot == "red" then
    return M.contrast(p.red, M.blend(p.red, p.base, 0.10))
  end
  return M.contrast(p[slot], p.base)
end

-- tinted backgrounds are derived, so a new region only needs its 26 base colors
function M.derive(p)
  local tint = function(color, alpha)
    return M.blend(color, p.base, alpha)
  end
  local text_contrast = M.contrast(p.text, p.base)
  local cursorline = tint(p.yellow, 0.06)
  return {
    -- the accent marks focus (the cursor number, the mode, the scope), the tokens get their own
    -- colors so a keyword never looks like an error in a red region
    keyword = M.away_from_error(p, p.yellow),
    -- functions stay a step under the text, which is always the brightest thing on screen
    func = M.cap_contrast(p.rosewater, p.base, text_contrast * 0.88),
    comment = M.tint_to_contrast(
      M.blend(p.yellow, p.subtext0, 0.12),
      cursorline,
      M.COMMENT_CONTRAST
    ),
    border = M.blend(p.yellow, p.overlay1, 0.4),
    search = M.away_from_error(p, p.yellow),
    cursorline = cursorline,
    cursorline_insert = tint(p.yellow, 0.16),
    visual = tint(p.rosewater, 0.15),
    -- slot_contrast measures red on this same tint, keep them together
    diag_error_bg = tint(p.red, 0.10),
    diag_warn_bg = tint(p.peach, 0.10),
    diag_hint_bg = tint(p.teal, 0.10),
    diag_info_bg = tint(p.blue, 0.10),
    diff_add = tint(p.green, 0.12),
    diff_change = tint(p.yellow, 0.08),
    diff_delete = tint(p.red, 0.12),
    diff_text = tint(p.yellow, 0.18),
    indent = tint(p.overlay0, 0.35),
    indent_scope = tint(p.yellow, 0.25),
    glance_preview = tint(p.surface0, 0.45),
    inlay = tint(p.surface0, 0.64),
    glance_cursorline = tint(p.yellow, 0.08),
    blame = tint(p.overlay1, 0.85),
    stopped_line = tint(p.yellow, 0.14),
    -- a whisper of the accent keeps side panels warm with the character instead of plain gray
    panel = M.tint_to_contrast(M.blend(p.yellow, p.surface0, 0.12), p.base, 1.07),
    separator = M.tint_to_contrast(p.yellow, p.base, 2.0),
  }
end

-- every role a skin's syntax signature paints, and the color it takes when the skin names none:
-- a derived color by name (see M.derive) or a palette slot
M.SYNTAX_DEFAULTS = {
  keyword = "keyword",
  ["function"] = "func",
  type = "lavender",
  string = "green",
  constant = "peach",
  comment = "comment",
  property = "func",
}
-- roles that carry the code's structure, in the order they pick: each reads apart from the error
-- color and from the roles before it, falling back through its own list. Functions fall back to a
-- calm near text gray, keywords and types to the cool slots
local STRUCTURAL = { "keyword", "function", "type" }
local function structural_fallbacks(p, role)
  if role == "function" then
    local gray = M.cap_contrast(p.subtext1, p.base, M.contrast(p.text, p.base) * 0.88)
    return { gray, "peach", "sky", "teal" }
  end
  if role == "type" then
    return { "lavender", "sky", "teal", "blue", "mauve", "peach" }
  end
  return AWAY_FROM_ERROR
end

--- Tells whether a syntax role's color names something a region provides.
---@param name string a derived color or a palette slot
---@param p table region palette
---@return boolean
function M.known_color(name, p)
  return M.derive(p)[name] ~= nil or p[name] ~= nil
end

--- Resolves a skin's syntax signature into one color and style per role for a region.
---@param p table region palette
---@param syntax table|nil skin.syntax, roles as { color?: string, style?: string[] }
---@return table<string, { fg: string, style: string[] }>
function M.syntax(p, syntax)
  syntax = syntax or {}
  local tints = M.derive(p)
  local function pick(role)
    local spec = syntax[role] or {}
    local name = spec.color or M.SYNTAX_DEFAULTS[role]
    return tints[name] or p[name] or tints[M.SYNTAX_DEFAULTS[role]], spec.style or {}
  end
  local roles, taken = {}, {}
  for _, role in ipairs(STRUCTURAL) do
    local color, style = pick(role)
    color = M.away_from_error(p, color, taken, structural_fallbacks(p, role))
    table.insert(taken, color)
    roles[role] = { fg = color, style = style }
  end
  for role in pairs(M.SYNTAX_DEFAULTS) do
    if not roles[role] then
      local color, style = pick(role)
      roles[role] = { fg = color, style = style }
    end
  end
  return roles
end

-- one indent level per color, accent first so the outermost block reads as the region
function M.rainbow(p)
  return { p.yellow, p.lavender, p.teal, p.sky, p.peach, p.red }
end

M.GUIDE_ALPHA = 0.4

--- Returns the rainbow faded toward the background, so the full strength scope is the only loud guide.
---@param p table region palette
---@return string[] one hex color per indent level
function M.indent_guides(p)
  return vim.tbl_map(function(color)
    return M.blend(color, p.base, M.GUIDE_ALPHA)
  end, M.rainbow(p))
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

-- the cursor wears the same mode colors as the line number, normal mode keeps the plain Cursor
M.CURSOR_GROUPS = {
  i = "EldenCursorInsert",
  v = "EldenCursorVisual",
  V = "EldenCursorVisual",
  ["\22"] = "EldenCursorVisual",
  R = "EldenCursorReplace",
  c = "EldenCursorCommand",
}

--- Returns the highlight group the cursor uses in a mode.
---@param mode string|nil mode as nvim_get_mode or ModeChanged reports it
---@return string group name
function M.cursor_group(mode)
  return M.CURSOR_GROUPS[(mode or "n"):sub(1, 1)] or "Cursor"
end

-- the shapes a skin without its own cursor wears
M.CURSOR_SHAPES = { normal = "block", insert = "ver25", replace = "hor20" }

--- Returns the guicursor value that paints each mode with its cursor group, in the skin's shapes.
---@param shapes { normal: string, insert: string, replace: string }|nil skin.cursor, guicursor shapes with any blink
---@return string
function M.guicursor(shapes)
  shapes = vim.tbl_extend("force", M.CURSOR_SHAPES, shapes or {})
  return table.concat({
    "n-sm:" .. shapes.normal .. "-Cursor",
    "o:hor50-Cursor",
    "v:block-" .. M.CURSOR_GROUPS.v,
    "i-ci-ve:" .. shapes.insert .. "-" .. M.CURSOR_GROUPS.i,
    "r-cr:" .. shapes.replace .. "-" .. M.CURSOR_GROUPS.R,
    "c:ver25-" .. M.CURSOR_GROUPS.c,
    "t:block-blinkon500-blinkoff500-TermCursor",
  }, ",")
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
    normal = mode(p.yellow),
    insert = mode(p.green),
    visual = mode(p.lavender),
    replace = mode(p.red),
    command = mode(p.peach),
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
    fill = { bg = bg },
    background = { fg = dim, bg = bg1 },
    buffer_visible = { fg = dim, bg = bg1 },
    buffer_selected = { fg = fg, bg = bg, bold = true },
    indicator_selected = { fg = accent, bg = bg },
    separator = { fg = bg, bg = bg1 },
    separator_visible = { fg = bg, bg = bg1 },
    separator_selected = { fg = bg, bg = bg },
    modified = { fg = accent, bg = bg1 },
    modified_selected = { fg = accent, bg = bg },
    close_button = { fg = dim, bg = bg1 },
    close_button_selected = { fg = dim, bg = bg },
    numbers = { fg = dim, bg = bg1 },
    numbers_selected = { fg = accent, bg = bg, bold = true },
    diagnostic = { fg = dim, bg = bg1 },
    diagnostic_selected = { fg = fg, bg = bg },
    error = { fg = p.red, bg = bg1 },
    error_selected = { fg = p.red, bg = bg, bold = true },
    warning = { fg = p.peach, bg = bg1 },
    warning_selected = { fg = p.peach, bg = bg, bold = true },
    hint = { fg = p.teal, bg = bg1 },
    hint_selected = { fg = p.teal, bg = bg },
    tab = { fg = dim, bg = bg1 },
    tab_selected = { fg = accent, bg = bg, bold = true },
    tab_close = { fg = dim, bg = bg },
  }
end

return M
