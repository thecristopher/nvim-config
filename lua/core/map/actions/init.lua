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
    if file then counts[file] = tonumber(count) end
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
    if key then room_for(rooms, key).todos = room_for(rooms, key).todos + (todos[file] or 0) end
  end
  for path, count in pairs(errors) do
    local key = zones.zone_key(path, root)
    if key then room_for(rooms, key).errors = room_for(rooms, key).errors + count end
  end

  local list = {}
  for key, room in pairs(rooms) do
    room.name = zones.zone_name(key)
    room.cleared = room.todos == 0 and room.errors == 0
    table.insert(list, room)
  end
  table.sort(list, function(a, b) return a.key < b.key end)
  return list
end

--- Describes what is still left in a room, empty once it is cleared.
---@param room table from M.rooms
---@return string
function M.leftovers(room)
  local parts = {}
  if room.errors > 0 then table.insert(parts, room.errors .. (room.errors == 1 and " error" or " errors")) end
  if room.todos > 0 then table.insert(parts, room.todos .. (room.todos == 1 and " TODO" or " TODOs")) end
  return table.concat(parts, ", ")
end

--- Counts the rooms already cleared.
---@param rooms table[] from M.rooms
---@return integer cleared, integer total
function M.progress(rooms)
  local cleared = #vim.tbl_filter(function(room) return room.cleared end, rooms)
  return cleared, #rooms
end

return M
