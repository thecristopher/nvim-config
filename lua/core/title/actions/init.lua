-- The title screen: the franchise's name in big block letters, a shimmer or a drip running through
-- it, and the rule that it shows once a day per franchise. Pure logic only, times are milliseconds.
local ease = require("core.motion.actions")

local M = {}

M.HEIGHT = 5
M.FADE_IN = 900
M.LEVELS = 8
M.DRIP_DEPTH = 4
M.DRIP_MS = 520
M.SHIMMER = { period = 3200, band = 10 }
-- nobody should be stuck behind a title, it lifts on its own after this long
M.AUTO_CLOSE_MS = 9000

-- five rows per letter, anything outside A to Z becomes a gap
M.FONT = {
  A = { " ███ ", "█   █", "█████", "█   █", "█   █" },
  B = { "████ ", "█   █", "████ ", "█   █", "████ " },
  C = { " ████", "█    ", "█    ", "█    ", " ████" },
  D = { "████ ", "█   █", "█   █", "█   █", "████ " },
  E = { "█████", "█    ", "████ ", "█    ", "█████" },
  F = { "█████", "█    ", "████ ", "█    ", "█    " },
  G = { " ████", "█    ", "█  ██", "█   █", " ████" },
  H = { "█   █", "█   █", "█████", "█   █", "█   █" },
  I = { "███", " █ ", " █ ", " █ ", "███" },
  J = { "  ███", "   █ ", "   █ ", "█  █ ", " ██  " },
  K = { "█   █", "█  █ ", "███  ", "█  █ ", "█   █" },
  L = { "█    ", "█    ", "█    ", "█    ", "█████" },
  M = { "█   █", "██ ██", "█ █ █", "█   █", "█   █" },
  N = { "█   █", "██  █", "█ █ █", "█  ██", "█   █" },
  O = { " ███ ", "█   █", "█   █", "█   █", " ███ " },
  P = { "████ ", "█   █", "████ ", "█    ", "█    " },
  Q = { " ███ ", "█   █", "█ █ █", "█  █ ", " ██ █" },
  R = { "████ ", "█   █", "████ ", "█  █ ", "█   █" },
  S = { " ████", "█    ", " ███ ", "    █", "████ " },
  T = { "█████", "  █  ", "  █  ", "  █  ", "  █  " },
  U = { "█   █", "█   █", "█   █", "█   █", " ███ " },
  V = { "█   █", "█   █", "█   █", " █ █ ", "  █  " },
  W = { "█   █", "█   █", "█ █ █", "██ ██", "█   █" },
  X = { "█   █", " █ █ ", "  █  ", " █ █ ", "█   █" },
  Y = { "█   █", " █ █ ", "  █  ", "  █  ", "  █  " },
  Z = { "█████", "   █ ", "  █  ", " █   ", "█████" },
}

M.GAP = { "   ", "   ", "   ", "   ", "   " }

--- Writes text in big block letters.
---@param text string
---@return string[] rows one per line of the font, all the same width
function M.big(text)
  local rows = { "", "", "", "", "" }
  local first = true
  for char in text:upper():gmatch(".") do
    local glyph = M.FONT[char] or M.GAP
    for row = 1, M.HEIGHT do
      rows[row] = rows[row] .. (first and "" or " ") .. glyph[row]
    end
    first = false
  end
  return rows
end

--- Tells whether the title already showed today for this franchise.
---@param saved string|nil saved line like "2026-10-24 resident_evil"
---@param day string today as YYYY-MM-DD
---@param franchise string
---@return boolean
function M.shown_today(saved, day, franchise)
  return saved == day .. " " .. franchise
end

--- Returns how visible the whole title is: it rises out of the dark, then stays.
---@param elapsed number
---@return number from 0 to 1
function M.alpha(elapsed)
  return ease.ease("out_cubic", ease.progress(elapsed, M.FADE_IN))
end

--- Returns the brightness level of a column while a band of light crosses the letters.
---@param col integer zero based column inside the title
---@param elapsed number
---@param width integer title width
---@return integer level from 1 (resting gold) to LEVELS (the brightest glint)
function M.shimmer_level(col, elapsed, width)
  local into = elapsed % M.SHIMMER.period
  local travel = width + M.SHIMMER.band * 2
  local position = -M.SHIMMER.band + travel * (into / M.SHIMMER.period)
  local glow = math.max(0, 1 - math.abs(col - position) / M.SHIMMER.band)
  return 1 + math.floor(glow * glow * (M.LEVELS - 1) + 0.5)
end

--- Picks the columns that bleed under the letters: every third solid cell on the bottom row.
---@param bottom string the title's last row
---@return { col: integer, depth: integer }[] zero based display columns and how far each one runs
function M.drips(bottom)
  local drips, solid = {}, 0
  for col, char in ipairs(vim.fn.split(bottom, "\\zs")) do
    if char == "█" then
      solid = solid + 1
      if solid % 3 == 1 then
        table.insert(drips, { col = col - 1, depth = 1 + (solid * 5) % M.DRIP_DEPTH })
      end
    end
  end
  return drips
end

--- Returns how many rows a drip has run so far.
---@param depth integer how far it runs in the end
---@param elapsed number
---@return integer
function M.drip_length(depth, elapsed)
  local running = math.floor((elapsed - M.FADE_IN) / M.DRIP_MS)
  return math.max(0, math.min(depth, running))
end

return M
