-- The gutter: line numbers fade with their distance to the cursor, the nearest one wearing a
-- touch of the region's accent.
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
  return actions.paint_number(column, vim.v.relnum)
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
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = take_over,
  })
end

return M
