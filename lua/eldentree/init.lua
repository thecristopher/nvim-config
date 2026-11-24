-- The Eldentree engine in one call: sets up every core module in the order they need each other.
-- This config calls it from init.lua, and another config can call it with `only` or `skip` to take
-- the pieces it wants, see docs/modules/engine.md.
local modules = require("eldentree.modules")

local M = {}

local function report(name, err)
  vim.schedule(function()
    vim.notify(("core.%s failed to set up:\n%s"):format(name, err), vim.log.levels.ERROR, {
      title = "Eldentree",
    })
  end)
end

--- Sets up the engine's modules, every one unless `only` or `skip` say otherwise.
---@param opts { only?: string[], skip?: string[] }|nil
function M.setup(opts)
  opts = opts or {}
  local unknown =
    modules.unknown(vim.list_extend(vim.list_extend({}, opts.only or {}), opts.skip or {}))
  if #unknown > 0 then
    report("setup", "unknown modules: " .. table.concat(unknown, ", "))
  end
  -- one module failing should not leave the editor without the rest
  for _, name in ipairs(modules.selected(opts)) do
    local ok, err = xpcall(function()
      require("core." .. name).setup()
    end, debug.traceback)
    if not ok then
      report(name, err)
    end
  end
end

return M
