-- Pure logic for the insert trace: a short memory of keys and the line written when insert mode ends.
local M = {}

M.MEMORY = 24

--- Adds a key to the memory, forgetting the oldest once it is full.
---@param memory string[]
---@param entry string
---@param size? integer
---@return string[]
function M.remember(memory, entry, size)
  table.insert(memory, entry)
  while #memory > (size or M.MEMORY) do table.remove(memory, 1) end
  return memory
end

--- Describes one key: what was typed, and what a mapping turned it into when they differ.
---@param key string the key nvim processed, already readable
---@param typed string what the person typed, already readable, empty when a mapping or plugin sent it
---@return string
function M.describe_key(key, typed)
  if typed == "" then return "{" .. key .. "}" end
  if typed ~= key then return typed .. ">" .. key end
  return key
end

--- Tells whether a mode change left insert mode for normal mode.
---@param old string
---@param new string
---@return boolean
function M.left_insert(old, new)
  return (old or ""):sub(1, 1) == "i" and (new or ""):sub(1, 1) == "n"
end

--- Guesses who ended insert mode from the keys right before it.
---@param memory string[] described keys, newest last
---@return string
function M.suspect(memory)
  local last, before = memory[#memory] or "", memory[#memory - 1] or ""
  if last == "<Esc>" then return "you pressed Esc" end
  if last == "{<Esc>}" then return "a plugin sent Esc (" .. before .. " came before it)" end
  if last:find("><Esc>$") then return "a mapping turned " .. last:match("^(.-)><Esc>$") .. " into Esc" end
  return "no Esc arrived, something switched windows or called stopinsert"
end

--- Writes the log line for one exit from insert mode.
---@param when string
---@param memory string[]
---@param context { file: string, filetype: string, floats: integer, mode: string }
---@return string
function M.entry(when, memory, context)
  return ("%s  %s  ->%s  [%s %s, %d floats]  keys: %s"):format(when, M.suspect(memory), context.mode,
    context.file, context.filetype, context.floats, table.concat(memory, " "))
end

return M
