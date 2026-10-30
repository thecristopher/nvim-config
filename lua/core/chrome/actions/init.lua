-- Pure pieces of the editor's chrome: mode names, notification titles, the gutter's fading
-- numbers, the picker frames and the command line titles. Nothing here touches the UI.
local M = {}

local MODES = {
  i = "insert",
  v = "visual",
  V = "visual",
  ["\22"] = "visual",
  s = "visual",
  S = "visual",
  ["\19"] = "visual",
  R = "replace",
  c = "command",
  r = "command",
  ["!"] = "terminal",
  t = "terminal",
}

---The lualine mode an nvim mode belongs to.
---@param mode string|nil as nvim_get_mode or ModeChanged reports it
---@return "normal"|"insert"|"visual"|"replace"|"command"|"terminal"
function M.mode_name(mode)
  return MODES[(mode or "n"):sub(1, 1)] or "normal"
end

---What the statusline calls a mode in the franchise in use.
---@param mode string|nil
---@param chrome table lore.chrome
---@return string
function M.mode_label(mode, chrome)
  local name = M.mode_name(mode)
  return (chrome.modes or {})[name] or name:upper()
end

local LEVELS = { [0] = "trace", "debug", "info", "warn", "error" }

---The title a notification wears: its own when it has one, the franchise's word for its level otherwise.
---@param title string|nil
---@param level string|integer|nil "info" or vim.log.levels.INFO
---@param chrome table lore.chrome
---@return string
function M.notify_title(title, level, chrome)
  if title and vim.trim(title) ~= "" then
    return title
  end
  local name = type(level) == "number" and LEVELS[level] or level or "info"
  return (chrome.notify or {})[name] or name
end

-- how bright each line number stays as it moves away from the cursor, nearest first
M.GUTTER_STEPS = { 0.85, 0.68, 0.55, 0.44, 0.34 }

---The highlight group of a relative line number, nil on the cursor line.
---@param relnum integer
---@return string|nil
function M.number_group(relnum)
  if relnum <= 0 then
    return nil
  end
  return "EldenNr" .. math.min(relnum, #M.GUTTER_STEPS)
end

---Paints the number of a statuscolumn with the group of its distance to the cursor.
---@param column string the statuscolumn string snacks built, its number as "%=<n> "
---@param relnum integer
---@return string
function M.paint_number(column, relnum)
  local group = M.number_group(relnum)
  if not group then
    return column
  end
  return (column:gsub("%%=(%d+) ", "%%=%%#" .. group .. "#%1 %%*", 1))
end

local function walk(box, fn)
  fn(box)
  for _, child in ipairs(box) do
    if type(child) == "table" then
      walk(child, fn)
    end
  end
end

---Frames a picker layout in the franchise: the title between its ornaments, the preview named
---the franchise's way, every title centered.
---@param layout table snacks picker layout config
---@param ornament string[] like { "▐ ", " ▌" }
---@param examine string what the preview is called while nothing is selected
---@return table
function M.frame_layout(layout, ornament, examine)
  local framed = vim.deepcopy(layout)
  walk(framed.layout or {}, function(box)
    if type(box.title) ~= "string" then
      return
    end
    if box.title:find("{title}", 1, true) then
      -- live and flags stay outside, empty they would leave a gap inside the ornaments
      box.title = box.title:gsub("{title}", ornament[1] .. "{title}" .. ornament[2], 1)
    elseif box.title:find("{preview", 1, true) then
      box.title = ornament[1] .. "{preview:" .. examine .. "}" .. ornament[2]
    end
    box.title_pos = "center"
  end)
  return framed
end

---The command line formats noice shows, titled and marked the franchise's way.
---@param chrome table lore.chrome
---@param glyphs { icon: string, search: string } skin.cmdline
---@param ornament string[] like { "▐ ", " ▌" }
---@return table<string, table> noice cmdline.format entries
function M.cmdline_formats(chrome, glyphs, ornament)
  local function titled(text)
    return " " .. ornament[1] .. text .. ornament[2] .. " "
  end
  return {
    cmdline = { pattern = "^:", icon = glyphs.icon, lang = "vim", title = titled(chrome.cmdline) },
    search_down = {
      kind = "search",
      pattern = "^/",
      icon = glyphs.search .. " ",
      lang = "regex",
      title = titled(chrome.search),
    },
    search_up = {
      kind = "search",
      pattern = "^%?",
      icon = glyphs.search .. " ",
      lang = "regex",
      title = titled(chrome.search),
    },
  }
end

return M
