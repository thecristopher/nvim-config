-- The pure side of the 8 bit sprites: which sprite a moment plays, how two rows of pixels become
-- one row of half blocks, which frame is on screen and where the sprite sits.
local M = {}

-- every frame lasts this long, a stepped animation reads more 8 bit than a smooth one
M.FRAME_MS = 110

-- saving happens all day, so only one save in this many pops a sprite
M.SAVE_CHANCE = 0.25

local TRANSPARENT = "."

--- Finds the sprite a region plays for a moment.
---@param pixels table|nil the lore's pixels, keyed by region name
---@param region string region name
---@param moment string what happened ("saved", "felled", "great")
---@return { frames: string[][], colors: table<string, string> }|nil nil when the region has none
function M.sprite_for(pixels, region, moment)
  local own = pixels and pixels[region]
  if type(own) ~= "table" or not own.moments or not own.sprites then
    return nil
  end
  local frames = own.sprites[own.moments[moment] or ""]
  if not frames or #frames == 0 then
    return nil
  end
  return { frames = frames, colors = own.colors or {} }
end

--- Tells whether a moment pops its sprite this time.
---@param moment string what happened
---@param roll number a random number between 0 and 1
---@return boolean
function M.pops(moment, roll)
  if moment == "saved" then
    return roll < M.SAVE_CHANCE
  end
  return true
end

-- the palette slot a pixel letter paints, nil when the pixel is transparent
local function slot(letter, colors)
  if not letter or letter == "" or letter == TRANSPARENT then
    return nil
  end
  return colors[letter]
end

--- Turns a pixel above another into one cell: its character and the slots of its colors.
---@param top string|nil palette slot of the upper pixel, nil when transparent
---@param bottom string|nil palette slot of the lower pixel, nil when transparent
---@return string char
---@return string|nil fg slot, nil when the whole cell is transparent
---@return string|nil bg slot, "base" when only half the cell is painted
function M.cell(top, bottom)
  if not top and not bottom then
    return " ", nil, nil
  end
  if not bottom then
    return "▀", top, "base"
  end
  if not top then
    return "▄", bottom, "base"
  end
  if top == bottom then
    return "█", top, top
  end
  return "▀", top, bottom
end

-- one row of cells from two rows of pixels, with a mark for every painted cell
local function row_of(upper, lower, colors)
  local chars, marks, byte = {}, {}, 0
  for index = 1, #upper do
    local char, fg, bg =
      M.cell(slot(upper:sub(index, index), colors), slot(lower:sub(index, index), colors))
    table.insert(chars, char)
    if fg then
      table.insert(marks, { start = byte, finish = byte + #char, fg = fg, bg = bg })
    end
    byte = byte + #char
  end
  return { text = table.concat(chars), marks = marks }
end

--- Draws one frame as editor rows, two pixel rows per row.
---@param frame string[] rows of pixel letters, all the same width
---@param colors table<string, string> pixel letter to palette slot
---@return { text: string, marks: { start: integer, finish: integer, fg: string, bg: string }[] }[]
function M.rows(frame, colors)
  local rows = {}
  for index = 1, #frame, 2 do
    local lower = frame[index + 1] or string.rep(TRANSPARENT, #frame[index])
    table.insert(rows, row_of(frame[index], lower, colors))
  end
  return rows
end

--- The size a sprite takes on screen, in cells.
---@param frames string[][]
---@return integer width
---@return integer height
function M.size(frames)
  local first = frames[1]
  return #first[1], math.ceil(#first / 2)
end

--- The frame on screen after some time, nil once the last one has played.
---@param elapsed number milliseconds since the sprite popped
---@param count integer how many frames the sprite has
---@return integer|nil
function M.frame_at(elapsed, count)
  local index = math.floor(elapsed / M.FRAME_MS) + 1
  return index <= count and index or nil
end

--- Where the sprite sits: the top right corner of the window, clear of its edges.
---@param info { winrow: integer, wincol: integer, width: integer, height: integer } from getwininfo
---@param width integer sprite width in cells
---@param height integer sprite height in cells
---@return { row: integer, col: integer, width: integer, height: integer }|nil nil when it does not fit
function M.place(info, width, height)
  if info.width < width + 4 or info.height < height + 2 then
    return nil
  end
  return {
    row = info.winrow,
    col = info.wincol - 1 + info.width - width - 2,
    width = width,
    height = height,
  }
end

--- The highlight group that paints a cell with these slots.
---@param fg string palette slot
---@param bg string palette slot
---@return string
function M.group(fg, bg)
  return "EldenPixel_" .. fg .. "_" .. bg
end

return M
