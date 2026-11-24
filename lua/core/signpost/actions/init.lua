-- The sign every travel shows with the place you arrive at. Pure math only: when it shows, how the
-- name is written to fit, where it sits and how its dark plate fades at the edges.
local ease = require("core.motion.actions")

local M = {}

-- every travel lasts the same, so fog, door and curtain feel like one gesture in three costumes
M.DURATION = 2200
-- share of the travel the sign takes to fade in or out
M.FADE = 0.07
-- the plate keeps this many clear columns beside the name, then fades over EDGE more
M.PAD = 6
M.EDGE = 10
M.LEVELS = 8
-- the plate is a little short of solid at its heart, so the travel still breathes behind it
M.PLATE = 0.92
-- the ornament on the rule above the name
M.MARK = "◆"

--- Returns how visible the sign is: it fades in after `from` and is gone by `to`.
---@param raw number progress of the travel from 0 to 1
---@param from number when the screen is covered and the sign starts to show
---@param to number when the sign must be gone
---@return number from 0 to 1
function M.alpha(raw, from, to)
  local appear = ease.ease("out_cubic", ease.progress(raw - from, M.FADE))
  local leave = 1 - ease.ease("in_cubic", ease.progress(raw - (to - M.FADE), M.FADE))
  return math.max(0, math.min(appear, leave))
end

local function spaced(text)
  return require("core.banner.actions").spaced(text)
end

local function truncate(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end
  local chars = vim.fn.strchars(text)
  while chars > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(text, 0, chars)) > max_width - 1 do
    chars = chars - 1
  end
  return vim.fn.strcharpart(text, 0, chars) .. "…"
end

--- Returns the name the way the sign writes it: letter spaced when it fits, plain when that is
--- too wide, and cut with an ellipsis as a last resort.
---@param name string the project or branch
---@param screen_width integer
---@return string
function M.text(name, screen_width)
  local max_width = math.max(1, screen_width - 2 * M.PAD - 4)
  local wide = spaced(name)
  if vim.fn.strdisplaywidth(wide) <= max_width then
    return wide
  end
  return truncate(name:upper(), max_width)
end

--- Returns where the sign goes: the name on the middle row, a rule above and below it, and the
--- plate spanning both with room to fade.
---@param screen_width integer
---@param screen_height integer
---@param text_width integer display width of the name as written
---@return { row: integer, col: integer, rule_col: integer, rule_width: integer, plate_col: integer, plate_width: integer, top: integer, bottom: integer }
function M.layout(screen_width, screen_height, text_width)
  local row = math.floor(screen_height / 2)
  local rule_width = math.min(screen_width, text_width + 4)
  local plate_width = math.min(screen_width, text_width + 2 * (M.PAD + M.EDGE))
  return {
    row = row,
    col = math.max(0, math.floor((screen_width - text_width) / 2)),
    rule_col = math.max(0, math.floor((screen_width - rule_width) / 2)),
    rule_width = rule_width,
    plate_col = math.max(0, math.floor((screen_width - plate_width) / 2)),
    plate_width = plate_width,
    top = math.max(0, row - 2),
    bottom = math.min(screen_height - 1, row + 2),
  }
end

--- Returns one row of the plate as runs of `{ columns, level }`, dark in the middle and fading
--- to nothing over EDGE columns at each end.
---@param width integer columns the plate spans
---@return { [1]: integer, [2]: integer }[]
function M.plate_runs(width)
  local runs = {}
  for col = 0, width - 1 do
    local from_edge = math.min(col, width - 1 - col)
    local level = math.min(M.LEVELS, math.floor((from_edge + 1) / M.EDGE * M.LEVELS + 0.5))
    local last = runs[#runs]
    if last and last[2] == level then
      last[1] = last[1] + 1
    else
      table.insert(runs, { 1, level })
    end
  end
  return runs
end

--- Returns the rule above the name, with the ornament in its middle, or the plain one below it.
---@param width integer columns the rule spans
---@param marked boolean true for the rule carrying the ornament
---@return string
function M.rule(width, marked)
  if not marked or width < 5 then
    return ("─"):rep(width)
  end
  local side = math.floor((width - 3) / 2)
  return ("─"):rep(side) .. " " .. M.MARK .. " " .. ("─"):rep(width - 3 - side)
end

return M
