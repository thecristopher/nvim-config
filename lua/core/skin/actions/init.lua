-- Turns a franchise skin into what each component expects. Pure logic only.
local M = {}

-- telescope wants the eight border characters spelled out, top then corners
M.BORDER_CHARS = {
  rounded = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  double = { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
  single = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
}

--- Returns telescope's border characters for a border name, rounded when it has none.
---@param border string like "double"
---@return string[]
function M.border_chars(border)
  return M.BORDER_CHARS[border] or M.BORDER_CHARS.rounded
end

--- Returns the toggleterm name for a border, which calls rounded "curved".
---@param border string
---@return string
function M.toggleterm_border(border)
  return border == "rounded" and "curved" or border
end

--- Wraps a float title in the franchise's ornaments.
---@param title string
---@param skin table franchise skin
---@return string
function M.ornate(title, skin)
  local ornament = skin.ornament or { "", "" }
  return ornament[1] .. title .. ornament[2]
end

--- Builds vim.diagnostic sign text from the skin, keyed by severity.
---@param signs { error: string, warn: string, hint: string, info: string }
---@param severity table vim.diagnostic.severity
---@return table<integer, string>
function M.sign_text(signs, severity)
  return {
    [severity.ERROR] = signs.error,
    [severity.WARN] = signs.warn,
    [severity.HINT] = signs.hint,
    [severity.INFO] = signs.info,
  }
end

return M
