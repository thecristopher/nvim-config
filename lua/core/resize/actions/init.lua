-- Window borders and resize steps, kept pure so they can be tested without a screen.
local M = {}

-- columns or rows moved per key press, and per press with shift
M.STEP = 2
M.BIG_STEP = 8

-- the file tree stays between these widths, so it is never lost nor swallows the editor
M.TREE_MIN = 20
M.TREE_MAX = 60

-- what each key of the resize mode does: which side of the window and which way
M.KEYS = {
  h = { side = "width", steps = -M.STEP },
  l = { side = "width", steps = M.STEP },
  k = { side = "height", steps = -M.STEP },
  j = { side = "height", steps = M.STEP },
  H = { side = "width", steps = -M.BIG_STEP },
  L = { side = "width", steps = M.BIG_STEP },
  K = { side = "height", steps = -M.BIG_STEP },
  J = { side = "height", steps = M.BIG_STEP },
  ["<Left>"] = { side = "width", steps = -M.STEP },
  ["<Right>"] = { side = "width", steps = M.STEP },
  ["<Up>"] = { side = "height", steps = -M.STEP },
  ["<Down>"] = { side = "height", steps = M.STEP },
}

-- keys that end the resize mode
M.DONE = { ["<Esc>"] = true, q = true, ["<CR>"] = true }

-- glyph of the handle drawn on a hovered border
M.HANDLES = { right = "⇔", bottom = "⇕" }

-- the wincmd direction of the window across each border
M.ACROSS = { right = "l", bottom = "j" }

---@class ResizeWinInfo
---@field winrow integer first screen row of the window, 1 based, winbar included
---@field wincol integer first screen column, 1 based
---@field winbar integer 1 when the window has a winbar
---@field width integer
---@field height integer text rows, winbar left out

---Which border of a window the mouse sits on, from what getmousepos() reports.
---A vertical border belongs to the window on its left, a horizontal one to the window above.
---@param pos { wincol: integer, winrow: integer }
---@param info ResizeWinInfo the window getmousepos() named
---@return "right"|"bottom"|nil
function M.edge_at(pos, info)
  if pos.wincol == info.width + 1 then
    return "right"
  end
  if pos.winrow == info.winbar + info.height + 1 then
    return "bottom"
  end
  return nil
end

---Narrowest and widest a window may get, the tree has its own range.
---@param filetype string
---@param total integer columns of the whole editor
---@return integer least
---@return integer most
function M.width_range(filetype, total)
  if filetype == "neo-tree" then
    return math.min(M.TREE_MIN, total), math.min(M.TREE_MAX, total)
  end
  return 1, total
end

---A window size after a resize step, kept inside its range.
---@param size integer current width or height
---@param steps integer cells to add, negative to take
---@param least integer
---@param most integer
---@return integer
function M.stepped(size, steps, least, most)
  return math.min(math.max(size + steps, least), most)
end

---A width pulled back inside its range, nil when it already fits.
---@param width integer
---@param least integer
---@param most integer
---@return integer|nil
function M.fitted(width, least, most)
  if width < least then
    return least
  end
  if width > most then
    return most
  end
  return nil
end

---A winhighlight with the separator swapped for another group, the rest kept as it was.
---@param winhighlight string current value of the window option
---@param group string highlight group the separator takes
---@return string
function M.with_separator(winhighlight, group)
  local parts = {}
  for part in winhighlight:gmatch("[^,]+") do
    if not part:match("^WinSeparator:") then
      table.insert(parts, part)
    end
  end
  table.insert(parts, "WinSeparator:" .. group)
  return table.concat(parts, ",")
end

local function between(value, least, most)
  return math.min(math.max(value, least), most)
end

---Where a border's handle goes, zero based like nvim_open_win. It sits on the border itself,
---so it moves with the window, at the mouse along the border or at its middle without one.
---@param edge "right"|"bottom"
---@param info ResizeWinInfo
---@param along integer|nil screen row (right edge) or column (bottom edge) of the mouse, 1 based
---@return integer row
---@return integer col
function M.handle_spot(edge, info, along)
  local top = info.winrow + info.winbar
  if edge == "right" then
    local row =
      between(along or (top + math.floor(info.height / 2)), info.winrow, top + info.height - 1)
    return row - 1, info.wincol + info.width - 1
  end
  local col = between(
    along or (info.wincol + math.floor(info.width / 2)),
    info.wincol,
    info.wincol + info.width - 1
  )
  return top + info.height - 1, col - 1
end

return M
