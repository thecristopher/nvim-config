-- The health ECG in the statusline while the franchise plays it: Fine, Caution or Danger,
-- read from the current buffer's diagnostics, with the trace scrolling at the heart's pace.
local actions = require("core.ecg.actions")
local motion = require("core.motion")

local M = {}

local trace = actions.trace("fine", 0)
local condition = "fine"

local function active()
  return require("core.franchise").mechanic("status") == "ecg"
end

local function read_condition()
  local severity = vim.diagnostic.severity
  local counts = vim.diagnostic.count(0)
  return actions.condition(counts[severity.ERROR] or 0, counts[severity.WARN] or 0)
end

local function define_highlights()
  local p = require("core.themes").palette()
  for name, look in pairs(actions.CONDITIONS) do
    vim.api.nvim_set_hl(
      0,
      "EldenEcg" .. look.label,
      { fg = p[look.color], bg = p.surface0, bold = name ~= "fine" }
    )
  end
end

local function refresh_statusline()
  require("core.utils").refresh_statusline()
end

-- the statusline only repaints when the trace actually moved
local function beat(elapsed)
  if not active() then
    return
  end
  condition = read_condition()
  local next_trace = actions.trace(condition, elapsed)
  if next_trace == trace then
    return
  end
  trace = next_trace
  refresh_statusline()
end

--- Returns the statusline piece: the trace and the condition, in the condition's color.
---@return string
function M.statusline()
  local look = actions.CONDITIONS[condition]
  return ("%%#EldenEcg%s#%s %s"):format(look.label, trace, look.label)
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("eldentree_ecg", { clear = true }),
    callback = define_highlights,
  })
  M.monitor = motion.loop({ interval = 60, on_tick = beat })
end

return M
