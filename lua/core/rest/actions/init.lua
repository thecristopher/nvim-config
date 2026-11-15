-- Resting at a Site of Grace: after a long idle the world dims, embers rise, and any key wakes you.
local banner = require("core.banner.actions")
local ease = require("core.motion.actions")

local M = {}

M.DEFAULT_AFTER_MS = 5 * 60 * 1000
M.FADE_MS = 1600
M.DEEPEST_ALPHA = 0.78

-- only drift off from normal mode, nobody wants to be ambushed mid sentence
function M.should_rest(opts)
  if opts.resting or not opts.enabled then
    return false
  end
  if opts.mode ~= "n" then
    return false
  end
  return opts.idle >= (opts.after or M.DEFAULT_AFTER_MS)
end

-- how dark the veil is, sinking in slowly so it feels like dusk and not a power cut
function M.veil_alpha(elapsed)
  return M.DEEPEST_ALPHA * ease.ease("in_out_sine", ease.progress(elapsed, M.FADE_MS))
end

-- the words come in after the dark has mostly settled
function M.text_alpha(elapsed)
  return ease.ease("out_cubic", ease.progress(elapsed - M.FADE_MS * 0.5, M.FADE_MS))
end

M.TYPE_MS = 85

--- Returns how much of a line the typewriter has written so far, and whether it is done.
---@param text string
---@param elapsed number milliseconds since the rest began
---@return string written, boolean done
function M.typed(text, elapsed)
  local length = vim.fn.strchars(text)
  local chars = math.max(0, math.min(length, math.floor((elapsed - M.FADE_MS * 0.5) / M.TYPE_MS)))
  return vim.fn.strcharpart(text, 0, chars), chars >= length
end

local function grace_lines(words, region_title)
  return {
    { text = "󰫢", group = "EldenRestTitle", gap = 0 },
    { text = banner.spaced(words.site), group = "EldenRestTitle", gap = 1 },
    { text = region_title, group = "EldenRestSub", gap = 1 },
    { text = words.rise, group = "EldenRestHint", gap = 3 },
  }
end

-- the safe room asks before it saves, and counts the ribbons you have used this run
local function typewriter_lines(words, region_title, ribbons)
  return {
    { text = "▣", group = "EldenRestTitle", gap = 0 },
    { text = banner.spaced(words.site), group = "EldenRestTitle", gap = 1 },
    { text = region_title, group = "EldenRestSub", gap = 1 },
    { text = words.typewriter, group = "EldenRestTitle", gap = 2, typed = true },
    { text = ("%s ×%d"):format(words.ink_ribbons, ribbons or 0), group = "EldenRestSub", gap = 1 },
    { text = words.rise, group = "EldenRestHint", gap = 3 },
  }
end

-- the stage lights go down to the afternoon sun, and the heart waits under it
local function golden_hour_lines(words, region_title)
  return {
    { text = "󰋑", group = "EldenRestTitle", gap = 0 },
    { text = banner.spaced(words.site), group = "EldenRestTitle", gap = 1 },
    { text = region_title, group = "EldenRestSub", gap = 1 },
    { text = words.rise, group = "EldenRestHint", gap = 3 },
  }
end

local function lines_for(style, words, region_title, ribbons)
  if style == "typewriter" then
    return typewriter_lines(words, region_title, ribbons)
  end
  if style == "golden_hour" then
    return golden_hour_lines(words, region_title)
  end
  return grace_lines(words, region_title)
end

-- where each line of text goes, centered as a block a little above the middle
---@param opts { style: string|nil, ribbons: integer|nil }|nil style "typewriter" writes the save
---prompt, "golden_hour" rests under the sun
function M.layout(width, height, region_title, opts)
  opts = opts or {}
  local words = require("core.franchise").current().words
  local lines = lines_for(opts.style, words, region_title, opts.ribbons)
  local row = math.floor(height * 0.4)
  local placed = {}
  for _, line in ipairs(lines) do
    row = row + line.gap
    local width_of = vim.fn.strdisplaywidth(line.text)
    table.insert(placed, {
      row = row,
      col = banner.center_col(width, width_of),
      text = line.text,
      group = line.group,
      typed = line.typed,
    })
    row = row + 1
  end
  return placed
end

-- the window of afternoon sun laid across the editor: where it starts and how wide it is as
-- fractions of the screen, how far each row leans, and the blinds that cut it into slats
M.SUN = { left = 0.18, width = 0.34, lean = 0.7, slat = 4, sway_ms = 24000, sway = 0.04 }

--- Returns the patches of sunlight on the screen at a moment: every row the blinds let through,
--- leaning like light from a low sun and swaying slowly as the afternoon goes by.
---@param width integer screen columns
---@param height integer screen rows
---@param elapsed number milliseconds since the rest began
---@return { row: integer, from: integer, to: integer }[] spans inside the screen with `to` exclusive
function M.sun_spans(width, height, elapsed)
  local sun = M.SUN
  local sway = math.sin(2 * math.pi * elapsed / sun.sway_ms) * sun.sway * width
  local span_width = math.floor(width * sun.width)
  local spans = {}
  for row = 0, height - 1 do
    -- the last row of every slat is the blind itself, so it stays in the shade
    if row % sun.slat ~= sun.slat - 1 then
      local from = math.floor(width * sun.left + row * sun.lean + sway)
      local to = math.min(width, from + span_width)
      from = math.max(0, from)
      if to > from then
        table.insert(spans, { row = row, from = from, to = to })
      end
    end
  end
  return spans
end

return M
