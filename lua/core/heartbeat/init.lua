-- The heartbeat statusline piece for franchises whose status is heartbeat: a heart that beats
-- calm on a clean buffer and races with its errors, next to the stage you stand on.
local actions = require("core.heartbeat.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

local M = {}

local condition = "fine"
local level = 1

local function active()
  return require("core.franchise").mechanic("status") == "heartbeat"
end

local function read_condition()
  local severity = vim.diagnostic.severity
  local counts = vim.diagnostic.count(0)
  return actions.condition(counts[severity.ERROR] or 0, counts[severity.WARN] or 0)
end

-- every step of the pulse gets its own group once, so beating never redefines a highlight
local function define_highlights()
  local p = require("core.themes").palette()
  local rest, peak = color.to_int(p.overlay2), color.to_int(p.pink)
  for step = 1, actions.GLOW_LEVELS do
    local fg = color.mix(rest, peak, (step - 1) / (actions.GLOW_LEVELS - 1))
    vim.api.nvim_set_hl(0, "EldenHeart" .. step, { fg = fg, bg = p.surface0, bold = true })
  end
end

-- the statusline only repaints when the heart changed brightness or pace
local function beat(elapsed)
  if not active() then
    return
  end
  local next_condition = read_condition()
  local next_level = actions.glow_level(elapsed, next_condition)
  if next_level == level and next_condition == condition then
    return
  end
  condition, level = next_condition, next_level
  require("core.utils").refresh_statusline()
end

--- Returns the statusline piece: the heart at its current brightness and the stage's title.
---@return string
function M.statusline()
  local glyph = actions.PACES[condition].glyph
  return ("%%#EldenHeart%d#%s %s"):format(level, glyph, require("core.themes").current().title)
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_heartbeat", { clear = true }),
    callback = define_highlights,
  })
  -- the lub lasts about a tenth of a beat, so it needs a faster tick than the grace's breath
  M.monitor = motion.loop({ interval = 50, on_tick = beat })
end

return M
