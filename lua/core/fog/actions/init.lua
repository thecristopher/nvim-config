-- The fog wall you walk through when traveling between Sites of Grace. Pure math only:
-- how thick the mist is at each moment and where its wisps sit. Times are milliseconds.
local M = {}

M.DURATION = 900
-- the mist thickens quickly, then takes its time to thin out
M.PEAK = 0.22
-- winblend at the thickest moment, 100 is invisible
M.THICKEST = 30

--- Returns the float's winblend for a point in the crossing.
---@param raw number progress from 0 to 1
---@return integer winblend from M.THICKEST (thick) to 100 (gone)
function M.blend_at(raw)
  raw = math.max(0, math.min(1, raw))
  local density
  if raw < M.PEAK then
    density = raw / M.PEAK
  else
    local t = (raw - M.PEAK) / (1 - M.PEAK)
    density = 1 - t * t
  end
  return math.floor(100 - density * (100 - M.THICKEST) + 0.5)
end

M.WISPS = { "░", "▒" }

-- the wall is densest across the middle of the screen, like fog pooling at eye level
local function row_density(row, height)
  if height <= 1 then return 0.5 end
  local center = (height - 1) / 2
  local distance = math.abs(row - center) / center
  return 0.55 - 0.35 * distance
end

--- Returns the mist lines for a float of this size.
---@param width integer columns
---@param height integer rows
---@param rand fun(): number random source between 0 and 1
---@return string[] lines # one per row
function M.texture(width, height, rand)
  local lines = {}
  for row = 0, height - 1 do
    local density = row_density(row, height)
    local cells = {}
    for col = 1, width do
      local roll = rand()
      if roll < density * 0.35 then
        cells[col] = M.WISPS[2]
      elseif roll < density then
        cells[col] = M.WISPS[1]
      else
        cells[col] = " "
      end
    end
    lines[row + 1] = table.concat(cells)
  end
  return lines
end

return M
