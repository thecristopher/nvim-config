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
  return vim.tbl_map(function(region) return region.name end, M.regions())
end

function M.find(name)
  for _, region in ipairs(M.regions()) do
    if region.name == name then return region end
  end
  return nil
end

-- a stale or typo'd saved name should land you somewhere pretty, not on an error
function M.resolve(name)
  return M.find(name) or M.regions()[1]
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

--- Returns the region a project wears: the one chosen there before, or one derived from its folder name.
---@param root string project root
---@param chosen table<string, string>|nil regions picked per project root
---@return string region name
function M.project_region(root, chosen)
  local picked = chosen and chosen[root]
  if picked and M.find(picked) then return picked end
  local names = M.names()
  -- the hash is stable across machines, so a project keeps its region everywhere
  return names[require("core.utils").hash(vim.fs.basename(root)) % #names + 1]
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

local function channel_luminance(value)
  local c = value / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = to_rgb(hex)
  return 0.2126 * channel_luminance(r) + 0.7152 * channel_luminance(g) + 0.0722 * channel_luminance(b)
end

-- WCAG contrast ratio, 1 means identical and 21 is black on white
function M.contrast(a, b)
  local light, dark = luminance(a), luminance(b)
  if light < dark then light, dark = dark, light end
  return (light + 0.05) / (dark + 0.05)
end

-- accents differ wildly in brightness, so mix until the result reads the same in every region
function M.tint_to_contrast(fg, bg, target)
  for step = 1, 100 do
    local mixed = M.blend(fg, bg, step / 100)
    if M.contrast(mixed, bg) >= target then return mixed end
  end
  return fg
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
    stopped_line      = tint(p.yellow, 0.14),
    -- a whisper of the accent keeps side panels warm with the character instead of plain gray
    panel             = M.tint_to_contrast(M.blend(p.yellow, p.surface0, 0.12), p.base, 1.07),
    separator         = M.tint_to_contrast(p.yellow, p.base, 2.0),
  }
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
  return vim.tbl_map(function(color) return M.blend(color, p.base, M.GUIDE_ALPHA) end, M.rainbow(p))
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

--- Returns the guicursor value that paints each mode with its cursor group.
---@return string
function M.guicursor()
  return table.concat({
    "n-sm:block-Cursor",
    "o:hor50-Cursor",
    "v:block-" .. M.CURSOR_GROUPS.v,
    "i-ci-ve:ver25-" .. M.CURSOR_GROUPS.i,
    "r-cr:hor20-" .. M.CURSOR_GROUPS.R,
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
