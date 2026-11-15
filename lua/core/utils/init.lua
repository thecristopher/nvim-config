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

--- Writes one of Eldentree's own state files (tallies, the region of the day, caches). Losing
--- the last write to a crash costs nothing, so it skips the fsync that makes writefile take
--- milliseconds instead of microseconds, which matters for files written on every save.
---@param path string
---@param lines string[]
---@param flags? string extra writefile flags, like "a" to append
---@return boolean ok
function M.write_state(path, lines, flags)
  return (pcall(vim.fn.writefile, lines, path, (flags or "") .. "S"))
end

--- Repaints the statusline. lualine draws one global statusline, so only the current window is
--- refreshed: refreshing every window lets lualine lose track of the focused one in command mode
--- and paint the inactive line over the real one. Calls that land in the same tick share one
--- repaint, so the grace, the ECG and the music moving on the same frame redraw once.
local statusline_pending = false
function M.refresh_statusline()
  if statusline_pending then
    return
  end
  statusline_pending = true
  vim.schedule(function()
    statusline_pending = false
    local ok, lualine = pcall(require, "lualine")
    if ok then
      lualine.refresh({ place = { "statusline" }, scope = "window" })
    end
  end)
end

--- Picks the first folder that holds a portrait, so private portraits outside the repo win over
--- the ones it ships.
---@param file string|nil the portrait's file name, like "claire.jpg"
---@param dirs string[] folders to look in, in order
---@param readable fun(path: string): boolean
---@return string|nil path nil when no folder has it
function M.find_portrait(file, dirs, readable)
  if not file then
    return nil
  end
  for _, dir in ipairs(dirs) do
    local path = dir .. "/" .. file
    if readable(path) then
      return path
    end
  end
  return nil
end

--- The folders portraits live in: the private one first (`vim.g.eldentree_portraits_dir`, or
--- eldentree/portraits in stdpath data), never committed, then images/portraits in the config.
---@return string[]
function M.portrait_dirs()
  return {
    vim.g.eldentree_portraits_dir or (vim.fn.stdpath("data") .. "/eldentree/portraits"),
    vim.fn.stdpath("config") .. "/images/portraits",
  }
end

--- Where a portrait is on disk. A portrait no folder holds points at the config's folder, so a
--- readability check on it still says no.
---@param file string the portrait's file name
---@return string
function M.portrait_path(file)
  local found = M.find_portrait(file, M.portrait_dirs(), function(path)
    return vim.fn.filereadable(path) == 1
  end)
  return found or (M.portrait_dirs()[2] .. "/" .. file)
end

return M
