-- The ruler: instead of a column painted down the whole window, only the part of a line that runs
-- past the limit (textwidth, or 100) is tinted, so inline blame and long comments are never split.
-- Wrapped prose without a textwidth has no column to keep and goes without.
local actions = require("core.chrome.actions")

local M = {}

local function define_highlights()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  vim.api.nvim_set_hl(0, "EldenOverLength", { bg = blend(p.red, p.base, 0.22) })
end

-- only buffers holding a file get the ruler, never pickers, terminals or the HUD
local function wants_ruler(win)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  return actions.ruler_applies(vim.bo[buf].textwidth, vim.wo[win].wrap)
end

--- Draws the ruler in a window, replacing the one it had, or takes it away where it does not belong.
---@param win integer
function M.draw(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local previous = vim.w[win].eldentree_ruler
  if previous then
    pcall(vim.fn.matchdelete, previous, win)
    vim.w[win].eldentree_ruler = nil
  end
  if not wants_ruler(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local pattern = actions.overflow_pattern(actions.ruler_limit(vim.bo[buf].textwidth))
  vim.w[win].eldentree_ruler = vim.fn.matchadd("EldenOverLength", pattern, -1, -1, { window = win })
end

function M.setup(group)
  vim.o.colorcolumn = ""
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "FileType" }, {
    group = group,
    callback = function()
      M.draw(vim.api.nvim_get_current_win())
    end,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = { "textwidth", "wrap" },
    callback = function()
      M.draw(vim.api.nvim_get_current_win())
    end,
  })
end

return M
