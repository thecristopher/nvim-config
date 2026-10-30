-- The statusline's mode badge: named the franchise's way, and fading into the next mode's color
-- instead of cutting to it.
local actions = require("core.chrome.actions")

local M = {}

---The mode's name in the franchise in use, for lualine's mode component.
---@return string
function M.label()
  return actions.mode_label(
    vim.api.nvim_get_mode().mode,
    require("core.franchise").current().chrome
  )
end

local function theme()
  return require("core.themes.actions").lualine_theme(require("core.themes").palette())
end

-- the badge and the separator glued to it, lualine creates the separator the first time it draws
local function badge_groups(mode)
  local groups = { ["lualine_a_" .. mode] = "bg" }
  local prefix = "lualine_transitional_lualine_a_" .. mode .. "_to_"
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    if name:sub(1, #prefix) == prefix then
      groups[name] = "fg"
    end
  end
  return groups
end

local function fade(from, to)
  local colors = theme()
  if not (colors[from] and colors[to]) or from == to then
    return
  end
  local motion = require("core.motion")
  for name, side in pairs(badge_groups(to)) do
    local target = vim.api.nvim_get_hl(0, { name = name, link = false })
    target[side] = colors[to].a.bg
    local start = vim.deepcopy(target)
    start[side] = colors[from].a.bg
    vim.api.nvim_set_hl(0, name, start)
    motion.fade_hl(name, target, { duration = 220 })
  end
end

function M.setup(group)
  local last = "normal"
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      local now = actions.mode_name(vim.v.event.new_mode)
      fade(last, now)
      last = now
    end,
  })
end

return M
