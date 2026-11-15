-- The heart in the statusline: it beats calm while the buffer is clean and races as errors pile
-- up, with the lub and dub of a real heartbeat. Pure logic only, times are milliseconds.
local ecg = require("core.ecg.actions")

local M = {}

M.GLOW_LEVELS = 8

-- beats per minute for each condition the ECG reads, and the glyph the heart wears
M.PACES = {
  fine = { bpm = 60, glyph = "󰋑" },
  caution = { bpm = 96, glyph = "󰋑" },
  danger = { bpm = 132, glyph = "󰋔" },
}

-- where in a beat the lub and the dub land, and how long each glows, as fractions of the beat
M.LUB = { at = 0.0, width = 0.14, peak = 1 }
M.DUB = { at = 0.22, width = 0.12, peak = 0.7 }

--- Reads how fast the heart should beat from the buffer's diagnostics, the same way the ECG does.
---@param errors integer
---@param warnings integer
---@return string condition: fine, caution or danger
function M.condition(errors, warnings)
  return ecg.condition(errors, warnings)
end

-- a soft bump that rises and falls inside its window and is zero outside it
local function bump(phase, pulse)
  local into = (phase - pulse.at) / pulse.width
  if into < 0 or into > 1 then
    return 0
  end
  return pulse.peak * math.sin(math.pi * into)
end

--- Returns how bright the heart is at a moment: two quick pulses at the start of every beat,
--- then rest until the next one.
---@param elapsed number milliseconds since the heart started
---@param bpm number beats per minute
---@return number from 0 to 1
function M.pulse(elapsed, bpm)
  local period = 60000 / bpm
  local phase = (elapsed % period) / period
  return math.max(bump(phase, M.LUB), bump(phase, M.DUB))
end

--- Returns which precomputed glow group the pulse sits on, so only the statusline repaints.
---@param elapsed number milliseconds since the heart started
---@param condition string from M.condition
---@return integer level from 1 (resting) to GLOW_LEVELS (the peak of the lub)
function M.glow_level(elapsed, condition)
  local pulse = M.pulse(elapsed, M.PACES[condition].bpm)
  return math.floor(pulse * (M.GLOW_LEVELS - 1) + 0.5) + 1
end

return M
