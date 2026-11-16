-- Dresses every component in the franchise's skin: float borders through winborder, the cursor's
-- shapes, the gutter signs, the small marks of every plugin (core/skin/glyphs), lualine separators
-- and bufferline tabs. Runs at startup and again on :Franchise.
local actions = require("core.skin.actions")

local M = {}

--- Returns the skin of the franchise in use.
---@return table
function M.current()
  return require("core.franchise").current().skin
end

--- Returns the border every float should wear.
---@return string
function M.border()
  return M.current().border
end

--- Wraps a float title in the franchise's ornaments.
---@param title string
---@return string
function M.title(title)
  return actions.ornate(title, M.current())
end

--- Returns the franchise's glyph for a diagnostic or notification level.
---@param level string "error", "warn", "info", "hint", "debug" or "trace"
---@param given string|nil a glyph already chosen, which wins when it is not empty
---@return string
function M.icon(level, given)
  return actions.level_icon(M.current().icons, level, given)
end

--- Returns the skin's small marks: guides, whitespace, folds, prompt, which-key, scrollbar, spinner.
---@return table
function M.glyphs()
  return M.current().glyphs
end

local function apply_signs()
  local severity = vim.diagnostic.severity
  vim.diagnostic.config({
    signs = { text = actions.sign_text(M.current().signs, severity) },
    float = { border = M.border(), source = "if_many", header = "", prefix = "" },
  })
end

-- a plugin already set up rebuilds from its spec, which reads the new skin
local function resetup(plugin, module)
  if not package.loaded[module] then
    return
  end
  local ok, config = pcall(require, "lazy.core.config")
  if not ok or not config.spec.plugins[plugin] then
    return
  end
  local spec = config.spec.plugins[plugin]
  -- lazy keeps the opts it resolved the first time, which still hold the old franchise's skin
  actions.forget_resolved_opts(spec)
  local opts = require("lazy.core.plugin").values(spec, "opts", false)
  pcall(function()
    require(module).setup(opts)
  end)
end

--- Applies the skin of the franchise in use to everything that can change live.
function M.apply()
  vim.o.winborder = M.border()
  if vim.fn.exists("+pumborder") == 1 then
    vim.o.pumborder = M.border()
  end
  vim.o.guicursor = require("core.themes.actions").guicursor(M.current().cursor)
  apply_signs()
  require("core.skin.glyphs").apply(M.glyphs())
  resetup("lualine.nvim", "lualine")
  resetup("bufferline.nvim", "bufferline")
end

function M.setup()
  M.apply()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("eldentree_skin", { clear = true }),
    pattern = "EldentreeFranchise",
    callback = M.apply,
  })
end

return M
