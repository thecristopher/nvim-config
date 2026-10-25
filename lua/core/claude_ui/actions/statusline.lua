-- Claude Code's statusline in the franchise's colors: the region, branch, model, runes and song on
-- top, and below them the context left plus both usage limits drawn as the game's own bars
-- (HP, FP and stamina in the Lands Between, the CONDITION monitor in Raccoon City). Pure logic only.
local ecg = require("core.ecg.actions")

local M = {}

M.BAR_WIDTH = 10
M.SONG_WIDTH = 32
local RESET = "\27[0m"
local SEPARATOR = "  "

--- Wraps text in a 24 bit foreground color.
---@param hex string like "#C9A84C"
---@param text string
---@return string
function M.paint(hex, text)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    return text
  end
  return ("\27[38;2;%d;%d;%dm%s%s"):format(
    tonumber(r, 16),
    tonumber(g, 16),
    tonumber(b, 16),
    text,
    RESET
  )
end

--- Draws a bar filled to a percentage.
---@param percent number 0 to 100
---@param width integer|nil cells, M.BAR_WIDTH by default
---@return string
function M.bar(percent, width)
  width = width or M.BAR_WIDTH
  local filled = math.floor(math.max(0, math.min(100, percent)) / 100 * width + 0.5)
  return ("█"):rep(filled) .. ("░"):rep(width - filled)
end

--- Reads how healthy a session is from the context it has left.
---@param remaining number percent of the context window still free
---@return string condition: fine, caution or danger
function M.condition(remaining)
  if remaining > 50 then
    return "fine"
  end
  if remaining > 25 then
    return "caution"
  end
  return "danger"
end

--- Writes a number with thousands separators, like 161,150.
---@param value number
---@return string
function M.thousands(value)
  local text = tostring(math.floor(value))
  local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (formatted:gsub("^,", ""))
end

local function remaining_of(limit)
  if type(limit) ~= "table" or type(limit.used_percentage) ~= "number" then
    return nil
  end
  return 100 - limit.used_percentage
end

local function context_left(data)
  local window = data.context_window
  if type(window) ~= "table" then
    return nil
  end
  return window.remaining_percentage
end

local function header(data, ctx)
  local p = ctx.region.palette
  local parts = { M.paint(p.yellow, "✦ " .. ctx.region.title) }
  if ctx.branch and ctx.branch ~= "" then
    table.insert(parts, M.paint(p.subtext0, " " .. ctx.branch))
  end
  if type(data.model) == "table" and data.model.display_name then
    table.insert(parts, M.paint(p.lavender or p.text, "󰚩 " .. data.model.display_name))
  end
  if ctx.runes then
    table.insert(parts, M.paint(p.yellow, ctx.lore.currency.glyph .. " " .. M.thousands(ctx.runes)))
  end
  if ctx.song and ctx.song ~= "" then
    table.insert(parts, M.paint(p.mauve or p.text, ctx.song))
  end
  return table.concat(parts, SEPARATOR)
end

local function meter(label, remaining, color, p)
  local value = ("%3d%%"):format(math.floor(remaining + 0.5))
  return M.paint(p.subtext0, label)
    .. " "
    .. M.paint(color, M.bar(remaining))
    .. " "
    .. M.paint(p.text, value)
end

local function heartbeat(label, remaining, p, now_ms)
  local condition = M.condition(remaining)
  local look = ecg.CONDITIONS[condition]
  local color = p[look.color] or p.text
  return M.paint(p.subtext0, label)
    .. " "
    .. M.paint(color, ecg.trace(condition, now_ms, M.BAR_WIDTH))
    .. " "
    .. M.paint(color, look.label)
end

local function meters(data, ctx)
  local p, bars = ctx.region.palette, ctx.lore.claude.bars
  local parts = {}
  local context = context_left(data)
  if context and ctx.ecg then
    table.insert(parts, heartbeat(bars.context, context, p, ctx.now_ms))
  elseif context then
    table.insert(parts, meter(bars.context, context, p.red, p))
  end
  local rate_limits = data.rate_limits or {}
  local five_hour = remaining_of(rate_limits.five_hour)
  if five_hour then
    table.insert(parts, meter(bars.five_hour, five_hour, p.blue or p.sky, p))
  end
  local seven_day = remaining_of(rate_limits.seven_day)
  if seven_day then
    table.insert(parts, meter(bars.seven_day, seven_day, p.green, p))
  end
  return table.concat(parts, SEPARATOR)
end

--- Renders the statusline rows Claude Code prints, one string per row.
---@param data table the JSON Claude Code sends on stdin
---@param ctx { lore: table, region: table, ecg: boolean, now_ms: number, branch: string|nil, runes: number|nil, song: string|nil }
---@return string[]
function M.render(data, ctx)
  local rows = { header(data, ctx) }
  local bottom = meters(data, ctx)
  if bottom ~= "" then
    table.insert(rows, bottom)
  end
  return rows
end

return M
