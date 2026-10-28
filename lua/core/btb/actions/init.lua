-- Pure pieces of the back-to-basics bridge: the coach of the franchise, its sounds, the fanfare
-- of a solve and how a lesson reads as a HUD item.
local M = {}

-- the coach reuses sounds the franchise already has, a moment with no match stays quiet
M.SOUNDS = {
  coach_open = "hud_open",
  ready = "hud_select",
  hint = "hud_select",
  failed = "hud_back",
  failed_again = "hud_back",
  skip = "hud_close",
}

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

---The franchise sound that plays for a coach event.
---@param event string "coach_open" or a moment like "failed"
---@return string|nil
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

return M
