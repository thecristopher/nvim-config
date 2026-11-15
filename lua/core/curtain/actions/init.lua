-- The stage curtain that closes on one project and opens on the next. Pure math only: how far
-- the drapes cover the screen, how the light falls on their folds and when the stage name shows.
local ease = require("core.motion.actions")

local M = {}

M.DURATION = 2600

-- the drapes meet, hold a beat while the new stage is announced, then part
M.CLOSE_UNTIL = 0.34
M.OPEN_FROM = 0.62

-- columns per fold of velvet, and how bright each column of a fold is (1 is the darkest)
M.FOLD = { 1, 2, 3, 4, 3, 2 }
M.SHADES = 4

--- Returns how much of its half of the screen each drape covers, 0 parted and 1 closed.
---@param raw number progress from 0 to 1
---@return number
function M.cover(raw)
  if raw < M.CLOSE_UNTIL then
    return ease.ease("in_out_sine", raw / M.CLOSE_UNTIL)
  end
  if raw < M.OPEN_FROM then
    return 1
  end
  return 1 - ease.ease("in_cubic", (raw - M.OPEN_FROM) / (1 - M.OPEN_FROM))
end

--- Returns how many columns one drape spans on a screen of a given width.
---@param width integer screen columns
---@param cover number from 0 to 1
---@return integer
function M.drape_width(width, cover)
  -- rounding up lets the drapes meet in the middle of an odd width
  return math.min(math.ceil(width / 2), math.floor(width / 2 * cover + 0.5))
end

--- Returns the shade of one column of velvet, counted from the drape's inner edge so the folds
--- travel with the fabric instead of standing still while it moves.
---@param from_edge integer columns away from the inner edge, 0 is the edge itself
---@return integer shade from 1 to SHADES
function M.shade_at(from_edge)
  return M.FOLD[from_edge % #M.FOLD + 1]
end

--- Returns a drape as runs of velvet, each `{ columns, shade }`, read left to right.
---@param width integer columns the drape spans
---@param side "left"|"right" which drape, the left one has its inner edge on the right
---@return { [1]: integer, [2]: integer }[]
function M.runs(width, side)
  local runs = {}
  for col = 0, width - 1 do
    local from_edge = side == "left" and (width - 1 - col) or col
    local shade = M.shade_at(from_edge)
    local last = runs[#runs]
    if last and last[2] == shade then
      last[1] = last[1] + 1
    else
      table.insert(runs, { 1, shade })
    end
  end
  return runs
end

--- Returns how visible the stage name is: it only shows while the drapes are closed.
---@param raw number progress from 0 to 1
---@return number from 0 to 1
function M.name_alpha(raw)
  local span = (M.OPEN_FROM - M.CLOSE_UNTIL) / 3
  local appear = ease.progress(raw - M.CLOSE_UNTIL, span)
  local leave = 1 - ease.progress(raw - (M.OPEN_FROM - span), span)
  return math.min(appear, leave)
end

return M
