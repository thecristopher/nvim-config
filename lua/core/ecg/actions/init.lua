-- The health ECG from the inventory screen: how the buffer is doing and the trace it draws.
-- Pure logic only, times are milliseconds.
local M = {}

M.WIDTH = 12

-- one heartbeat, everything else on the line is the flat baseline
M.BEAT = { "▂", "▁", "▇", "▁", "▃" }
M.BASELINE = "▁"

M.CONDITIONS = {
  fine = { label = "Fine", color = "green", step_ms = 140, gap = 12 },
  caution = { label = "Caution", color = "peach", step_ms = 100, gap = 9 },
  danger = { label = "Danger", color = "red", step_ms = 60, gap = 6 },
}

--- Reads the buffer's health from its diagnostics.
---@param errors integer
---@param warnings integer
---@return string condition: fine, caution or danger
function M.condition(errors, warnings)
  if errors >= 3 then
    return "danger"
  end
  if errors > 0 or warnings >= 5 then
    return "caution"
  end
  return "fine"
end

--- Draws the trace at a moment, the beats scrolling left as time goes by.
---@param condition string from M.condition
---@param elapsed number milliseconds since the monitor started
---@param width integer|nil cells, M.WIDTH by default
---@return string
function M.trace(condition, elapsed, width)
  local look = M.CONDITIONS[condition]
  local offset = math.floor(elapsed / look.step_ms)
  local cells = {}
  for col = 0, (width or M.WIDTH) - 1 do
    local position = (col + offset) % look.gap
    cells[col + 1] = M.BEAT[position + 1] or M.BASELINE
  end
  return table.concat(cells)
end

return M
