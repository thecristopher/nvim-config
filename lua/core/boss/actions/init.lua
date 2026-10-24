-- Boss fights against your own errors: who guards each region, when a fight begins, and how the
-- health bar looks at any moment, gold chip of fresh damage included. Times are milliseconds.
local ease = require("core.motion.actions")

local M = {}

M.THRESHOLD       = 3
M.ENGAGE_AFTER_MS = 8000
M.ENTRANCE_MS     = 700
M.CHIP_HOLD_MS    = 500
M.CHIP_MS         = 600
M.DAMAGE_LINGER_MS = 900
M.HEIGHT          = 2
M.MAX_WIDTH       = 80

M.BOSSES = {
  leyndell     = "Morgott, the Omen King",
  haligtree    = "Malenia, Blade of Miquella",
  raya_lucaria = "Rennala, Queen of the Full Moon",
  caelid       = "Starscourge Radahn",
  mohgwyn      = "Mohg, Lord of Blood",
  ordina       = "Commander Niall",
  limgrave     = "Margit, the Fell Omen",
  stormveil    = "Godrick the Grafted",
  volcano_manor = "Rykard, Lord of Blasphemy",
  nokron       = "Mimic Tear",
  farum_azula  = "Maliketh, the Black Blade",
}

--- Returns the boss guarding a region, Morgott when the region has none.
---@param region string|nil region name
---@return string
function M.boss_for(region)
  return M.BOSSES[region] or M.BOSSES.leyndell
end

--- Decides whether errors have stuck around long enough to call it a fight.
---@param opts { errors: integer, since: number|nil, now: number, threshold: integer|nil }
---@return boolean
function M.should_engage(opts)
  if opts.errors < (opts.threshold or M.THRESHOLD) or not opts.since then return false end
  return opts.now - opts.since >= M.ENGAGE_AFTER_MS
end

--- Returns how much health the boss has left, as a fraction of the worst moment of the fight.
---@param errors integer errors right now
---@param peak integer most errors seen during the fight
---@return number from 0 to 1
function M.health(errors, peak)
  if not peak or peak <= 0 then return 0 end
  return math.max(0, math.min(1, errors / peak))
end

--- Returns the bar width for an editor this many columns wide.
---@param columns integer
---@return integer
function M.width(columns)
  return math.max(20, math.min(M.MAX_WIDTH, math.floor(columns * 0.55)))
end

local function cells(width, fraction)
  return math.floor(width * math.max(0, math.min(1, fraction)) + 0.5)
end

--- Splits the bar into health left, the gold chip of damage just taken, and what is already gone.
---@param width integer bar width in cells
---@param health number fraction still standing
---@param chip number fraction the gold chip still reaches
---@return { fill: integer, chip: integer, empty: integer }
function M.segments(width, health, chip)
  local filled = cells(width, health)
  local chipped = math.max(filled, cells(width, chip))
  return { fill = filled, chip = chipped - filled, empty = width - chipped }
end

--- Returns where the gold chip reaches: it holds for a beat, then drains down to the new health.
---@param from number health before the hit
---@param to number health after the hit
---@param since_hit number milliseconds since the hit
---@return number
function M.chip_at(from, to, since_hit)
  if to >= from then return to end
  local drained = ease.ease("in_out_sine", ease.progress(since_hit - M.CHIP_HOLD_MS, M.CHIP_MS))
  return from - (from - to) * drained
end

--- Returns what the bar shows at a moment: health filled, chip reach, and the damage number.
---@param fight { health: number, entered_at: number, hit_at: number|nil, chip_from: number|nil, damage: integer|nil }
---@param now number
---@return { fill: number, chip: number, damage: integer|nil }
function M.frame(fight, now)
  local entrance = ease.ease("out_cubic", ease.progress(now - fight.entered_at, M.ENTRANCE_MS))
  local fill = fight.health * entrance
  if not fight.hit_at then return { fill = fill, chip = fill } end

  local since_hit = now - fight.hit_at
  local chip = M.chip_at(fight.chip_from or fight.health, fight.health, since_hit)
  local showing = since_hit < M.CHIP_HOLD_MS + M.CHIP_MS + M.DAMAGE_LINGER_MS
  return { fill = fill, chip = math.max(fill, chip), damage = showing and fight.damage or nil }
end

--- Returns how long a hit keeps the bar moving, so the animation knows when to stop.
---@return integer
function M.hit_duration()
  return M.CHIP_HOLD_MS + M.CHIP_MS + M.DAMAGE_LINGER_MS
end

--- Builds the line above the bar: the boss name on the left, fresh damage on the right.
---@param name string
---@param damage integer|nil
---@param width integer
---@return string
function M.header(name, damage, width)
  local right = (damage and damage > 0) and tostring(damage) or ""
  local gap = math.max(1, width - vim.api.nvim_strwidth(name) - #right)
  return name .. (" "):rep(gap) .. right
end

--- Picks the editor row for the bar: just above the statusline, or the top while the cursor is down there.
---@param opts { lines: integer, cmdheight: integer, statusline: integer, cursor_row: integer, top: integer }
---@return integer zero based editor row
function M.placement(opts)
  local bottom = opts.lines - opts.cmdheight - opts.statusline - M.HEIGHT
  if opts.cursor_row >= bottom then return opts.top end
  return bottom
end

return M
