-- Claude Code's statusline in the franchise's colors: the branch, model and song on top, and below
-- them the context left plus both usage limits drawn as the game's own bars (HP, FP and stamina in
-- the Lands Between, CONDITION, AMMO and HERBS in Raccoon City). The region and the runes stay in
-- the editor's statusline under it. Pure logic only.

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
  local parts = {}
  if ctx.branch and ctx.branch ~= "" then
    table.insert(parts, M.paint(p.subtext0, " " .. ctx.branch))
  end
  if type(data.model) == "table" and data.model.display_name then
    table.insert(parts, M.paint(p.lavender or p.text, "󰚩 " .. data.model.display_name))
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

local function meters(data, ctx)
  local p, bars = ctx.region.palette, ctx.lore.claude.bars
  local parts = {}
  local context = context_left(data)
  if context then
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
---@param ctx { lore: table, region: table, branch: string|nil, song: string|nil }
---@return string[]
function M.render(data, ctx)
  local rows = {}
  for _, row in ipairs({ header(data, ctx), meters(data, ctx) }) do
    if row ~= "" then
      table.insert(rows, row)
    end
  end
  return rows
end

return M
