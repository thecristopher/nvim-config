-- Code snapshots: turns styled lines into an SVG card framed in the region's colors.
-- Pure string building only, the editor side hands in lines already split into styled runs.
local M = {}

M.FONT = "JetBrainsMono Nerd Font, JetBrains Mono, Menlo, monospace"
M.FONT_SIZE = 15
M.CHAR_WIDTH = 9.03 -- JetBrains Mono advances 0.602 of its size per cell
M.LINE = 22
M.PADDING = 56
M.INNER = 28
M.TITLE_BAR = 44
M.MAX_LINES = 200

--- Escapes text so it can sit inside SVG markup.
---@param text string
---@return string
function M.escape(text)
  return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

--- Joins neighbor cells that look the same into one run, so the SVG stays small.
---@param cells { text: string, fg: string|nil, bold: boolean|nil, italic: boolean|nil }[]
---@return { text: string, fg: string|nil, bold: boolean|nil, italic: boolean|nil }[]
function M.merge(cells)
  local runs = {}
  for _, cell in ipairs(cells or {}) do
    local last = runs[#runs]
    if last and last.fg == cell.fg and last.bold == cell.bold and last.italic == cell.italic then
      last.text = last.text .. cell.text
    else
      table.insert(runs, { text = cell.text, fg = cell.fg, bold = cell.bold, italic = cell.italic })
    end
  end
  return runs
end

--- Cuts the shared indent off every line, so a snippet from deep inside a function sits flush left.
---@param lines string[]
---@return integer columns that every non blank line starts with
function M.common_indent(lines)
  local indent
  for _, line in ipairs(lines or {}) do
    if line:match("%S") then
      local width = #line:match("^ *")
      indent = indent and math.min(indent, width) or width
    end
  end
  return indent or 0
end

local function tspan(run, fallback)
  local attrs = { ('fill="%s"'):format(run.fg or fallback) }
  if run.bold then
    table.insert(attrs, 'font-weight="bold"')
  end
  if run.italic then
    table.insert(attrs, 'font-style="italic"')
  end
  return ("<tspan %s>%s</tspan>"):format(table.concat(attrs, " "), M.escape(run.text))
end

--- Measures the card for some lines.
---@param rows { [integer]: table }[] styled runs per line
---@param gutter integer columns for line numbers, 0 for none
---@return { width: number, height: number, card_width: number, card_height: number }
function M.size(rows, gutter)
  local longest = 0
  for _, runs in ipairs(rows) do
    local width = 0
    for _, run in ipairs(runs) do
      width = width + vim.api.nvim_strwidth(run.text)
    end
    longest = math.max(longest, width)
  end
  local card_width = math.max(520, (longest + gutter) * M.CHAR_WIDTH + M.INNER * 2)
  local card_height = M.TITLE_BAR + #rows * M.LINE + M.INNER * 1.5
  return {
    card_width = card_width,
    card_height = card_height,
    width = card_width + M.PADDING * 2,
    height = card_height + M.PADDING * 2,
  }
end

local function frame(size, colors, title, region)
  local x, y = M.PADDING, M.PADDING
  return table.concat({
    ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'):format(
      size.width,
      size.height,
      size.width,
      size.height
    ),
    "<defs>",
    ('<linearGradient id="sky" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'):format(
      colors.glow,
      colors.crust
    ),
    '<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#000000" flood-opacity="0.55"/></filter>',
    "</defs>",
    '<rect width="100%" height="100%" fill="url(#sky)"/>',
    ('<rect x="%d" y="%d" width="%d" height="%d" rx="14" fill="%s" stroke="%s" stroke-width="1.5" filter="url(#shadow)"/>'):format(
      x,
      y,
      size.card_width,
      size.card_height,
      colors.base,
      colors.border
    ),
    ('<text x="%d" y="%d" fill="%s" font-family="%s" font-size="13" text-anchor="middle" letter-spacing="3">◈  %s  ◈</text>'):format(
      x + size.card_width / 2,
      y + 28,
      colors.accent,
      M.FONT,
      M.escape(title)
    ),
    ('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>'):format(
      x + 24,
      y + M.TITLE_BAR - 4,
      x + size.card_width - 24,
      y + M.TITLE_BAR - 4,
      colors.border
    ),
    ('<text x="%d" y="%d" fill="%s" font-family="%s" font-size="12" text-anchor="end" letter-spacing="2">%s</text>'):format(
      size.width - M.PADDING,
      size.height - M.PADDING / 2 + 4,
      colors.muted,
      M.FONT,
      M.escape(region)
    ),
  }, "\n")
end

--- Builds the whole SVG card.
---@param rows table[] styled runs per line
---@param opts { title: string, region: string, first_line: integer|nil, colors: { base: string, crust: string, glow: string, border: string, accent: string, text: string, muted: string } }
---@return string svg
function M.svg(rows, opts)
  local gutter = opts.first_line and #tostring(opts.first_line + #rows - 1) + 2 or 0
  local size = M.size(rows, gutter)
  local colors = opts.colors
  local parts = { frame(size, colors, opts.title, opts.region) }
  local left = M.PADDING + M.INNER
  for index, runs in ipairs(rows) do
    local baseline = M.PADDING + M.TITLE_BAR + M.INNER / 2 + index * M.LINE - 6
    local spans = {}
    if opts.first_line then
      table.insert(
        spans,
        tspan(
          { text = ("%" .. (gutter - 2) .. "d  "):format(opts.first_line + index - 1) },
          colors.muted
        )
      )
    end
    for _, run in ipairs(runs) do
      table.insert(spans, tspan(run, colors.text))
    end
    table.insert(
      parts,
      ('<text x="%d" y="%d" font-family="%s" font-size="%d" xml:space="preserve">%s</text>'):format(
        left,
        baseline,
        M.FONT,
        M.FONT_SIZE,
        table.concat(spans)
      )
    )
  end
  table.insert(parts, "</svg>")
  return table.concat(parts, "\n")
end

return M
