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

---The highlight group of a relative line number, nil on the cursor line of the window in focus.
---Every number of a window out of focus takes the faintest step, so the eye finds the active one.
---@param relnum integer
---@param focused? boolean false for a window out of focus, defaults to true
---@return string|nil
function M.number_group(relnum, focused)
  if focused == false then
    return "EldenNr" .. #M.GUTTER_STEPS
  end
  if relnum <= 0 then
    return nil
  end
  return "EldenNr" .. math.min(relnum, #M.GUTTER_STEPS)
end

---Paints the number of a statuscolumn with the group of its distance to the cursor.
---@param column string the statuscolumn string snacks built, its number as "%=<n> "
---@param relnum integer
---@param focused? boolean false for a window out of focus
---@return string
function M.paint_number(column, relnum, focused)
  local group = M.number_group(relnum, focused)
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

-- the column code should stay within when the buffer sets no textwidth
M.RULER_DEFAULT = 100

---The last column code should reach: the buffer's textwidth, or the default when it has none.
---@param textwidth integer
---@return integer
function M.ruler_limit(textwidth)
  return textwidth > 0 and textwidth or M.RULER_DEFAULT
end

---Whether a buffer has a column worth keeping: code without wrap, or any buffer with a textwidth
---of its own (a commit message keeps its 72). Wrapped prose has no column to stay within.
---@param textwidth integer
---@param wrap boolean
---@return boolean
function M.ruler_applies(textwidth, wrap)
  return textwidth > 0 or not wrap
end

---The match pattern for the part of every line that runs past the limit.
---@param limit integer
---@return string
function M.overflow_pattern(limit)
  return ("\\%%>%dv.\\+"):format(limit)
end

-- clients that never speak the buffer's language, they would only crowd the label
M.QUIET_CLIENTS = { copilot = true, ["null-ls"] = true }

---The statusline's language piece: the filetype icon with the language servers attached, or the
---filetype itself while none is.
---@param icon string devicon of the filetype, "" when there is none
---@param filetype string
---@param client_names string[]
---@return string
function M.language_label(icon, filetype, client_names)
  local names = vim.tbl_filter(function(name)
    return not M.QUIET_CLIENTS[name]
  end, client_names)
  local text = #names > 0 and table.concat(names, " ") or filetype
  if text == "" then
    return ""
  end
  return icon ~= "" and (icon .. " " .. text) or text
end

---A terminal buffer's name the way a person says it: the shell and its toggleterm number.
---@param bufname string like "term://~/repo//4242:/bin/zsh;#toggleterm#1"
---@return string like "zsh #1", or "terminal" when the name says nothing usable
function M.terminal_title(bufname)
  local command = bufname:match("^term://.-//%d+:([^;]+)") or ""
  local shell = vim.fs.basename(vim.trim(command):match("^(%S+)") or "")
  local number = bufname:match("#toggleterm#(%d+)")
  local title = shell ~= "" and shell or "terminal"
  return number and (title .. " #" .. number) or title
end

-- the narrowest editor each statusline piece still shows in: on a narrow screen the least needed
-- leave first, instead of lualine cutting the whole bar short with "<"
M.STATUSLINE_MIN = {
  music = 150,
  btb = 135,
  ci = 120,
  runes = 110,
  diff = 100,
  status = 90,
  language = 80,
}

---Whether a statusline piece fits an editor this wide.
---@param piece string a key of STATUSLINE_MIN, anything else always shows
---@param columns integer
---@return boolean
function M.shows(piece, columns)
  return columns >= (M.STATUSLINE_MIN[piece] or 0)
end

---Whether a buffer holds something with a name and a language worth naming in the statusline:
---files and help pages do, the HUD, pickers, prompts and lists do not.
---@param buftype string
---@return boolean
function M.names_itself(buftype)
  return buftype == "" or buftype == "help"
end

return M
