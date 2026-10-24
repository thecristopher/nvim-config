-- The "ENEMY FELLED" banners: what each one says, how it breathes in and out,
-- and the soft band of shadow it sits on. Times are milliseconds since the banner appeared.
local ease = require("core.motion.actions")

local M = {}

M.HEIGHT     = 7
M.TEXT_ROW   = 2
M.RULE_ROW   = 3
M.SUB_ROW    = 4
M.BAND_LEVELS = 10

M.KINDS = {
  felled = {
    text = "ENEMY FELLED", color = "yellow",
    duration = 3200, fade_in = 450, fade_out = 900, stagger = 40, letter_ms = 380, band = 0.92,
  },
  great = {
    text = "GREAT ENEMY FELLED", color = "yellow",
    duration = 3800, fade_in = 500, fade_out = 1000, stagger = 35, letter_ms = 420, band = 0.95, rule = true,
  },
  -- death never hurries, the whole word seeps in at once
  died = {
    text = "YOU DIED", color = "red",
    duration = 4200, fade_in = 900, fade_out = 1100, stagger = 0, letter_ms = 1400, band = 0.97,
  },
  grace = {
    text = "LOST GRACE DISCOVERED", color = "yellow",
    duration = 3200, fade_in = 450, fade_out = 900, stagger = 30, letter_ms = 360, band = 0.88, rule = true,
  },
  cleansed = {
    text = "SCARLET ROT CLEANSED", color = "green",
    duration = 2600, fade_in = 350, fade_out = 800, stagger = 25, letter_ms = 300, band = 0.85,
  },
  -- walking into a new part of a project, quieter still so it never interrupts the work
  zone = {
    text = "", color = "subtext1",
    duration = 2200, fade_in = 450, fade_out = 800, stagger = 30, letter_ms = 380, band = 0.42, rule = true,
  },
  -- area names hang lightly over the world instead of blotting it out
  region = {
    text = "", color = "text",
    duration = 2800, fade_in = 600, fade_out = 900, stagger = 45, letter_ms = 500, band = 0.55, rule = true,
  },
}

function M.kind(name, overrides)
  local base = M.KINDS[name]
  if not base then return nil end
  return vim.tbl_extend("force", base, overrides or {})
end

-- "ENEMY FELLED" becomes "E N E M Y   F E L L E D", the way the game letterspaces it
function M.spaced(text)
  local words = {}
  for word in text:upper():gmatch("%S+") do
    table.insert(words, (word:gsub(".", "%0 ")):sub(1, -2))
  end
  return table.concat(words, "   ")
end

-- 0 to 1 and back, how visible the whole banner is at this moment
function M.envelope(elapsed, kind)
  local rising  = ease.progress(elapsed, kind.fade_in)
  local falling = 1 - ease.progress(elapsed - (kind.duration - kind.fade_out), kind.fade_out)
  return ease.ease("in_out_sine", math.min(rising, falling))
end

-- each letter wakes a little after its neighbor, then everything leaves together
function M.letter_alpha(index, elapsed, kind)
  local delay = (index - 1) * kind.stagger
  local woken = ease.ease("out_cubic", ease.progress(elapsed - delay, kind.letter_ms))
  local falling = 1 - ease.progress(elapsed - (kind.duration - kind.fade_out), kind.fade_out)
  return woken * ease.ease("in_out_sine", falling)
end

local function smoothstep(x)
  x = math.max(0, math.min(1, x))
  return x * x * (3 - 2 * x)
end

-- strongest across the middle, melting away toward the top, bottom and both edges
function M.band_alpha(row, col, width, height)
  local center   = (height - 1) / 2
  local vertical = 1 - (math.abs(row - center) / (center + 1)) ^ 2
  local fade_cols = math.max(1, math.floor(width * 0.22))
  local from_edge = math.min(col, width - 1 - col)
  return vertical * smoothstep(from_edge / fade_cols)
end

function M.quantize(alpha, levels)
  return math.floor(math.max(0, math.min(1, alpha)) * levels + 0.5)
end

-- hl blend runs backwards from alpha: 100 is invisible, 0 is solid
function M.blend_for(alpha)
  return math.floor(100 - math.max(0, math.min(1, alpha)) * 100 + 0.5)
end

function M.center_col(width, text_width)
  return math.max(0, math.floor((width - text_width) / 2))
end

-- a thin rule that glows at the middle and fades to nothing at its tips
function M.rule_alpha(index, length)
  if length <= 1 then return 1 end
  local from_middle = math.abs((index - 1) / (length - 1) - 0.5) * 2
  return 1 - from_middle ^ 2
end

M.CLEANSE_AFTER_MS = 20 * 1000
M.CLEANSE_COOLDOWN_MS = 2 * 60 * 1000

-- only a long fight earns the banner, errors that flicker while typing do not count
function M.should_cleanse(opts)
  if opts.errors > 0 or not opts.errors_since then return false end
  if opts.now - opts.errors_since < M.CLEANSE_AFTER_MS then return false end
  if opts.last_shown and opts.now - opts.last_shown < M.CLEANSE_COOLDOWN_MS then return false end
  return true
end

return M
