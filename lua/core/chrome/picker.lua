-- The snacks pickers per franchise: the layout the skin names, its titles between the ornaments.
local actions = require("core.chrome.actions")

local M = {}

-- results above the prompt, like choosing at a grace
M.GRACE = {
  reverse = true,
  layout = {
    box = "horizontal",
    width = 0.84,
    min_width = 120,
    height = 0.84,
    border = "none",
    {
      box = "vertical",
      { win = "list", title = "{title} {live} {flags}", border = true },
      { win = "input", height = 1, border = true },
    },
    { win = "preview", title = "{preview}", width = 0.52, border = true },
  },
}

-- the item list on the left, what you examine on the right, the prompt on top like the case's label
M.INVENTORY = {
  layout = {
    box = "horizontal",
    width = 0.84,
    min_width = 120,
    height = 0.82,
    {
      box = "vertical",
      width = 0.42,
      border = true,
      title = "{title} {live} {flags}",
      { win = "input", height = 1, border = "bottom" },
      { win = "list", border = "none" },
    },
    { win = "preview", title = "{preview}", border = true },
  },
}

---The layout preset of the franchise in use, a stacked one on narrow screens.
---@return string
function M.preset()
  if vim.o.columns < 120 then
    return "vertical"
  end
  return require("core.skin").current().picker or "default"
end

---Frames whatever layout a picker resolved to in the franchise's ornaments.
---@param layout table
---@return table
function M.frame(layout)
  local skin = require("core.skin").current()
  local examine = require("core.franchise").current().chrome.examine
  return actions.frame_layout(layout, skin.ornament or { "", "" }, examine)
end

return M
