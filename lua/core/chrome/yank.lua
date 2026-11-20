-- What you yank, and what you paste, glows in the region's accent and fades out on core/motion's
-- clock, instead of the default highlight snapping off. With motion stilled it stays a short plain flash, so a yank always
-- shows what it took.
local M = {}

M.DURATION = 320

-- lights a group in the accent and lets it fade to the background, or holds it while motion is still
local function glow(group)
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  vim.api.nvim_set_hl(0, group, { bg = blend(p.yellow, p.base, 0.45) })
  local motion = require("core.motion")
  if motion.enabled() then
    motion.fade_hl(group, { bg = p.base }, { duration = M.DURATION, easing = "in_cubic" })
  end
end

--- Flashes the text just yanked. Call it from TextYankPost.
function M.flash()
  vim.hl.on_yank({ higroup = "EldenYank", timeout = M.DURATION })
  glow("EldenYank")
  -- a cut fires TextYankPost too, only a real yank sounds like one
  if vim.v.event.operator == "y" then
    require("core.sound").play("yank")
  end
end

--- Lights what the next put lands on: yanky marks it with YankyPut for DURATION, this gives it
--- the same glow a yank gets. Call it right before a yanky put.
function M.prime_put()
  glow("YankyPut")
  require("core.sound").play("yank")
end

return M
