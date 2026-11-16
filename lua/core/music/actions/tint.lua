-- The cover's tint: the dominant colors ImageMagick finds in an album cover, and the one accent
-- vivid enough to dress the panel and the statusline while that album plays. Pure logic only.
local themes = require("core.themes.actions")

local M = {}

-- grays and washed out colors read as no tint at all
M.MIN_SATURATION = 0.3
-- near black disappears on the base and near white glares
M.MIN_LIGHTNESS = 0.2
M.MAX_LIGHTNESS = 0.85
-- the accent must read on the region base as well as the palette's own accents do
M.MIN_CONTRAST = 4.5
-- how many colors ImageMagick reduces the cover to
M.COLORS = 6

--- Builds the ImageMagick call that reduces a cover to its dominant colors.
---@param binary string "magick" or "convert"
---@param file string cover image
---@return string[]
function M.command(binary, file)
  return {
    binary,
    file,
    "-resize",
    "64x64",
    "-colors",
    tostring(M.COLORS),
    "-format",
    "%c",
    "histogram:info:-",
  }
end

--- Reads ImageMagick's histogram into colors, the most common first.
---@param output string|nil lines like "  2833: (20,14,11) #140F0B srgb(...)"
---@return { count: integer, hex: string }[]
function M.parse_histogram(output)
  local colors = {}
  for line in (output or ""):gmatch("[^\n]+") do
    local count, hex = line:match("^%s*(%d+):.-(#%x%x%x%x%x%x)")
    if count then
      table.insert(colors, { count = tonumber(count), hex = hex:upper() })
    end
  end
  table.sort(colors, function(a, b)
    return a.count > b.count
  end)
  return colors
end

--- Returns a color's saturation and lightness, both from 0 to 1.
---@param hex string "#RRGGBB"
---@return number saturation, number lightness
function M.saturation_lightness(hex)
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  local high, low = math.max(r, g, b), math.min(r, g, b)
  local lightness = (high + low) / 2
  if high == low then
    return 0, lightness
  end
  return (high - low) / (1 - math.abs(2 * lightness - 1)), lightness
end

--- Tells whether a color is vivid enough to stand for the album.
---@param hex string
---@return boolean
function M.vivid(hex)
  local saturation, lightness = M.saturation_lightness(hex)
  return saturation >= M.MIN_SATURATION
    and lightness >= M.MIN_LIGHTNESS
    and lightness <= M.MAX_LIGHTNESS
end

--- Lifts a color toward white on a dark base, or toward black on a light one, until it reads.
---@param hex string
---@param base string the region's base
---@param target number contrast ratio to reach
---@return string
function M.readable(hex, base, target)
  if themes.contrast(hex, base) >= target then
    return hex
  end
  local _, base_lightness = M.saturation_lightness(base)
  local toward = base_lightness < 0.5 and "#FFFFFF" or "#000000"
  for step = 1, 20 do
    local lifted = themes.blend(toward, hex, step / 20)
    if themes.contrast(lifted, base) >= target then
      return lifted
    end
  end
  return toward
end

--- Picks the album's accent: the vivid color covering the most of the cover, weighted by how
--- vivid it is, made readable on the base.
---@param colors { count: integer, hex: string }[] from parse_histogram
---@param base string the region's base
---@return string|nil nil when the cover has no vivid color, so the palette stays
function M.accent(colors, base)
  local best, best_score
  for _, color in ipairs(colors or {}) do
    if M.vivid(color.hex) then
      local saturation = M.saturation_lightness(color.hex)
      local score = color.count * saturation
      if not best_score or score > best_score then
        best, best_score = color.hex, score
      end
    end
  end
  return best and M.readable(best, base, M.MIN_CONTRAST) or nil
end

--- The groups that wear the album's accent, with the attrs each one keeps.
---@param accent string
---@return table<string, table>
function M.groups(accent)
  return {
    EldenMusicTitle = { fg = accent, bold = true },
    EldenMusicBarDone = { fg = accent },
    EldenMusicBarHead = { fg = accent, bold = true },
    EldenMusicLyricSweep = { fg = accent, bold = true },
    EldenMusicEqHigh = { fg = accent },
    EldenMusicDividerGem = { fg = accent },
    EldenMusicLine = { fg = accent },
  }
end

--- The same groups in the region's palette, for when nothing tints them.
---@param p table palette
---@return table<string, table>
function M.palette_groups(p)
  return {
    EldenMusicTitle = { fg = p.yellow, bold = true },
    EldenMusicBarDone = { fg = p.yellow },
    EldenMusicBarHead = { fg = p.peach, bold = true },
    EldenMusicLyricSweep = { fg = p.yellow, bold = true },
    EldenMusicEqHigh = { fg = p.yellow },
    EldenMusicDividerGem = { fg = p.yellow },
    EldenMusicLine = { fg = p.mauve },
  }
end

return M
