-- Turns a franchise skin into what each component expects. Pure logic only.
local M = {}

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

--- Returns the glyph for a level, a glyph the caller already chose winning over the skin's.
---@param icons table<string, string>|nil skin.icons
---@param level string "error", "warn", "info", "hint", "debug" or "trace"
---@param given string|nil glyph the notification brought, "" or nil when it brought none
---@return string
function M.level_icon(icons, level, given)
  if given and given ~= "" then
    return given
  end
  return (icons or {})[level] or ""
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
