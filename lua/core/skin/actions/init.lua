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

--- Builds the listchars option from the skin's glyphs.
---@param glyphs table skin.glyphs
---@return table<string, string>
function M.listchars(glyphs)
  return { tab = glyphs.list.tab, trail = glyphs.list.trail, nbsp = glyphs.list.nbsp }
end

--- Builds the fillchars option from the skin's glyphs: folds, the diff filler, the lines between
--- windows and the mark past the end of the buffer.
---@param glyphs table skin.glyphs
---@return table<string, string>
function M.fillchars(glyphs)
  return {
    foldopen = glyphs.fold.open,
    foldclose = glyphs.fold.close,
    foldsep = " ",
    fold = " ",
    diff = glyphs.diff,
    eob = glyphs.eob or " ",
    vert = glyphs.split and glyphs.split.vert or "│",
    horiz = glyphs.split and glyphs.split.horiz or "─",
  }
end

--- Builds which-key's icons from the skin's glyphs.
---@param glyphs table skin.glyphs
---@return { breadcrumb: string, separator: string, group: string }
function M.which_key_icons(glyphs)
  return {
    breadcrumb = glyphs.keys.breadcrumb,
    separator = glyphs.keys.separator,
    group = glyphs.keys.group,
  }
end

--- Forgets the opts lazy.nvim resolved for a plugin, so its opts function runs again and reads the
--- skin of the franchise in use instead of the one the plugin first loaded with.
---@param plugin table a lazy.nvim plugin spec
function M.forget_resolved_opts(plugin)
  local cache = plugin and plugin._ and plugin._.cache
  if cache then
    cache.opts = nil
  end
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
