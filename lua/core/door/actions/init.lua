-- The door you push open when traveling between Safe Rooms, the old loading screen from the mansion.
-- Pure math only: how dark the screen is, how far the panels slide, and the rows they are drawn with.
local ease = require("core.motion.actions")

local M = {}

M.DURATION = require("core.signpost.actions").DURATION
M.WIDTH = 26
M.HEIGHT = 13

-- the dark falls fast, the door waits a beat, swings, and then the dark lifts off the new project
M.DARK_UNTIL = 0.12
M.SWING_FROM = 0.30
M.SWING_UNTIL = 0.78
M.LIGHT_FROM = 0.80
-- the new project loads in the dark, and its name hangs over the door until the light returns
M.COVERED = M.DARK_UNTIL
M.SIGN = { from = M.DARK_UNTIL, to = M.LIGHT_FROM }

--- Returns how dark the screen is, 0 shows the editor and 1 is pitch black.
---@param raw number progress from 0 to 1
---@return number
function M.darkness(raw)
  if raw < M.DARK_UNTIL then
    return ease.ease("out_cubic", raw / M.DARK_UNTIL)
  end
  if raw < M.LIGHT_FROM then
    return 1
  end
  return 1 - ease.ease("in_out_sine", (raw - M.LIGHT_FROM) / (1 - M.LIGHT_FROM))
end

--- Returns how far open the door is, 0 shut and 1 wide open.
---@param raw number progress from 0 to 1
---@return number
function M.swing(raw)
  local span = M.SWING_UNTIL - M.SWING_FROM
  return ease.ease("in_out_sine", ease.progress(raw - M.SWING_FROM, span))
end

-- the planks of each panel and the seam between them, every few columns
M.PLANK = { face = "▓", seam = "▒", every = 4 }

--- How big the door stands on a screen: most of its height, about as wide as it is tall.
---@param screen_width integer
---@param screen_height integer
---@return integer width, integer height
function M.size(screen_width, screen_height)
  local height = math.max(7, math.min(screen_height - 4, math.floor(screen_height * 0.72)))
  local width = math.max(14, math.min(screen_width - 6, math.floor(height * 2.2)))
  -- an even inside, so both panels are the same width
  if (width - 2) % 2 == 1 then
    width = width - 1
  end
  return width, height
end

-- one column of a panel: a plank face or the seam between planks, counted from the panel's hinge
local function plank(col)
  return col % M.PLANK.every == 0 and M.PLANK.seam or M.PLANK.face
end

-- the part of a panel still in the doorway, its planks sliding with it toward the frame
local function panel_cells(half, visible, from_hinge)
  local cells = {}
  for index = 1, visible do
    -- the panel slides behind the frame, so the doorway shows the columns nearest its free edge
    local col = from_hinge and (half - visible + index) or (visible - index + 1)
    cells[index] = plank(col)
  end
  return cells
end

-- one row of the doorway: the frame, both panels sliding toward the frame, the dark between them
local function doorway_row(open, row, width, height)
  local inner = width - 2
  local half = math.floor(inner / 2)
  local visible = math.floor(half * (1 - open) + 0.5)
  local left = panel_cells(half, visible, true)
  local right = panel_cells(half, visible, false)
  -- the handles ride the free edges, halfway up, while there is a panel to hold them
  if row == math.floor(height / 2) and visible >= 2 then
    left[visible] = "●"
    right[1] = "●"
  end
  local gap = (" "):rep(inner - visible * 2)
  return "│" .. table.concat(left) .. gap .. table.concat(right) .. "│"
end

--- Returns the door as text rows, frame and panels, for a given slide.
---@param open number from 0 (shut) to 1 (both panels gone into the frame)
---@param width? integer the whole door's columns, M.WIDTH by default
---@param height? integer its rows, M.HEIGHT by default
---@return string[]
function M.rows(open, width, height)
  width, height = width or M.WIDTH, height or M.HEIGHT
  local rows = { "┌" .. ("─"):rep(width - 2) .. "┐" }
  for row = 2, height - 1 do
    table.insert(rows, doorway_row(open, row, width, height))
  end
  table.insert(rows, "┴" .. ("─"):rep(width - 2) .. "┴")
  return rows
end

--- Returns how visible the door itself is: it appears in the dark and goes before the light comes back.
---@param raw number progress from 0 to 1
---@return number from 0 to 1
function M.door_alpha(raw)
  local appear = ease.progress(raw - M.DARK_UNTIL, M.SWING_FROM - M.DARK_UNTIL)
  local leave = 1 - ease.progress(raw - M.SWING_UNTIL, M.LIGHT_FROM - M.SWING_UNTIL)
  return math.min(appear, leave)
end

return M
