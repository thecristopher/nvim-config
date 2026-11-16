-- The project map: every folder is a room, red while something is still left inside it
-- (errors or TODOs) and blue once it is cleared. Pure bookkeeping only.
local zones = require("core.zones.actions")

local M = {}

--- Parses `git grep -c` output into counts per file.
---@param output string lines like "lua/core/map/init.lua:2"
---@return table<string, integer>
function M.parse_counts(output)
  local counts = {}
  for line in (output or ""):gmatch("[^\n]+") do
    local file, count = line:match("^(.*):(%d+)$")
    if file then
      counts[file] = tonumber(count)
    end
  end
  return counts
end

local function room_for(rooms, key)
  rooms[key] = rooms[key] or { key = key, todos = 0, errors = 0 }
  return rooms[key]
end

--- Builds the rooms of a project from its files, the TODOs in them and the errors open right now.
---@param root string repo root
---@param files string[] paths relative to the root
---@param todos table<string, integer> TODO count per relative path
---@param errors table<string, integer> error count per absolute path
---@return { key: string, name: string, todos: integer, errors: integer, cleared: boolean }[] sorted by key
function M.rooms(root, files, todos, errors)
  local rooms = {}
  for _, file in ipairs(files) do
    local key = zones.zone_key(root .. "/" .. file, root)
    if key then
      room_for(rooms, key).todos = room_for(rooms, key).todos + (todos[file] or 0)
    end
  end
  for path, count in pairs(errors) do
    local key = zones.zone_key(path, root)
    if key then
      room_for(rooms, key).errors = room_for(rooms, key).errors + count
    end
  end

  local list = {}
  for _, room in pairs(rooms) do
    room.cleared = room.todos == 0 and room.errors == 0
    table.insert(list, room)
  end
  table.sort(list, function(a, b)
    return a.key < b.key
  end)
  local names = zones.zone_names(vim.tbl_map(function(room)
    return room.key
  end, list))
  for _, room in ipairs(list) do
    room.name = names[room.key]
  end
  return list
end

--- Describes what is still left in a room, empty once it is cleared.
---@param room table from M.rooms
---@return string
function M.leftovers(room)
  local parts = {}
  if room.errors > 0 then
    table.insert(parts, room.errors .. (room.errors == 1 and " error" or " errors"))
  end
  if room.todos > 0 then
    table.insert(parts, room.todos .. (room.todos == 1 and " TODO" or " TODOs"))
  end
  return table.concat(parts, ", ")
end

--- Counts the rooms already cleared.
---@param rooms table[] from M.rooms
---@return integer cleared, integer total
function M.progress(rooms)
  local cleared = #vim.tbl_filter(function(room)
    return room.cleared
  end, rooms)
  return cleared, #rooms
end

-- the spatial map --------------------------------------------------------------------------------

-- every room is a box this wide (borders included) unless the window is narrower, with a space between
M.BOX = { min = 20, max = 30, gap = 1 }
M.HERE = "▲"

local function wing_of(key)
  return key:match("^[^/]+") or key
end

-- top folders with no rooms below them share one wing, so the map is not a column of lone boxes
M.GROUNDS = "/"

local function lone(rooms)
  local count = {}
  for _, room in ipairs(rooms) do
    local wing = wing_of(room.key)
    count[wing] = (count[wing] or 0) + 1
  end
  return function(room)
    return room.key == wing_of(room.key) and count[room.key] == 1
  end
end

--- Groups the rooms by their top folder, the wings of the map, in the rooms' own order. Top folders
--- that are a single room share the GROUNDS wing.
---@param rooms table[] from M.rooms
---@return { name: string, rooms: table[] }[]
function M.wings(rooms)
  local wings, by_name = {}, {}
  local is_lone = lone(rooms)
  for _, room in ipairs(rooms) do
    local name = is_lone(room) and M.GROUNDS or wing_of(room.key)
    if not by_name[name] then
      by_name[name] = { name = name, rooms = {} }
      table.insert(wings, by_name[name])
    end
    table.insert(by_name[name].rooms, room)
  end
  return wings
end

--- How wide every box is and how many fit in a row of the given width.
---@param rooms table[]
---@param width integer columns the map may use
---@return integer box_width, integer per_row
function M.box_size(rooms, width)
  local widest = 0
  for _, room in ipairs(rooms) do
    widest = math.max(widest, vim.fn.strdisplaywidth(room.name), vim.fn.strdisplaywidth(room.key))
  end
  -- borders, padding and the glyph in front of the name
  local box = math.max(M.BOX.min, math.min(M.BOX.max, widest + 6))
  box = math.min(box, math.max(8, width))
  return box, math.max(1, math.floor((width + M.BOX.gap) / (box + M.BOX.gap)))
end

-- cuts text to a display width, closing with an ellipsis when it had to cut
local function fit(text, width)
  if vim.fn.strdisplaywidth(text) <= width then
    return text .. (" "):rep(width - vim.fn.strdisplaywidth(text))
  end
  local cut = vim.fn.strcharpart(text, 0, math.max(0, width - 1))
  while vim.fn.strdisplaywidth(cut) > width - 1 do
    cut = vim.fn.strcharpart(cut, 0, vim.fn.strchars(cut) - 1)
  end
  return cut .. "…" .. (" "):rep(width - 1 - vim.fn.strdisplaywidth(cut))
end

local function room_group(room, here)
  if here then
    return "EldenMapHere"
  end
  return room.cleared and "EldenMapCleared" or "EldenMapLeft"
end

-- the four rows of one box as { text, chunks }, chunks being { text, group } pairs
local function box_rows(room, box, opts)
  local inner = box - 4
  local here = room.key == opts.here
  local group = room_group(room, here)
  local glyph = room.cleared and opts.glyphs.cleared or opts.glyphs.left
  local marker = here and (" " .. M.HERE) or ""
  local name_width = inner - vim.fn.strdisplaywidth(glyph) - 1 - vim.fn.strdisplaywidth(marker)
  local detail = M.leftovers(room)
  local path_width = inner - (detail ~= "" and vim.fn.strdisplaywidth(detail) + 1 or 0)
  local path = path_width >= 4 and fit(room.key, path_width) or ""
  local second = detail ~= "" and (path ~= "" and path .. " " .. detail or fit(detail, inner))
    or fit(room.key, inner)
  return {
    { { "╭" .. ("─"):rep(box - 2) .. "╮", group } },
    {
      { "│ ", group },
      { glyph .. " ", group },
      { fit(room.name, name_width), group .. "Name" },
      { marker, "EldenMapHere" },
      { " │", group },
    },
    { { "│ ", group }, { fit(second, inner), "EldenMapPath" }, { " │", group } },
    { { "╰" .. ("─"):rep(box - 2) .. "╯", group } },
  }
end

-- joins chunks into one line, turning each chunk into a mark with byte columns
local function join(row_chunks, line, marks, row)
  for _, chunk in ipairs(row_chunks) do
    if chunk[1] ~= "" then
      table.insert(marks, { row = row, col = #line, end_col = #line + #chunk[1], group = chunk[2] })
      line = line .. chunk[1]
    end
  end
  return line
end

local function wing_header(wing, width)
  local cleared = M.progress(wing.rooms)
  local title = (" %s  %d/%d "):format(wing.name, cleared, #wing.rooms)
  local rule = math.max(0, width - vim.fn.strdisplaywidth(title) - 2)
  return "──" .. title .. ("─"):rep(rule)
end

local function place_row(rooms, box, opts, out)
  local first_row = #out.lines
  for line_index = 1, 4 do
    local line = ""
    for index, room in ipairs(rooms) do
      if index > 1 then
        line = line .. (" "):rep(M.BOX.gap)
      end
      local start = #line
      line =
        join(box_rows(room, box, opts)[line_index], line, out.marks, first_row + line_index - 1)
      if line_index == 2 then
        table.insert(out.rooms, { row = #out.lines, col = start, end_col = #line, key = room.key })
      end
    end
    table.insert(out.lines, line)
  end
end

--- Draws the rooms as a map: a header per wing (top folder) and its rooms as boxes in rows, red
--- while something is left inside, blue once cleared, the room you stand in marked.
---@param rooms table[] from M.rooms
---@param opts { width: integer, here?: string, glyphs: { left: string, cleared: string } }
---@return { lines: string[], marks: { row: integer, col: integer, end_col: integer, group: string }[], rooms: { row: integer, col: integer, end_col: integer, key: string }[] }
function M.layout(rooms, opts)
  local box, per_row = M.box_size(rooms, opts.width)
  local out = { lines = {}, marks = {}, rooms = {} }
  for index, wing in ipairs(M.wings(rooms)) do
    if index > 1 then
      table.insert(out.lines, "")
    end
    local header = wing_header(wing, math.min(opts.width, per_row * (box + M.BOX.gap) - M.BOX.gap))
    table.insert(
      out.marks,
      { row = #out.lines, col = 0, end_col = #header, group = "EldenMapWing" }
    )
    table.insert(out.lines, header)
    for first = 1, #wing.rooms, per_row do
      place_row(vim.list_slice(wing.rooms, first, first + per_row - 1), box, opts, out)
    end
  end
  return out
end

--- Finds the room drawn under a cursor position of the map.
---@param placed { row: integer, col: integer, end_col: integer, key: string }[] from M.layout
---@param row integer zero based line
---@param col integer zero based byte column
---@return string|nil key
function M.room_at(placed, row, col)
  for _, spot in ipairs(placed) do
    -- every row of a box belongs to its room, the name row is the one recorded
    if row >= spot.row - 1 and row <= spot.row + 2 and col >= spot.col and col < spot.end_col then
      return spot.key
    end
  end
  return nil
end

return M
