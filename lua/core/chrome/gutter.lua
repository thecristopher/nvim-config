-- The gutter: line numbers fade with their distance to the cursor, the nearest one wearing a
-- touch of the region's accent, and windows out of focus drop their cursor line and dim every number.
local actions = require("core.chrome.actions")

local M = {}

local EXPRESSION = "%!v:lua.require'core.chrome.gutter'.render()"

local function define_highlights()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  for index, step in ipairs(actions.GUTTER_STEPS) do
    local fg = blend(p.subtext1, p.base, step)
    if index == 1 then
      fg = blend(p.yellow, fg, 0.35)
    end
    vim.api.nvim_set_hl(0, "EldenNr" .. index, { fg = fg })
  end
end

---The statuscolumn: snacks builds it, the number gets the color of its distance.
---@return string
function M.render()
  local ok, column = pcall(require("snacks.statuscolumn").get)
  if not ok then
    return ""
  end
  local focused = vim.g.statusline_winid == vim.api.nvim_get_current_win()
  return actions.paint_number(column, vim.v.relnum, focused)
end

-- windows holding a file show their cursor line only while in focus; trees, pickers and lists keep
-- theirs, it is how they show the selection. Changing the option also redraws the window, so its
-- numbers repaint in the faint step right away
local function follow_focus(on)
  return function()
    if vim.bo.buftype ~= "" or vim.api.nvim_win_get_config(0).relative ~= "" then
      return
    end
    vim.wo.cursorline = on
  end
end

local function take_over()
  if not vim.o.statuscolumn:find("snacks.statuscolumn", 1, true) then
    return
  end
  vim.o.statuscolumn = EXPRESSION
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.wo[win].statuscolumn:find("snacks.statuscolumn", 1, true) then
      vim.wo[win].statuscolumn = EXPRESSION
    end
  end
end

function M.setup(group)
  define_highlights()
  vim.api.nvim_create_autocmd(
    { "WinEnter", "BufWinEnter" },
    { group = group, callback = follow_focus(true) }
  )
  vim.api.nvim_create_autocmd("WinLeave", { group = group, callback = follow_focus(false) })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = take_over,
  })
end

return M
