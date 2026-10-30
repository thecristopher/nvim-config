-- The editor's chrome in the franchise in use: the mode badge, the gutter, the notifications,
-- the pickers and the command line. Words come from lore.chrome, shapes from the skin.
local M = {}

---The current mode's name in the franchise in use, for the statusline.
---@return string
function M.label()
  return require("core.chrome.modes").label()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_chrome", { clear = true })
  require("core.chrome.modes").setup(group)
  require("core.chrome.gutter").setup(group)
  require("core.chrome.cmdline").setup(group)
end

return M
