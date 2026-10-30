-- The command line popup in the franchise's words and glyphs, renamed on every franchise switch.
local actions = require("core.chrome.actions")

local M = {}

---The noice cmdline formats for the franchise in use.
---@return table<string, table>
function M.formats()
  local lore = require("core.franchise").current()
  return actions.cmdline_formats(lore.chrome, lore.skin.cmdline, lore.skin.ornament or { "", "" })
end

-- noice expands its formats once at setup and its routes point at the same tables, so they are
-- changed in place: the next show builds a new popup from them
local function apply()
  local ok, config = pcall(require, "noice.config")
  if not ok or not (config.options.cmdline and config.options.cmdline.format) then
    return
  end
  local border = require("core.skin").border()
  for name, fresh in pairs(M.formats()) do
    local format = config.options.cmdline.format[name]
    if format and format.opts and format.opts.border then
      format.icon = fresh.icon
      format.opts.border.text = format.opts.border.text or {}
      format.opts.border.text.top = fresh.title
      format.opts.border.style = border
    end
  end
  local popup = config.options.views and config.options.views.cmdline_popup
  if popup and popup.border then
    popup.border.style = border
  end
end

function M.setup(group)
  vim.api.nvim_create_autocmd(
    "User",
    { group = group, pattern = "EldentreeFranchise", callback = apply }
  )
end

return M
