-- Zones: every folder of a project is a place in the franchise's world. Pure naming and timing only.
local utils = require("core.utils")

local M = {}

M.COOLDOWN_MS = 20 * 1000
M.DEPTH = 2

--- Returns the zone a file lives in: its folder under the repo root, cut to DEPTH segments.
---@param file string absolute file path
---@param root string|nil repo root
---@return string|nil zone like "lua/core", nil for files at the root or outside it
function M.zone_key(file, root)
  if not root or file:sub(1, #root + 1) ~= root .. "/" then
    return nil
  end
  local relative_dir = vim.fs.dirname(file:sub(#root + 2))
  if relative_dir == "." or relative_dir == "" then
    return nil
  end
  local segments = vim.split(relative_dir, "/", { plain = true })
  return table.concat(vim.list_slice(segments, 1, M.DEPTH), "/")
end

--- Names a zone: a landmark when its folder is a well known one, otherwise a stable place for it.
---@param key string zone from M.zone_key
---@return string
function M.zone_name(key)
  local lore = require("core.franchise").current()
  local segments = vim.split(key, "/", { plain = true })
  for index = #segments, 1, -1 do
    local landmark = lore.landmarks[segments[index]]
    if landmark then
      return landmark
    end
  end
  return lore.places[utils.hash(key) % #lore.places + 1]
end

--- Decides whether entering a zone deserves its banner.
---@param opts { key: string|nil, seen: table<string, boolean>, now: number, last_shown: number|nil, busy: boolean }
---@return boolean
function M.should_announce(opts)
  if not opts.key or opts.seen[opts.key] or opts.busy then
    return false
  end
  return not opts.last_shown or opts.now - opts.last_shown >= M.COOLDOWN_MS
end

return M
