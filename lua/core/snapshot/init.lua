-- Snapshots of code for sharing: the selection (or the whole buffer) painted with the exact colors on
-- screen, framed in the region's palette, saved as a PNG and copied to the clipboard on macOS.
local actions = require("core.snapshot.actions")

local M = {}

local function to_hex(color)
  return color and ("#%06X"):format(color) or nil
end

-- the color a highlight group really paints with, links followed
local function style_of(group)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return { fg = to_hex(hl.fg), bold = hl.bold, italic = hl.italic }
end

-- semantic tokens outrank treesitter, which outranks old regex syntax, the same order nvim draws them
local function cell_style(buf, row, col)
  local info = vim.inspect_pos(
    buf,
    row,
    col,
    { extmarks = false, semantic_tokens = true, treesitter = true, syntax = true }
  )
  for _, source in ipairs({ info.semantic_tokens, info.treesitter, info.syntax }) do
    for index = #source, 1, -1 do
      -- semantic tokens keep their group under opts, treesitter and syntax keep it at the top
      local item = source[index].opts or source[index]
      local group = item.hl_group
      local style = group and style_of(group)
      if style and style.fg then
        return style
      end
    end
  end
  return {}
end

local function styled_line(buf, row, line, indent)
  local cells = {}
  local starts = vim.str_utf_pos(line)
  for index, start in ipairs(starts) do
    if start > indent then
      local stop = (starts[index + 1] or #line + 1) - 1
      local text = line:sub(start, stop)
      local style = text:match("%S") and cell_style(buf, row, start - 1) or {}
      table.insert(cells, {
        text = text == "\t" and "  " or text,
        fg = style.fg,
        bold = style.bold,
        italic = style.italic,
      })
    end
  end
  return actions.merge(cells)
end

local function colors()
  local p = require("core.themes").palette()
  local blend = require("core.themes.actions").blend
  return {
    base = p.base,
    crust = p.crust,
    glow = blend(p.yellow, p.crust, 0.22),
    border = blend(p.yellow, p.base, 0.45),
    accent = p.yellow,
    text = p.text,
    muted = p.overlay1,
  }
end

-- half the files in a project are called init or index, so the title carries the path from the repo root
local function display_name(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local root = require("core.repos").root(vim.fs.dirname(file))
  if root and file:sub(1, #root + 1) == root .. "/" then
    return file:sub(#root + 2)
  end
  return vim.fn.fnamemodify(file, ":t")
end

local function output_path(buf)
  local dir = vim.fn.expand("~/Pictures/Eldentree")
  vim.fn.mkdir(dir, "p")
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t"):gsub("[^%w%._-]", "_")
  return ("%s/%s-%s.png"):format(dir, name ~= "" and name or "snapshot", os.date("%Y%m%d-%H%M%S"))
end

local function copy_to_clipboard(png)
  if vim.fn.has("mac") == 0 then
    return false
  end
  local script = ('set the clipboard to (read (POSIX file "%s") as «class PNGf»)'):format(png)
  return vim.system({ "osascript", "-e", script }):wait().code == 0
end

local function render(svg, png, clipboard)
  local svg_path = vim.fn.tempname() .. ".svg"
  vim.fn.writefile(vim.split(svg, "\n"), svg_path)
  -- twice the size keeps the text crisp on retina screens and in chat previews
  vim.system(
    { "rsvg-convert", "--zoom", "2", "-o", png, svg_path },
    {},
    vim.schedule_wrap(function(result)
      vim.fn.delete(svg_path)
      if result.code ~= 0 then
        return vim.notify(
          "rsvg-convert failed: " .. (result.stderr or ""),
          vim.log.levels.ERROR,
          { title = "Snapshot" }
        )
      end
      local copied = clipboard and copy_to_clipboard(png) and ", copied to the clipboard" or ""
      vim.notify(
        ("Saved %s%s"):format(vim.fn.fnamemodify(png, ":~"), copied),
        vim.log.levels.INFO,
        { title = "Snapshot" }
      )
    end)
  )
end

--- Captures lines first to last (1 based) of the current buffer as a framed PNG.
---@param first integer
---@param last integer
---@param opts { path: string|nil, clipboard: boolean|nil }|nil path defaults to ~/Pictures/Eldentree, clipboard to true
---@return string|nil png path
function M.capture(first, last, opts)
  opts = opts or {}
  if vim.fn.executable("rsvg-convert") == 0 then
    return vim.notify(
      "Snapshots need rsvg-convert (brew install librsvg)",
      vim.log.levels.WARN,
      { title = "Snapshot" }
    )
  end
  local buf = vim.api.nvim_get_current_buf()
  last = math.min(last, first + actions.MAX_LINES - 1)
  local lines = vim.api.nvim_buf_get_lines(buf, first - 1, last, false)
  local indent = actions.common_indent(lines)
  local rows = {}
  for index, line in ipairs(lines) do
    rows[index] = styled_line(buf, first + index - 2, line, indent)
  end

  local region = require("core.themes").current()
  local svg = actions.svg(rows, {
    title = display_name(buf),
    region = ("ELDENTREE  ·  %s"):format(region.title:upper()),
    first_line = first,
    colors = colors(),
  })
  local png = opts.path or output_path(buf)
  render(svg, png, opts.clipboard ~= false)
  return png
end

function M.setup()
  vim.api.nvim_create_user_command("Snapshot", function(cmd)
    M.capture(cmd.line1, cmd.line2)
  end, { range = "%", desc = "Save the selection or buffer as a framed PNG" })
end

return M
