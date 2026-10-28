-- Pure pieces of the progress bar: the bar itself, the elapsed time and the notification text.
local M = {}

M.WIDTH = 24
M.FRAME_MS = 120
-- the lit stretch that sweeps a bar while the work has no known end
M.SWEEP = 6

local FALLBACK_STYLE = { done = "━", head = "●", left = "─" }

---The bar style of a skin, the music panel's bar so every bar in the config looks alike.
---@param skin table|nil franchise skin
---@return { done: string, head: string, left: string }
function M.style(skin)
  local bar = skin and skin.music and skin.music.bar
  return bar or FALLBACK_STYLE
end

local function determinate(fraction, style, width)
  local filled = math.floor(math.max(0, math.min(1, fraction)) * width + 0.5)
  if filled >= width then
    return style.done:rep(width)
  end
  return style.done:rep(filled) .. style.head .. style.left:rep(width - filled - 1)
end

-- the stretch bounces from one end to the other, so the bar always moves
local function sweeping(elapsed_ms, style, width)
  local travel = width - M.SWEEP
  local step = math.floor(elapsed_ms / M.FRAME_MS) % (travel * 2)
  local start = step <= travel and step or (travel * 2 - step)
  return style.left:rep(start)
    .. style.done:rep(M.SWEEP - 1)
    .. style.head
    .. style.left:rep(width - start - M.SWEEP)
end

---Draws the bar: filled up to the fraction when it is known, sweeping when it is not.
---@param fraction number|nil 0 to 1
---@param elapsed_ms integer
---@param style { done: string, head: string, left: string }
---@param width? integer
---@return string
function M.bar(fraction, elapsed_ms, style, width)
  width = width or M.WIDTH
  if fraction then
    return determinate(fraction, style, width)
  end
  return sweeping(elapsed_ms, style, width)
end

---Elapsed time as people read it: 7s, 1m 05s.
---@param ms integer
---@return string
function M.elapsed(ms)
  local seconds = math.floor(ms / 1000)
  if seconds < 60 then
    return seconds .. "s"
  end
  return ("%dm %02ds"):format(math.floor(seconds / 60), seconds % 60)
end

---How wide the text of a notification may run, so it fits the notifier and never jumps around.
---@param columns integer the editor width
---@return integer
function M.text_width(columns)
  -- the notifier takes at most 40% of the editor and keeps a little padding inside
  return math.max(36, math.min(72, math.floor(columns * 0.4) - 4))
end

local function hard_break(word, width)
  local pieces = {}
  while vim.fn.strdisplaywidth(word) > width do
    table.insert(pieces, vim.fn.strcharpart(word, 0, width))
    word = vim.fn.strcharpart(word, width)
  end
  table.insert(pieces, word)
  return pieces
end

local function wrap_line(line, width, out)
  local current = ""
  for word in line:gmatch("%S+") do
    for _, piece in ipairs(hard_break(word, width)) do
      local candidate = current == "" and piece or (current .. " " .. piece)
      if current ~= "" and vim.fn.strdisplaywidth(candidate) > width then
        table.insert(out, current)
        candidate = piece
      end
      current = candidate
    end
  end
  table.insert(out, current)
end

---Wraps a message to a width, keeping its own line breaks and splitting words too long for a line.
---@param text string
---@param width integer
---@return string
function M.wrap(text, width)
  local out = {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    wrap_line(line, width, out)
  end
  return table.concat(out, "\n")
end

---The notification text: what is happening, then the bar with the time it has taken.
---@param message string
---@param fraction number|nil
---@param elapsed_ms integer
---@param style { done: string, head: string, left: string }
---@param width? integer where the message wraps, nothing wraps without it
---@return string
function M.text(message, fraction, elapsed_ms, style, width)
  local tail = fraction
      and ("%d%%  %s"):format(math.floor(fraction * 100 + 0.5), M.elapsed(elapsed_ms))
    or M.elapsed(elapsed_ms)
  local shown = width and M.wrap(message, width) or message
  return shown .. "\n" .. M.bar(fraction, elapsed_ms, style) .. "  " .. tail
end

return M
