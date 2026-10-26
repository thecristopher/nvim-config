-- The HUD's pure logic: moving through a grid of slots, cycling tabs, scrolling, fitting text,
-- and composing rows of colored chunks into buffer lines with highlight marks.
local M = {}

M.MOVES = {
  h = { 0, -1 },
  l = { 0, 1 },
  k = { -1, 0 },
  j = { 1, 0 },
}

--- Moves the cursor through a grid of count slots laid out columns wide.
---@param index integer current slot, 1 based
---@param count integer slots in the grid
---@param columns integer slots per row
---@param direction string h, j, k or l
---@return integer|nil next slot, nil when the move leaves the grid through that edge
function M.grid_move(index, count, columns, direction)
  if count == 0 then
    return nil
  end
  local step = M.MOVES[direction]
  local row, col = math.floor((index - 1) / columns), (index - 1) % columns
  local next_row, next_col = row + step[1], col + step[2]
  if next_col < 0 or next_col >= columns or next_row < 0 then
    return nil
  end
  local next_index = next_row * columns + next_col + 1
  if next_index > count then
    -- moving down into a short last row lands on its last slot instead of falling off
    if step[1] > 0 and next_row * columns < count then
      return count
    end
    return nil
  end
  return next_index
end

--- Cycles through n entries, wrapping at both ends.
---@param index integer 1 based
---@param count integer
---@param step integer 1 forward, -1 back
---@return integer
function M.cycle(index, count, step)
  if count == 0 then
    return 1
  end
  return (index - 1 + step) % count + 1
end

--- Returns how many slots fit in a width.
---@param width integer columns available
---@param slot_width integer one slot with its frame
---@return integer at least one
function M.columns_for(width, slot_width)
  return math.max(1, math.floor(width / slot_width))
end

--- Keeps the cursor's row inside the visible rows, moving the window as little as possible.
---@param cursor_row integer zero based grid row of the cursor
---@param visible integer grid rows that fit
---@param offset integer first grid row shown now
---@return integer new offset
function M.scroll(cursor_row, visible, offset)
  if cursor_row < offset then
    return cursor_row
  end
  if cursor_row >= offset + visible then
    return cursor_row - visible + 1
  end
  return offset
end

--- Cuts text to a display width, marking the cut with an ellipsis.
---@param text string
---@param width integer
---@return string
function M.fit(text, width)
  if width <= 0 then
    return ""
  end
  if vim.api.nvim_strwidth(text) <= width then
    return text
  end
  return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

--- Pads text with spaces to a display width, cutting it first when it is too long.
---@param text string
---@param width integer
---@return string
function M.pad(text, width)
  local fitted = M.fit(text, width)
  return fitted .. (" "):rep(math.max(0, width - vim.api.nvim_strwidth(fitted)))
end

--- Breaks text into lines no wider than width, at spaces when it can.
---@param text string
---@param width integer
---@return string[]
function M.wrap(text, width)
  local lines, current = {}, ""
  for word in (text or ""):gmatch("%S+") do
    local candidate = current == "" and word or current .. " " .. word
    if vim.api.nvim_strwidth(candidate) <= width then
      current = candidate
    else
      if current ~= "" then
        table.insert(lines, current)
      end
      current = M.fit(word, width)
    end
  end
  if current ~= "" then
    table.insert(lines, current)
  end
  return lines
end

--- Measures a row of { text, hl } chunks as the terminal draws it.
---@param chunks table[]
---@return integer
function M.width(chunks)
  local width = 0
  for _, chunk in ipairs(chunks) do
    width = width + vim.api.nvim_strwidth(chunk[1])
  end
  return width
end

--- Pads a row of chunks with blank space up to a width.
---@param chunks table[]
---@param width integer
---@return table[] chunks
function M.pad_chunks(chunks, width)
  local padded = vim.list_extend({}, chunks)
  local gap = width - M.width(chunks)
  if gap > 0 then
    table.insert(padded, { (" "):rep(gap) })
  end
  return padded
end

--- Cuts a row of chunks at a display width, so no frame after it is ever pushed out of place.
---@param chunks table[]
---@param width integer
---@return table[] chunks
function M.clip(chunks, width)
  local clipped, used = {}, 0
  for _, chunk in ipairs(chunks) do
    local room = width - used
    if room <= 0 then
      break
    end
    local size = vim.api.nvim_strwidth(chunk[1])
    if size > room then
      local cut = vim.tbl_extend("force", {}, chunk)
      -- blank space is simply shortened, only words get the ellipsis
      cut[1] = chunk[1]:match("^%s*$") and (" "):rep(room) or M.fit(chunk[1], room)
      table.insert(clipped, cut)
      break
    end
    table.insert(clipped, chunk)
    used = used + size
  end
  return clipped
end

--- Places two columns of rows side by side, the left one padded to its width.
---@param left table[] rows of chunks
---@param left_width integer
---@param right table[] rows of chunks
---@param gap integer columns between them
---@return table[] rows
function M.beside(left, left_width, right, gap)
  local rows = {}
  for index = 1, math.max(#left, #right) do
    local row = M.pad_chunks(left[index] or {}, left_width + gap)
    rows[index] = vim.list_extend(row, right[index] or {})
  end
  return rows
end

--- Shifts every row right by an indent.
---@param rows table[]
---@param indent integer
---@return table[]
function M.indent(rows, indent)
  return vim.tbl_map(function(row)
    return vim.list_extend({ { (" "):rep(indent) } }, row)
  end, rows)
end

--- Turns rows of { text, hl } chunks into buffer lines, highlight marks and named spots.
--- A chunk may carry `bg`, a background group painted under its own, and `spot`, a name whose
--- position is recorded so the cursor and the floats land exactly where the layout put them.
---@param rows table[]
---@return string[] lines, table[] marks as { row, start_byte, end_byte, hl, priority } with zero based rows, table<string, { row: integer, col: integer }> spots, zero based display cells
function M.compose(rows)
  local lines, marks, spots = {}, {}, {}
  for index, chunks in ipairs(rows) do
    local line, col = "", 0
    for _, chunk in ipairs(chunks) do
      if chunk.spot then
        spots[chunk.spot] = { row = index - 1, col = col }
      end
      if chunk[1] ~= "" then
        if chunk.bg then
          table.insert(marks, { index - 1, #line, #line + #chunk[1], chunk.bg, 150 })
        end
        if chunk[2] then
          table.insert(marks, { index - 1, #line, #line + #chunk[1], chunk[2], 200 })
        end
      end
      line = line .. chunk[1]
      col = col + vim.api.nvim_strwidth(chunk[1])
    end
    lines[index] = line
  end
  return lines, marks, spots
end

--- Centers a row of chunks inside a width.
---@param chunks table[]
---@param width integer
---@return table[] chunks
function M.center(chunks, width)
  local left = math.max(0, math.floor((width - M.width(chunks)) / 2))
  return vim.list_extend({ { (" "):rep(left) } }, chunks)
end

--- Adds blank rows above so a column sits in the middle of a taller one.
---@param rows table[]
---@param height integer rows of the taller column
---@return table[]
function M.middle(rows, height)
  local padded = {}
  for _ = 1, math.max(0, math.floor((height - #rows) / 2)) do
    table.insert(padded, {})
  end
  return vim.list_extend(padded, rows)
end

-- portraits are 276x336 and half blocks draw two pixels per cell, so a cell box this ratio fits them
M.PORTRAIT_RATIO = 46 / 28

--- Sizes the portrait as tall as the room allows while keeping its shape.
---@param max_width integer cells available across
---@param max_height integer rows available
---@param min_height integer below this the portrait is left out
---@return { width: integer, height: integer }|nil
function M.portrait_fit(max_width, max_height, min_height)
  local height = math.min(max_height, math.floor(max_width / M.PORTRAIT_RATIO))
  if height < min_height then
    return nil
  end
  return { width = math.floor(height * M.PORTRAIT_RATIO + 0.5), height = height }
end

--- Clamps a number between two bounds.
---@param value number
---@param low number
---@param high number
---@return number
function M.clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

--- Returns the byte column where a display column starts inside a line.
---@param line string
---@param display_col integer zero based
---@return integer zero based byte column
function M.byte_col(line, display_col)
  local width, starts = 0, vim.str_utf_pos(line)
  for index, start in ipairs(starts) do
    if width >= display_col then
      return start - 1
    end
    local stop = (starts[index + 1] or #line + 1) - 1
    width = width + vim.api.nvim_strwidth(line:sub(start, stop))
  end
  return #line
end

--- Tells whether the HUD should move to the window just entered, like the zoom float or a split of it.
---@param hud_win integer window the HUD is laid out for
---@param hud_buf integer the HUD buffer
---@param win integer window just entered
---@param buf integer buffer that window shows
---@return boolean
function M.follows(hud_win, hud_buf, win, buf)
  return buf == hud_buf and win ~= hud_win
end

--- Picks the window the HUD lives in among those showing its buffer: the one with the cursor, then
--- the one it was in, then any, so a split that moves on or a closed zoom hands it back.
---@param current integer window with the cursor
---@param last integer window the HUD was laid out for
---@param showing integer[] windows showing the HUD buffer
---@return integer|nil win, nil when no window shows it anymore
function M.hud_window(current, last, showing)
  if vim.tbl_contains(showing, current) then
    return current
  end
  if vim.tbl_contains(showing, last) then
    return last
  end
  return showing[1]
end

return M
