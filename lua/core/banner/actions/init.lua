-- The "ENEMY FELLED" banners: what each one says (from the franchise), how it breathes in and out,
-- and the soft band of shadow it sits on. Times are milliseconds since the banner appeared.
local ease = require("core.motion.actions")

local M = {}

M.HEIGHT = 7
M.TEXT_ROW = 2
M.RULE_ROW = 3
M.SUB_ROW = 4
M.BAND_LEVELS = 10

-- how a banner sits on the screen: a band of shadow (the default), the whole screen going dark
-- (blackout) or a film slate whose stick snaps shut over the words (clapper)
M.LOOKS = { "band", "blackout", "clapper" }

M.KINDS = {
  felled = {
    color = "yellow",
    duration = 3200,
    fade_in = 450,
    fade_out = 900,
    stagger = 40,
    letter_ms = 380,
    band = 0.92,
  },
  great = {
    color = "yellow",
    duration = 3800,
    fade_in = 500,
    fade_out = 1000,
    stagger = 35,
    letter_ms = 420,
    band = 0.95,
    rule = true,
  },
  -- death never hurries, the whole word seeps in at once
  died = {
    color = "red",
    duration = 4200,
    fade_in = 900,
    fade_out = 1100,
    stagger = 0,
    letter_ms = 1400,
    band = 0.97,
  },
  grace = {
    color = "yellow",
    duration = 3200,
    fade_in = 450,
    fade_out = 900,
    stagger = 30,
    letter_ms = 360,
    band = 0.88,
    rule = true,
  },
  cleansed = {
    color = "green",
    duration = 2600,
    fade_in = 350,
    fade_out = 800,
    stagger = 25,
    letter_ms = 300,
    band = 0.85,
  },
  -- walking into a new part of a project, quieter still so it never interrupts the work
  zone = {
    text = "",
    color = "subtext1",
    duration = 2200,
    fade_in = 450,
    fade_out = 800,
    stagger = 30,
    letter_ms = 380,
    band = 0.42,
    rule = true,
  },
  -- area names hang lightly over the world instead of blotting it out
  region = {
    text = "",
    color = "text",
    duration = 2800,
    fade_in = 600,
    fade_out = 900,
    stagger = 45,
    letter_ms = 500,
    band = 0.55,
    rule = true,
  },
}

--- Returns a banner kind with the franchise's words and style on it, nil for an unknown kind.
---@param name string kind name from M.KINDS
---@param overrides table|nil fields that win over the kind's own
---@return table|nil
function M.kind(name, overrides)
  local base = M.KINDS[name]
  if not base then
    return nil
  end
  local lore = require("core.franchise").current()
  local style = (lore.banner_styles or {})[name] or {}
  local text = lore.banners[name] or base.text or ""
  return vim.tbl_extend("force", base, style, { text = text }, overrides or {})
end

--- Tells whether a banner should crumble the code into rain behind it.
---@param name string kind name
---@param buftype string of the window the rain would cover
---@param enabled boolean|nil vim.g.eldentree_rain, only false turns it off
---@return boolean
function M.rains(name, buftype, enabled)
  return name == "died" and buftype == "" and enabled ~= false
end

-- dripping banners ------------------------------------------------------------------------

M.DRIP_DEPTH = 3
M.DRIP_MS = 420

--- Picks which letters bleed and how far, the same every time so the banner never flickers.
---@param letter_cols integer[] zero based columns of the banner's letters
---@return { col: integer, length: integer }[]
function M.drips(letter_cols)
  local drips = {}
  for index, col in ipairs(letter_cols) do
    if index % 2 == 1 then
      table.insert(drips, { col = col, length = 1 + (index * 7) % M.DRIP_DEPTH })
    end
  end
  return drips
end

--- Returns how visible a drip is at a depth below its letter: deeper drops arrive later.
---@param depth integer 1 right under the letter, up to DRIP_DEPTH
---@param elapsed number milliseconds since the banner appeared
---@param kind table
---@return number from 0 to 1
function M.drip_alpha(depth, elapsed, kind)
  local delay = kind.fade_in + kind.letter_ms * 0.6 + (depth - 1) * M.DRIP_MS
  local running = ease.ease("out_cubic", ease.progress(elapsed - delay, M.DRIP_MS))
  local falling = 1 - ease.progress(elapsed - (kind.duration - kind.fade_out), kind.fade_out)
  return running * ease.ease("in_out_sine", falling)
end

--- Where each part of a banner sits: the float's height and the rows of its text, rule, subtitle
--- and slate. Drips get their rows between the text and the subtitle, so they never cover it.
---@param kind table from M.kind
---@param screen_height integer editor rows, the blackout covers them all
---@return { height: integer, text: integer, rule: integer, sub: integer, slate?: integer }
function M.geometry(kind, screen_height)
  local drip_rows = kind.drip and M.DRIP_DEPTH or 0
  if kind.look == "blackout" then
    local height = math.max(M.HEIGHT, screen_height)
    local text = math.floor(height * 0.42)
    return { height = height, text = text, rule = text + 1, sub = text + drip_rows + 2 }
  end
  if kind.look == "clapper" then
    -- the open stick, the hinge, the shut stick and the slate's stripes sit over the words
    local text = M.CLAPPER.rows + 1
    return { height = text + 5, text = text, rule = text + 1, sub = text + 2, slate = 0 }
  end
  local sub = M.SUB_ROW + drip_rows
  return { height = math.max(M.HEIGHT, sub + 3), text = M.TEXT_ROW, rule = M.RULE_ROW, sub = sub }
end

--- How dark a cell of the banner's ground is before the fade: the band melts at its edges, a
--- blackout is the same everywhere.
---@param kind table
---@param row integer zero based
---@param col integer zero based
---@param width integer
---@param height integer
---@return number from 0 to 1
function M.ground_alpha(kind, row, col, width, height)
  if kind.look == "blackout" then
    return 1
  end
  return M.band_alpha(row, col, width, height)
end

-- the film slate --------------------------------------------------------------------------------

-- the stick is raised for `open_ms` after the words arrive, then snaps shut in one frame
M.CLAPPER = { rows = 4, stripe = "▚", open_ms = 650, extra = 8 }

--- How visible the raised stick and the shut stick are at a moment: the raised one shows while
--- the words arrive, the shut one takes over the moment it claps.
---@param elapsed number milliseconds since the banner appeared
---@param kind table
---@return number open, number shut both from 0 to 1, already faded with the banner
function M.clapper_alpha(elapsed, kind)
  local snap = kind.fade_in + M.CLAPPER.open_ms
  local fade = M.envelope(elapsed, kind)
  if elapsed < snap then
    return fade, 0
  end
  return 0, fade
end

--- The rows of the slate drawn over a banner's words, as { row, col, text, part } pieces with
--- part "open", "hinge", "shut" or "slate".
---@param text_width integer display width of the banner's words
---@param width integer float width
---@return { row: integer, col: integer, text: string, part: string }[]
function M.slate(text_width, width)
  local span = math.min(width - 2, text_width + M.CLAPPER.extra)
  local col = M.center_col(width, span)
  local stripes = M.CLAPPER.stripe:rep(span)
  return {
    -- raised: tilted up and to the right of its hinge
    { row = 0, col = col + 2, text = M.CLAPPER.stripe:rep(math.max(1, span - 2)), part = "open" },
    { row = 1, col = col, text = "╱", part = "hinge" },
    { row = 2, col = col, text = stripes, part = "shut" },
    { row = 3, col = col, text = ("▀"):rep(span), part = "slate" },
  }
end

--- The subtitle a :Banner preview shows under a kind: death and a cut take no applause.
---@param name string kind name
---@param salute string the franchise's salute
---@return string|nil
function M.preview_subtitle(name, salute)
  if name == "died" then
    return nil
  end
  return salute
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
  local rising = ease.progress(elapsed, kind.fade_in)
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
  local center = (height - 1) / 2
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
  if length <= 1 then
    return 1
  end
  local from_middle = math.abs((index - 1) / (length - 1) - 0.5) * 2
  return 1 - from_middle ^ 2
end

M.CLEANSE_AFTER_MS = 20 * 1000
M.CLEANSE_COOLDOWN_MS = 2 * 60 * 1000

-- only a long fight earns the banner, errors that flicker while typing do not count
function M.should_cleanse(opts)
  if opts.errors > 0 or not opts.errors_since then
    return false
  end
  if opts.now - opts.errors_since < M.CLEANSE_AFTER_MS then
    return false
  end
  if opts.last_shown and opts.now - opts.last_shown < M.CLEANSE_COOLDOWN_MS then
    return false
  end
  return true
end

return M
