-- The light that runs over the statusline on every save: which lualine groups it touches, when
-- each section lights up and how bright it gets. Pure logic only.
local blend = require("core.themes.actions").blend

local M = {}

-- a waits for the badge's own mode fade (220 ms) to settle, b and c follow it toward the middle
M.START_MS = 240
M.STEP_MS = 70
M.SPAN_MS = 360
M.PEAK = 0.45
M.TOTAL_MS = M.START_MS + 2 * M.STEP_MS + M.SPAN_MS

-- x, y and z mirror c, b and a, so the light runs from both ends to the middle
local SECTIONS = { a = "a", b = "b", c = "c", x = "c", y = "b", z = "a" }
local ORDER = { a = 0, b = 1, c = 2 }

--- The theme section a lualine group of a mode is painted with, nil for groups of other modes.
---@param group string like "lualine_a_normal" or "lualine_x_diagnostics_error_normal"
---@param mode string lualine mode name
---@return "a"|"b"|"c"|nil
function M.section_of(group, mode)
  local suffix = "_" .. mode
  if group:sub(-#suffix) ~= suffix then
    return nil
  end
  local letter = group:match("^lualine_([abcxyz])_")
  return letter and SECTIONS[letter] or nil
end

--- The sections on both sides of a lualine separator group, nil when it is not one of the mode's.
---@param group string like "lualine_transitional_lualine_a_normal_to_lualine_b_normal"
---@param mode string lualine mode name
---@return "a"|"b"|"c"|nil left, "a"|"b"|"c"|nil right
function M.transitional_sections(group, mode)
  local left, right = group:match("^lualine_transitional_(.+)_to_(lualine_.+)$")
  if not left then
    return nil, nil
  end
  local left_section, right_section = M.section_of(left, mode), M.section_of(right, mode)
  if not (left_section and right_section) then
    return nil, nil
  end
  return left_section, right_section
end

--- How lit a section is at a moment of the glint: 0 before its turn, rising to 1 and back to 0.
---@param elapsed number ms since the save
---@param section "a"|"b"|"c"
---@return number between 0 and 1
function M.strength(elapsed, section)
  local local_ms = elapsed - M.START_MS - ORDER[section] * M.STEP_MS
  if local_ms <= 0 or local_ms >= M.SPAN_MS then
    return 0
  end
  return math.sin(math.pi * local_ms / M.SPAN_MS)
end

--- The light each section glows toward: the badge already wears the accent, so it brightens to the
--- text color, the rest warm up to the accent.
---@param palette table region palette
---@return table<string, string> light per section
function M.lights(palette)
  return { a = palette.text, b = palette.yellow, c = palette.yellow }
end

--- A section's background partway through the glint, exactly its resting color at strength 0.
---@param rest string resting background "#RRGGBB"
---@param light string|nil the color it glows toward, nil while resting
---@param strength number from M.strength
---@return string
function M.glinted(rest, light, strength)
  -- resting, or a section with no light to glow toward, is exactly its theme color
  if not light or strength <= 0 then
    return rest
  end
  return blend(light, rest, M.PEAK * strength)
end

return M
