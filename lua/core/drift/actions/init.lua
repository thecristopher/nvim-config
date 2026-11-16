-- The weather past the end of the buffer: when a file ends before its window does, the region's
-- weather drifts through the empty rows under it. Pure decisions and geometry only.
local M = {}

-- fewer rows than this are a margin, not a sky
M.MIN_ROWS = 3
-- quieter than the HUD's weather, it shares the screen with text
M.BUDGET_SHARE = 0.5
-- writing that reads like prose, where weather under the last line is a mood and not a distraction
M.PROSE = { markdown = true, text = true, gitcommit = true }

--- Decides whether the window deserves weather under its text: prose and empty buffers only, code
--- stays calm.
---@param opts { enabled: boolean, buftype: string, filetype: string, empty: boolean, diff: boolean, floating: boolean, mode: string, resting: boolean }
---@return boolean
function M.should_drift(opts)
  if not opts.enabled or opts.resting or opts.diff or opts.floating then
    return false
  end
  if opts.buftype ~= "" then
    return false
  end
  if not (opts.empty or M.PROSE[opts.filetype]) then
    return false
  end
  -- typing is no moment for weather, and visual and operator modes are busy too
  return opts.mode == "n"
end

--- Where the sky starts and how tall it is, from the rows the text takes.
---@param text_rows integer screen rows the text takes from the top of the window
---@param height integer the window's text rows
---@return { row: integer, height: integer }|nil nil when fewer than MIN_ROWS stay empty
function M.sky(text_rows, height)
  local empty = height - text_rows
  if empty < M.MIN_ROWS then
    return nil
  end
  return { row = text_rows, height = empty }
end

--- The float over the empty rows, in editor coordinates, from the window's getwininfo.
---@param info { winrow: integer, wincol: integer, width: integer, textoff: integer, winbar: integer }
---@param sky { row: integer, height: integer }
---@return { row: integer, col: integer, width: integer, height: integer }|nil nil when no column is left
function M.placement(info, sky)
  local width = info.width - info.textoff
  if width < 1 then
    return nil
  end
  return {
    row = info.winrow - 1 + (info.winbar or 0) + sky.row,
    col = info.wincol - 1 + info.textoff,
    width = width,
    height = sky.height,
  }
end

--- How many particles share the sky, half what the HUD would draw in the same space.
---@param budget integer what core/hub would draw there
---@return integer
function M.budget(budget)
  return math.max(2, math.floor(budget * M.BUDGET_SHARE))
end

--- Tells whether two placements cover the same cells.
---@param a table|nil
---@param b table|nil
---@return boolean
function M.same_place(a, b)
  if not a or not b then
    return a == b
  end
  return a.row == b.row and a.col == b.col and a.width == b.width and a.height == b.height
end

return M
