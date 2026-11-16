-- The title screen: the franchise's name in big block letters, a shimmer, a drip or a marquee of
-- chasing bulbs running through it, and the rule that it shows once a day per franchise. Pure logic only, times are milliseconds.
local ease = require("core.motion.actions")

local M = {}

M.HEIGHT = 5
M.FADE_IN = 900
M.LEVELS = 8
M.DRIP_DEPTH = 4
M.DRIP_MS = 520
M.SHIMMER = { period = 3200, band = 10 }
-- the marquee's bulbs: columns between them, how long each step of the chase lasts, and how many
-- bulbs make one lit and dark pattern
M.MARQUEE = { spacing = 2, step_ms = 140, every = 3 }
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

-- five rows per letter drawn in thin strokes, the lettering of the Lands Between
M.THIN = {
  A = { "╭───╮", "│   │", "├───┤", "│   │", "╵   ╵" },
  B = { "┬───╮", "│   │", "├───┤", "│   │", "┴───╯" },
  C = { "╭───╴", "│    ", "│    ", "│    ", "╰───╴" },
  D = { "┬───╮", "│   │", "│   │", "│   │", "┴───╯" },
  E = { "┬───╴", "│    ", "├──╴ ", "│    ", "┴───╴" },
  F = { "┬───╴", "│    ", "├──╴ ", "│    ", "╵    " },
  G = { "╭───╴", "│    ", "│  ╶┐", "│   │", "╰───╯" },
  H = { "╷   ╷", "│   │", "├───┤", "│   │", "╵   ╵" },
  I = { "╶┬╴", " │ ", " │ ", " │ ", "╶┴╴" },
  J = { "  ╶┬╴", "   │ ", "   │ ", "╷  │ ", "╰──╯ " },
  K = { "╷   ╱", "│  ╱ ", "├─┤  ", "│  ╲ ", "╵   ╲" },
  L = { "╷    ", "│    ", "│    ", "│    ", "┴───╴" },
  M = { "┬╮ ╭┬", "│╰┬╯│", "│ ╵ │", "│   │", "╵   ╵" },
  N = { "┬╮  ╷", "│╲  │", "│ ╲ │", "│  ╲│", "╵  ╰┴" },
  O = { "╭───╮", "│   │", "│   │", "│   │", "╰───╯" },
  P = { "┬───╮", "│   │", "├───╯", "│    ", "╵    " },
  Q = { "╭───╮", "│   │", "│   │", "│ ╲ │", "╰──╲╯" },
  R = { "┬───╮", "│   │", "├─┬─╯", "│ ╰╮ ", "╵  ╰╴" },
  S = { "╭───╴", "│    ", "╰───╮", "    │", "╶───╯" },
  T = { "╶─┬─╴", "  │  ", "  │  ", "  │  ", "  ╵  " },
  U = { "╷   ╷", "│   │", "│   │", "│   │", "╰───╯" },
  V = { "╷   ╷", "│   │", "╲   ╱", " ╲ ╱ ", "  ╵  " },
  W = { "╷   ╷", "│   │", "│ ╷ │", "│╭┴╮│", "╰╯ ╰╯" },
  X = { "╲   ╱", " ╲ ╱ ", "  ╳  ", " ╱ ╲ ", "╱   ╲" },
  Y = { "╲   ╱", " ╲ ╱ ", "  │  ", "  │  ", "  ╵  " },
  Z = { "╶───╱", "   ╱ ", "  ╱  ", " ╱   ", "╱───╴" },
}

--- The font a title style writes with: thin strokes under the shimmer, solid blocks otherwise.
---@param style string|nil skin.title.style
---@return table<string, string[]>
function M.font_for(style)
  return style == "shimmer" and M.THIN or M.FONT
end

--- Writes text in big letters, block letters unless another font is given.
---@param text string
---@param font? table<string, string[]> M.FONT by default
---@return string[] rows one per line of the font, all the same width
function M.big(text, font)
  font = font or M.FONT
  local rows = { "", "", "", "", "" }
  local first = true
  for char in text:upper():gmatch(".") do
    local glyph = font[char] or M.GAP
    for row = 1, M.HEIGHT do
      rows[row] = rows[row] .. (first and "" or " ") .. glyph[row]
    end
    first = false
  end
  return rows
end

-- the ring ------------------------------------------------------------------------------------

-- the stroke for the directions a cell connects to, rounded where a line turns
local JOINTS = {
  ["lr"] = "─",
  ["ud"] = "│",
  ["dr"] = "╭",
  ["dl"] = "╮",
  ["ur"] = "╰",
  ["ul"] = "╯",
  ["udr"] = "├",
  ["udl"] = "┤",
  ["dlr"] = "┬",
  ["ulr"] = "┴",
  ["udlr"] = "┼",
  ["d"] = "╷",
  ["u"] = "╵",
}

local function joint(directions)
  local key = ""
  for _, direction in ipairs({ "u", "d", "l", "r" }) do
    if directions[direction] then
      key = key .. direction
    end
  end
  return JOINTS[key] or " "
end

local function connect(canvas, row, col, ...)
  canvas[row] = canvas[row] or {}
  canvas[row][col] = canvas[row][col] or {}
  for _, direction in ipairs({ ... }) do
    canvas[row][col][direction] = true
  end
end

-- joins two cells on the same row or column with a straight stroke
local function segment(canvas, from_row, from_col, to_row, to_col)
  if from_row == to_row then
    local step = to_col > from_col and 1 or -1
    for col = from_col, to_col - step, step do
      connect(canvas, from_row, col, step > 0 and "r" or "l")
      connect(canvas, from_row, col + step, step > 0 and "l" or "r")
    end
    return
  end
  local step = to_row > from_row and 1 or -1
  for row = from_row, to_row - step, step do
    connect(canvas, row, from_col, step > 0 and "d" or "u")
    connect(canvas, row + step, from_col, step > 0 and "u" or "d")
  end
end

--- Where the arch crosses each row: its left and right columns, widest at the bottom row.
---@param rows integer
---@param cols integer
---@return { left: integer, right: integer }[] one per row, top first
function M.arch(rows, cols)
  local center, reach = (cols - 1) / 2, (cols - 1) / 2
  local spans = {}
  for row = 0, rows - 1 do
    local height = (rows - 1 - row + 0.6) / rows
    local half = reach * math.sqrt(math.max(0, 1 - height * height))
    spans[row + 1] =
      { left = math.floor(center - half + 0.5), right = math.ceil(center + half - 0.5) }
  end
  return spans
end

-- the arc's height at most, and how much wider than the name it reaches
M.RING_ROWS = 5
M.RING_REACH = 16

--- Draws the arc of the ring over the title as a thin stroke: a half circle that steps down at
--- both ends and keeps going past the last row, so the name sits under it.
---@param rows integer how many text rows tall the arc is
---@param cols integer how many columns wide
---@return string[] rows all `cols` wide
function M.ring(rows, cols)
  local canvas = {}
  local spans = M.arch(rows, cols)
  segment(canvas, 0, spans[1].left, 0, spans[1].right)
  for row = 2, rows do
    local above, here = spans[row - 1], spans[row]
    segment(canvas, row - 2, above.left, row - 1, above.left)
    segment(canvas, row - 1, above.left, row - 1, here.left)
    segment(canvas, row - 2, above.right, row - 1, above.right)
    segment(canvas, row - 1, above.right, row - 1, here.right)
  end
  -- the ring carries on down beside the letters
  connect(canvas, rows - 1, spans[rows].left, "d")
  connect(canvas, rows - 1, spans[rows].right, "d")
  local out = {}
  for row = 0, rows - 1 do
    local chars = {}
    for col = 0, cols - 1 do
      chars[col + 1] = canvas[row] and canvas[row][col] and joint(canvas[row][col]) or " "
    end
    out[row + 1] = table.concat(chars)
  end
  return out
end

-- a failing light ----------------------------------------------------------------------------

M.FLICKER = { period = 1100, every = 3 }

--- How bright a failing light is at a moment: steady most of the time, with a short stutter
--- (a drop, a catch and a second drop) on every few periods.
---@param elapsed number
---@return number from 0 to 1
function M.flicker(elapsed)
  local period = math.floor(elapsed / M.FLICKER.period)
  if (period * 7) % M.FLICKER.every ~= 0 then
    return 1
  end
  local into = elapsed % M.FLICKER.period
  if into < 70 then
    return 0.25
  end
  if into >= 130 and into < 170 then
    return 0.55
  end
  return 1
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

--- Returns the bulbs framing a marquee around a box, in order around it so a chase can run
--- through them: along the top left to right, down the right side, back along the bottom and up
--- the left.
---@param width integer columns inside the frame
---@param height integer rows inside the frame
---@return { row: integer, col: integer }[] zero based, row -1 and col -2 sit on the frame itself
function M.bulbs(width, height)
  local spacing = M.MARQUEE.spacing
  local left, right = -spacing, width + spacing - 1
  local top, bottom = -1, height
  local bulbs = {}
  for col = left, right, spacing do
    table.insert(bulbs, { row = top, col = col })
  end
  for row = top + 1, bottom - 1 do
    table.insert(bulbs, { row = row, col = right })
  end
  for col = right, left, -spacing do
    table.insert(bulbs, { row = bottom, col = col })
  end
  for row = bottom - 1, top + 1, -1 do
    table.insert(bulbs, { row = row, col = left })
  end
  return bulbs
end

--- Tells whether a bulb is lit at a moment, the lit ones stepping around the frame.
---@param index integer the bulb's place in the order from M.bulbs
---@param elapsed number
---@return boolean
function M.bulb_lit(index, elapsed)
  local step = math.floor(elapsed / M.MARQUEE.step_ms)
  return (index - step) % M.MARQUEE.every == 0
end

return M
