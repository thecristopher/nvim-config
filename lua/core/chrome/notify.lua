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

--- Opens the notification history titled in the franchise's words between the skin's ornaments,
--- each entry under the franchise's word for its level, the same one its popup wore. Pressed again
--- from inside the history, it closes it.
function M.show_history()
  if vim.bo.filetype == "snacks_notif_history" then
    return vim.cmd("close")
  end
  local chrome = require("core.franchise").current().chrome
  local lines, marks =
    actions.history_lines(Snacks.notifier.get_history({ reverse = true }), chrome)
  local win = Snacks.win({
    style = "notification_history",
    title = " " .. require("core.skin").title(chrome.history or "Notification History") .. " ",
    -- the entries carry their own hour, numbers in the gutter would only repeat the row
    wo = { number = false, relativenumber = false, statuscolumn = "", signcolumn = "no" },
    enter = true,
    show = false,
  })
  local buf = win:open_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("eldentree_notify_history")
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(
      buf,
      ns,
      mark.row,
      mark.first,
      { end_col = mark.last, hl_group = mark.group }
    )
  end
  win:show()
end

return M
