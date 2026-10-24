-- The fog wall you walk through when traveling between Sites of Grace. Pure math only:
-- how thick the mist is at each moment and the soft clouds it is made of. Times are milliseconds.
-- The mist is only background color, never glyphs, so the code always shows through it.
local M = {}

M.DURATION = 1300
M.LEVELS   = 8
-- the mist thickens quickly, holds while the new project opens, then takes its time to thin out
M.RISE     = 0.18
M.HOLD     = 0.42
-- how opaque the thickest cloud gets, 1 would hide the editor completely
M.THICKEST = 0.72
-- how far the clouds drift across the screen during one crossing, in columns
M.DRIFT    = 18

local function smooth(x)
  x = math.max(0, math.min(1, x))
  return x * x * (3 - 2 * x)
end

--- Returns how thick the whole wall is at a point in the crossing.
---@param raw number progress from 0 to 1
---@return number density from 0 (clear) to 1 (thickest)
function M.density_at(raw)
  raw = math.max(0, math.min(1, raw))
  if raw < M.RISE then return smooth(raw / M.RISE) end
  if raw < M.HOLD then return 1 end
  return 1 - smooth((raw - M.HOLD) / (1 - M.HOLD))
end

-- fog pools at eye level and thins toward the top and bottom of the screen
local function row_weight(row, height)
  if height <= 1 then return 1 end
  local from_center = math.abs(row - (height - 1) / 2) / ((height - 1) / 2)
  return 1 - 0.45 * from_center * from_center
end

--- Returns how much cloud sits on one cell, layered waves so the shapes look soft, never noisy.
---@param col number column, fractional while drifting
---@param row integer
---@param height integer
---@param seed number shifts the pattern so each crossing looks different
---@return number cloud from 0 to 1
function M.cloud(col, row, height, seed)
  local broad = math.sin(col * 0.045 + seed) * math.cos(row * 0.16 + seed * 0.7)
  local wisps = math.sin((col + row * 2.2) * 0.11 + seed * 1.9)
  local raw = 0.5 + 0.32 * broad + 0.18 * wisps
  return math.max(0, math.min(1, raw)) * row_weight(row, height)
end

--- Returns the cloud level of every cell in a row, 0 for clear air up to LEVELS.
---@param width integer
---@param row integer
---@param height integer
---@param seed number
---@param drift number columns the clouds have moved so far
---@return integer[]
function M.row_levels(width, row, height, seed, drift)
  local levels = {}
  for col = 1, width do
    levels[col] = math.floor(M.cloud(col - 1 - drift, row, height, seed) * M.LEVELS + 0.5)
  end
  return levels
end

--- Packs a row of levels into runs, so each stretch of equal cloud needs one highlight.
---@param levels integer[]
---@return { [1]: integer, [2]: integer, [3]: integer }[] zero based start column, end column (exclusive), level
function M.runs(levels)
  local runs = {}
  for col, level in ipairs(levels) do
    local last = runs[#runs]
    if last and last[3] == level then
      last[2] = col
    else
      table.insert(runs, { col - 1, col, level })
    end
  end
  return runs
end

--- Returns the highlight blend for a cloud level at the current density, 100 is invisible.
---@param level integer
---@param density number
---@return integer
function M.blend_for(level, density)
  local alpha = level / M.LEVELS * density * M.THICKEST
  return math.floor(100 - math.max(0, math.min(1, alpha)) * 100 + 0.5)
end

return M
