-- Widths for the Claude side panel, kept pure so the math can be tested without windows.
local M = {}

-- share of the editor the panel opens with
M.DEFAULT_SHARE = 0.38

---Columns the panel takes at its default share.
---@param total integer columns of the whole editor
---@return integer
function M.default_width(total)
  return math.max(1, math.floor(total * M.DEFAULT_SHARE))
end

return M
