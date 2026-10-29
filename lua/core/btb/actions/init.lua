-- Pure pieces of the back-to-basics bridge: the coach of the franchise, its sounds, the fanfare
-- of a solve and how a lesson reads as a HUD item.
local M = {}

-- the coach reuses sounds the franchise already has, first match wins, a moment with no match
-- stays quiet. Opening the stage rings the spirit calling bell where there is one: the coach is summoned
M.SOUNDS = {
  coach_open = { "summon", "hud_open" },
  ready = { "hud_select" },
  hint = { "hud_select" },
  failed = { "hud_back" },
  failed_again = { "hud_back" },
  skip = { "hud_close" },
}

-- what the statusline shows while the next exercise gets ready in the background
local AHEAD_ICONS = { forge = "󰈸", brief = "󰭹" }

local STATE_ICONS = { mastered = "★", due = "↻", solved = "✓", started = "~", new = "·" }

---The persona that coaches in a franchise, nil when the lore names none.
---@param lore table franchise lore
---@return string|nil
function M.persona_of(lore)
  local persona = lore.coach and lore.coach.persona
  if persona == nil or persona == "" then
    return nil
  end
  return persona
end

---The franchise sounds that may play for a coach event, in order of preference.
---@param event string "coach_open" or a moment like "failed"
---@return string[]|nil
function M.sound_for(event)
  return M.SOUNDS[event]
end

-- what the banner says under its big word: the exercise beaten and what it paid
local function subtitle(result)
  local xp = (result.xp or 0) > 0 and ("+%d XP"):format(result.xp) or nil
  if result.level_up then
    return ("level %d cleared"):format(result.level_up) .. (xp and ("  ·  " .. xp) or "")
  end
  local parts = {}
  table.insert(parts, result.title)
  table.insert(parts, xp)
  return #parts > 0 and table.concat(parts, "  ·  ") or nil
end

---The banner, its subtitle and the runes a solve is worth. A redo or a failure earns nothing.
---@param result table the User BtbResult payload
---@return { banner: string|nil, subtitle: string|nil, runes: integer }
function M.celebration(result)
  if not result.ok or result.redo then
    return { banner = nil, subtitle = nil, runes = 0 }
  end
  local banner = nil
  if result.level_up then
    banner = "great"
  elseif result.outcome == "clean" then
    banner = "felled"
  end
  return { banner = banner, subtitle = banner and subtitle(result) or nil, runes = result.xp or 0 }
end

---Where a persona's portrait lives in the config.
---@param config_dir string
---@param persona { portrait?: string }
---@return string|nil
function M.portrait_file(config_dir, persona)
  if not persona or not persona.portrait then
    return nil
  end
  return config_dir .. "/images/portraits/" .. persona.portrait
end

-- the portraits are 276x336 and a terminal cell is about twice as tall as it is wide
M.PORTRAIT_COLUMNS_PER_ROW = 1.64

---Where the portrait sits inside the stage's portrait window: as big as fits without stretching,
---centered, so it reads the same on a laptop split or a wide monitor.
---@param width integer columns of the window
---@param height integer rows of the window
---@return { row: integer, col: integer, width: integer, height: integer }
function M.portrait_anchor(width, height)
  local fit_width = math.min(width, math.floor(height * M.PORTRAIT_COLUMNS_PER_ROW + 0.5))
  local fit_height = math.min(height, math.floor(fit_width / M.PORTRAIT_COLUMNS_PER_ROW + 0.5))
  return {
    row = math.floor((height - fit_height) / 2),
    col = math.floor((width - fit_width) / 2),
    width = math.max(1, fit_width),
    height = math.max(1, fit_height),
  }
end

---How a lesson reads in the HUD: icon by state, title, level and concepts.
---@param entry table one of btb lessons --json
---@return { icon: string, name: string, count: integer|nil, desc: string }
function M.hud_fields(entry)
  return {
    icon = STATE_ICONS[entry.state] or "·",
    name = entry.title,
    count = entry.level ~= 0 and entry.level or nil,
    desc = table.concat(entry.concepts or {}, ", "),
  }
end

---The lessons worth showing in the HUD: started or solved ones first, newest solves on top.
---@param entries table[] btb lessons --json
---@param limit integer
---@return table[]
function M.hud_lessons(entries, limit)
  local fought = vim.tbl_filter(function(entry)
    return entry.state ~= "new" and entry.lesson ~= nil
  end, entries)
  table.sort(fought, function(a, b)
    return (a.solvedAt or "") > (b.solvedAt or "")
  end)
  return vim.list_slice(fought, 1, limit)
end

---The statusline piece for the work btb does ahead, empty once it is done or failed.
---@param ahead table|nil the data of the last User BtbAhead
---@return string
function M.ahead_text(ahead)
  local icon = ahead and AHEAD_ICONS[ahead.step]
  if not icon then
    return ""
  end
  return ahead.label and (icon .. " " .. ahead.label) or icon
end

return M
