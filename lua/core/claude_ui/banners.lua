-- Prints the banner words of today's franchise as JSON for the eldentree-banners Claude Code mod,
-- so the mod never keeps its own copy of franchise text.
local spaced = require("core.banner.actions").spaced

local M = {}

--- Writes { franchise, died, felled } to stdout, each banner letterspaced like the game.
---@param _root string repo root, unused
---@param _args string[] command line arguments, unused
function M.run(_root, _args)
  local lore = require("core.franchise").current()
  io.write(vim.json.encode({
    franchise = lore.title,
    died = spaced(lore.banners.died),
    felled = spaced(lore.banners.felled),
  }))
end

return M
