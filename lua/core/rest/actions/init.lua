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
    { text = "✦", group = "EldenRestTitle", gap = 0 },
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

-- where each line of text goes, centered as a block a little above the middle
---@param opts { style: string|nil, ribbons: integer|nil }|nil style "typewriter" writes the save prompt
function M.layout(width, height, region_title, opts)
  opts = opts or {}
  local words = require("core.franchise").current().words
  local lines = opts.style == "typewriter" and typewriter_lines(words, region_title, opts.ribbons)
    or grace_lines(words, region_title)
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

return M
