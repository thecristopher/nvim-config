-- Player messages left on the ground of your code. Pure bookkeeping over a store shaped like
-- { [repo] = { [relative_file] = { { line = 12, text = "Be wary of null" }, ... } } }
local M = {}

M.TEMPLATES = {
  "Try %s",
  "Be wary of %s",
  "%s ahead",
  "Praise the %s!",
  "Could this be a %s?",
  "If only I had a %s...",
  "Visions of %s...",
  "Time for %s",
  "Behold, %s!",
  "Seek %s",
  "Didn't expect %s...",
}

--- Fills a template with a word, the way the game builds its messages.
---@param template string a M.TEMPLATES entry
---@param word string|nil what fills the blank
---@return string|nil message # nil when the word is blank
function M.compose(template, word)
  word = vim.trim(word or "")
  if word == "" then return nil end
  local message = template:format(word)
  return message:sub(1, 1):upper() .. message:sub(2)
end

--- Returns the file path relative to the repo, or nil when it lives outside of it.
---@param repo string repo root
---@param file string absolute file path
---@return string|nil
function M.relative(repo, file)
  local prefix = repo:gsub("/+$", "") .. "/"
  if file:sub(1, #prefix) ~= prefix then return nil end
  return file:sub(#prefix + 1)
end

--- Returns the messages on a file, sorted by line.
---@param store table
---@param repo string
---@param file string relative file path
---@return table[] messages as { line, text }
function M.for_file(store, repo, file)
  local list = vim.deepcopy((store[repo] or {})[file] or {})
  table.sort(list, function(a, b) return a.line < b.line end)
  return list
end

-- an empty file entry or repo entry would pile up in the json forever
local function prune(store, repo, file)
  if store[repo] and store[repo][file] and #store[repo][file] == 0 then store[repo][file] = nil end
  if store[repo] and next(store[repo]) == nil then store[repo] = nil end
end

--- Writes a message on a line, replacing whatever was written there before.
---@param store table
---@param repo string
---@param file string relative file path
---@param line integer 1 based line
---@param text string
---@return table store
function M.put(store, repo, file, line, text)
  store[repo] = store[repo] or {}
  local kept = vim.tbl_filter(function(entry) return entry.line ~= line end, store[repo][file] or {})
  table.insert(kept, { line = line, text = text })
  store[repo][file] = kept
  return store
end

--- Erases the message on a line.
---@param store table
---@param repo string
---@param file string relative file path
---@param line integer 1 based line
---@return table store
---@return boolean erased # false when nothing was written there
function M.erase(store, repo, file, line)
  local list = (store[repo] or {})[file] or {}
  local kept = vim.tbl_filter(function(entry) return entry.line ~= line end, list)
  if #kept == #list then return store, false end
  store[repo][file] = kept
  prune(store, repo, file)
  return store, true
end

--- Replaces a file's messages, used after edits move them to new lines.
---@param store table
---@param repo string
---@param file string relative file path
---@param messages table[] as { line, text }
---@return table store
function M.replace(store, repo, file, messages)
  store[repo] = store[repo] or {}
  store[repo][file] = messages
  prune(store, repo, file)
  return store
end

--- Lists every message in a repo, by file then line, ready for a picker.
---@param store table
---@param repo string
---@return table[] entries as { file, line, text }
function M.list(store, repo)
  local entries = {}
  for file in pairs(store[repo] or {}) do
    for _, message in ipairs(M.for_file(store, repo, file)) do
      table.insert(entries, { file = file, line = message.line, text = message.text })
    end
  end
  table.sort(entries, function(a, b)
    if a.file ~= b.file then return a.file < b.file end
    return a.line < b.line
  end)
  return entries
end

return M
