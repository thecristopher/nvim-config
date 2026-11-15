-- Pure steps behind the repo's own spell word list.
local M = {}

--- Whether the compiled word list has to be built again: it is missing, or older than the list.
---@param add_mtime integer|nil seconds, nil when the word list itself is missing
---@param spl_mtime integer|nil seconds, nil when it was never compiled
---@return boolean
function M.needs_build(add_mtime, spl_mtime)
  if not add_mtime then
    return false
  end
  return spl_mtime == nil or spl_mtime < add_mtime
end

return M
