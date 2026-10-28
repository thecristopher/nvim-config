-- Small project wide helpers that more than one module needs.
local M = {}

--- Hashes text with djb2, small and stable across sessions and machines.
---@param text string
---@return integer
function M.hash(text)
  local value = 5381
  for index = 1, #text do
    value = (value * 33 + text:byte(index)) % 4294967296
  end
  return value
end

--- Adds execute next to every read permission, the way `chmod +x` does.
---@param perm string from getfperm, like "rw-r--r--"
---@return string like "rwxr-xr-x"
function M.executable_perm(perm)
  return (perm:gsub("r(.)%-", "r%1x"))
end

--- Names the OS nvim runs on, the way modules that shell out to it choose their commands.
---@return "mac"|"windows"|"linux"
function M.platform()
  if vim.fn.has("mac") == 1 then
    return "mac"
  end
  if vim.fn.has("win32") == 1 then
    return "windows"
  end
  return "linux"
end

return M
