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

---What fullscreen does when focus lands somewhere. Floats are welcome, a collapsed window would
---grow and squeeze Claude so focus goes back, and a window just opened wants room so it ends.
---@param target "panel"|"float"|"collapsed"|"new"
---@return "keep"|"back"|"release"
function M.on_focus(target)
  if target == "collapsed" then
    return "back"
  end
  if target == "new" then
    return "release"
  end
  return "keep"
end

return M
