-- The explorer in the franchise's clothes: which folders are rooms still to clear, which files carry
-- review threads or ground messages. Pure logic only.
local zones = require("core.zones.actions")

local M = {}

--- Returns a path relative to the repo root, nil for the root itself or anything outside it.
---@param root string repo root
---@param path string absolute path
---@return string|nil
function M.relative(root, path)
  if not root or not path or path:sub(1, #root + 1) ~= root .. "/" then
    return nil
  end
  return path:sub(#root + 2)
end

local function depth(relative)
  return #vim.split(relative, "/", { plain = true })
end

local function inside(key, relative)
  return key == relative or key:sub(1, #relative + 1) == relative .. "/"
end

--- Tells whether a folder still hides something or is cleared, from the rooms of :Map. Only
--- folders as deep as a room get a state, deeper ones would only repeat their room's.
---@param rooms { key: string, cleared: boolean }[]|nil from core.map.actions.rooms
---@param relative string|nil folder relative to the repo root
---@return "left"|"cleared"|nil
function M.folder_state(rooms, relative)
  if not rooms or not relative or depth(relative) > zones.DEPTH then
    return nil
  end
  local found = false
  for _, room in ipairs(rooms) do
    if inside(room.key, relative) then
      if not room.cleared then
        return "left"
      end
      found = true
    end
  end
  return found and "cleared" or nil
end

--- Counts entries per file.
---@param entries table[]|nil review threads or ground messages
---@param field string the field that names the file, "path" for threads and "file" for messages
---@return table<string, integer>
function M.count_by_file(entries, field)
  local counts = {}
  for _, entry in ipairs(entries or {}) do
    local file = entry[field]
    if type(file) == "string" then
      counts[file] = (counts[file] or 0) + 1
    end
  end
  return counts
end

--- The marks after a file's name: its open threads with their count and a ground message.
---@param relative string|nil file relative to the repo root
---@param threads table<string, integer> open threads per file
---@param messages table<string, integer> ground messages per file
---@param tree table skin.tree
---@return { text: string, highlight: string }[]
function M.file_marks(relative, threads, messages, tree)
  if not relative then
    return {}
  end
  local marks = {}
  local open = threads[relative]
  if open then
    table.insert(
      marks,
      { text = ("%s %d "):format(tree.thread, open), highlight = "EldenTreeThread" }
    )
  end
  if messages[relative] then
    table.insert(marks, { text = tree.message .. " ", highlight = "EldenTreeMessage" })
  end
  return marks
end

--- The mark beside a folder: the skin's glyph for a room still left, nothing once it is cleared,
--- so the one mark in the tree is the folder that needs you.
---@param state "left"|"cleared"|nil from M.folder_state
---@param tree table skin.tree
---@return { text: string, highlight: string }|nil
function M.folder_mark(state, tree)
  if state == "left" then
    return { text = tree.left .. " ", highlight = "EldenTreeLeft" }
  end
  return nil
end

return M
