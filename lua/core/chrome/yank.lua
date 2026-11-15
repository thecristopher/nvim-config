-- What you yank glows in the region's accent and fades out on core/motion's clock, instead of the
-- default highlight snapping off. With motion stilled it stays a short plain flash, so a yank always
-- shows what it took.
local M = {}

M.DURATION = 320

--- Flashes the text just yanked. Call it from TextYankPost.
function M.flash()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  vim.api.nvim_set_hl(0, "EldenYank", { bg = blend(p.yellow, p.base, 0.45) })
  vim.hl.on_yank({ higroup = "EldenYank", timeout = M.DURATION })
  local motion = require("core.motion")
  if motion.enabled() then
    motion.fade_hl("EldenYank", { bg = p.base }, { duration = M.DURATION, easing = "in_cubic" })
  end
end

return M
