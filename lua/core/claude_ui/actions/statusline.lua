-- Claude Code's statusline in the franchise's colors: the model and the region's character who
-- keeps you company on top, then both usage limits drawn as the game's own bars (FP and stamina in
-- the Lands Between, AMMO and HERBS in Raccoon City) with what the session has cost and how long
-- it has run. The branch shows only when Claude runs outside nvim: inside it, the editor's
-- statusline right under it already says it, and the song, the region and the runes stay there.
-- Pure logic only.

local M = {}

M.BAR_WIDTH = 10
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

--- Writes how long a session has run the way a save file would: minutes, then hours and minutes.
---@param ms number|nil
---@return string|nil nil when the session did not say
function M.duration(ms)
  if type(ms) ~= "number" or ms < 0 then
    return nil
  end
  local minutes = math.floor(ms / 60000)
  if minutes < 60 then
    return ("%dm"):format(minutes)
  end
  return ("%dh %02dm"):format(math.floor(minutes / 60), minutes % 60)
end

--- Writes what a session has cost so far.
---@param usd number|nil
---@return string|nil nil when the session did not say
function M.cost(usd)
  if type(usd) ~= "number" then
    return nil
  end
  return ("$%.2f"):format(usd)
end

--- Reads the branch out of a .git/HEAD line, nil for a detached head.
---@param head string|nil
---@return string|nil
function M.branch(head)
  return (head or ""):match("^ref: refs/heads/(.+)$")
end

-- the franchise's own mark, the left ornament its float titles wear
local function emblem(lore)
  local ornament = ((lore.skin or {}).ornament or {})[1] or ""
  return vim.trim(ornament)
end

local function header(data, ctx)
  local p = ctx.region.palette
  if type(data.model) ~= "table" or not data.model.display_name then
    return ""
  end
  local parts = { M.paint(p.lavender or p.text, "󰚩 " .. data.model.display_name) }
  if ctx.region.character then
    local mark = emblem(ctx.lore)
    table.insert(
      parts,
      M.paint(p.yellow, (mark ~= "" and mark .. " " or "") .. ctx.region.character)
    )
  end
  if ctx.branch then
    table.insert(parts, M.paint(p.subtext0, "󰘬 " .. ctx.branch))
  end
  return table.concat(parts, SEPARATOR)
end

local function session(data, p)
  local parts = {}
  local spent = M.cost(type(data.cost) == "table" and data.cost.total_cost_usd or nil)
  if spent then
    table.insert(parts, M.paint(p.peach, spent))
  end
  local ran = M.duration(type(data.cost) == "table" and data.cost.total_duration_ms or nil)
  if ran then
    table.insert(parts, M.paint(p.subtext0, "󰔛 " .. ran))
  end
  return table.concat(parts, " ")
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
  local rate_limits = data.rate_limits or {}
  local five_hour = remaining_of(rate_limits.five_hour)
  if five_hour then
    table.insert(parts, meter(bars.five_hour, five_hour, p.blue or p.sky, p))
  end
  local seven_day = remaining_of(rate_limits.seven_day)
  if seven_day then
    table.insert(parts, meter(bars.seven_day, seven_day, p.green, p))
  end
  local spent = session(data, p)
  if spent ~= "" then
    table.insert(parts, spent)
  end
  return table.concat(parts, SEPARATOR)
end

--- Renders the statusline rows Claude Code prints, one string per row.
---@param data table the JSON Claude Code sends on stdin
---@param ctx { lore: table, region: table, branch?: string } branch only outside nvim
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
