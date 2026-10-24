-- Runes: the statusline's tally of work done. Saving earns them, felling enemies earns more,
-- and dying drops them as a bloodstain you can only reclaim by winning the next fight.
local ease = require("core.motion.actions")

local M = {}

M.RUNES_PER_EDIT = 25

-- banner kinds that pay out, and the one that costs you everything
M.BOUNTIES = { felled = 800, great = 5000, cleansed = 300, grace = 150 }

function M.format(amount)
  local digits = tostring(math.floor(amount))
  local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (grouped:gsub("^,", ""))
end

function M.gain_for_edits(edits)
  return math.max(0, edits or 0) * M.RUNES_PER_EDIT
end

-- the counter spins up like the game's instead of jumping straight to the total
function M.roll(from, to, t)
  return math.floor(from + (to - from) * ease.ease("out_cubic", t) + 0.5)
end

function M.award(state, amount)
  return { held = state.held + amount, bloodstain = state.bloodstain }
end

-- an older bloodstain is gone for good once you die again, just like the Lands Between
function M.die(state)
  return { held = 0, bloodstain = state.held }
end

function M.recover(state)
  return { held = state.held + state.bloodstain, bloodstain = 0 }
end

-- what a banner does to your runes: death drops them, victory reclaims the stain and pays out
function M.after_banner(state, kind)
  if kind == "died" then return M.die(state) end
  local bounty = M.BOUNTIES[kind]
  if not bounty then return state end
  return M.award(M.recover(state), bounty)
end

function M.decode(text)
  local held, bloodstain = (text or ""):match("^(%d+)%s+(%d+)$")
  return { held = tonumber(held) or 0, bloodstain = tonumber(bloodstain) or 0 }
end

function M.encode(state)
  return ("%d %d"):format(state.held, state.bloodstain)
end

M.GLOW_PERIOD = 3600

-- a slow breath between 0 and 1, the grace glyph pulses with it
function M.breath(elapsed)
  return (1 - math.cos(2 * math.pi * (elapsed % M.GLOW_PERIOD) / M.GLOW_PERIOD)) / 2
end

M.GLOW_LEVELS = 8

--- Returns which precomputed glow group the breath sits on, so only the statusline repaints.
---@param elapsed number milliseconds since the breathing began
---@return integer level from 1 (dimmest) to GLOW_LEVELS (brightest)
function M.glow_level(elapsed)
  return math.floor(M.breath(elapsed) * (M.GLOW_LEVELS - 1) + 0.5) + 1
end

return M
