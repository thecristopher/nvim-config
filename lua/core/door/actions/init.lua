-- The door you push open when traveling between Safe Rooms, the old loading screen from the mansion.
-- Pure math only: how dark the screen is, how far the doors swing, and the rows they are drawn with.
local ease = require("core.motion.actions")

local M = {}

M.DURATION = 2400
M.WIDTH    = 26
M.HEIGHT   = 13

-- the dark falls fast, the door waits a beat, swings, and then the dark lifts off the new project
M.DARK_UNTIL  = 0.12
M.SWING_FROM  = 0.30
M.SWING_UNTIL = 0.78
M.LIGHT_FROM  = 0.80

-- the panels lose their face as they turn away from you
M.PANEL_SHADES = { "█", "▓", "▒", "░" }

--- Returns how dark the screen is, 0 shows the editor and 1 is pitch black.
---@param raw number progress from 0 to 1
---@return number
function M.darkness(raw)
  if raw < M.DARK_UNTIL then return ease.ease("out_cubic", raw / M.DARK_UNTIL) end
  if raw < M.LIGHT_FROM then return 1 end
  return 1 - ease.ease("in_out_sine", (raw - M.LIGHT_FROM) / (1 - M.LIGHT_FROM))
end

--- Returns how far open the door is, 0 shut and 1 wide open.
---@param raw number progress from 0 to 1
---@return number
function M.swing(raw)
  local span = M.SWING_UNTIL - M.SWING_FROM
  return ease.ease("in_out_sine", ease.progress(raw - M.SWING_FROM, span))
end

local function panel_shade(open)
  local index = math.min(#M.PANEL_SHADES, math.floor(open * #M.PANEL_SHADES) + 1)
  return M.PANEL_SHADES[index]
end

-- one row of the doorway: the frame, both panels shrinking toward their hinges, the dark between them
local function doorway_row(open, row)
  local inner = M.WIDTH - 2
  local half = math.floor(inner / 2)
  local panel = math.floor(half * (1 - open) + 0.5)
  local shade = panel_shade(open)
  local left = shade:rep(panel)
  local right = shade:rep(panel)
  -- the handles sit on the inner edges, halfway up, while there is a panel left to hold them
  if row == math.floor(M.HEIGHT / 2) and panel >= 2 then
    left = shade:rep(panel - 1) .. "●"
    right = "●" .. shade:rep(panel - 1)
  end
  local gap = (" "):rep(inner - panel * 2)
  return "│" .. left .. gap .. right .. "│"
end

--- Returns the door as text rows, frame and panels, for a given swing.
---@param open number from 0 to 1
---@return string[]
function M.rows(open)
  local rows = { "┌" .. ("─"):rep(M.WIDTH - 2) .. "┐" }
  for row = 2, M.HEIGHT - 1 do
    table.insert(rows, doorway_row(open, row))
  end
  table.insert(rows, "┴" .. ("─"):rep(M.WIDTH - 2) .. "┴")
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
