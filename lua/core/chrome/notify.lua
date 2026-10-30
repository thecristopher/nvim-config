-- Notifications dressed as the game's messages: the franchise's word for the level between its
-- ornaments, and the hour it arrived in the corner.
local actions = require("core.chrome.actions")

local M = {}

---A snacks.notifier style.
---@param buf integer
---@param notif table snacks.notifier.Notif
---@param ctx table snacks.notifier.ctx
function M.style(buf, notif, ctx)
  local chrome = require("core.franchise").current().chrome
  local title = actions.notify_title(notif.title, notif.level, chrome)
  local label = vim.trim((notif.icon or "") .. " " .. title)
  ctx.opts.title = { { " " .. require("core.skin").title(label) .. " ", ctx.hl.title } }
  ctx.opts.title_pos = "center"
  ctx.opts.footer = { { " " .. os.date("%H:%M", notif.added) .. " ", ctx.hl.footer } }
  ctx.opts.footer_pos = "right"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(notif.msg, "\n"))
end

return M
