-- Loads the plugins nobody needs in the first frame one per tick after startup, instead of all of
-- them in one VeryLazy burst, so keys typed right away never wait behind a pile of setups. Each
-- plugin still loads earlier through its own keys or commands when they come first.
local actions = require("core.later.actions")

local M = {}

local function load_next(queue)
  local name = table.remove(queue, 1)
  if not name then
    return
  end
  pcall(require("lazy").load, { plugins = { name } })
  vim.defer_fn(function()
    load_next(queue)
  end, 0)
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      vim.defer_fn(function()
        load_next(actions.pending(require("lazy.core.config").plugins))
      end, actions.DELAY_MS)
    end,
  })
end

return M
