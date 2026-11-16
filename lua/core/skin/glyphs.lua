-- Pushes the skin's small marks into the options and the plugins that keep their own copy: the
-- whitespace and fold marks, snacks' indent guides and picker prompt, which-key, satellite's
-- scrollbar and noice's loading spinner. Plugins not loaded yet read the skin from their spec.
local actions = require("core.skin.actions")

local M = {}

-- the name noice's spinners are registered under, see lua/plugins/ui.lua
M.SPINNER = "eldentree"

--- Registers the skin's spinner with noice, so every LSP progress line turns in the franchise's frames.
---@param glyphs table skin.glyphs
function M.register_spinner(glyphs)
  local ok, spinners = pcall(require, "noice.util.spinners")
  if ok then
    spinners.spinners[M.SPINNER] =
      { frames = glyphs.spinner.frames, interval = glyphs.spinner.interval }
  end
end

-- snacks reads its indent config when the guides are enabled, so they are drawn again to change
local function indent(glyphs)
  local config = Snacks.config.indent
  if not config then
    return
  end
  config.indent.char = glyphs.indent
  config.scope.char = glyphs.scope
  if Snacks.indent.enabled then
    Snacks.indent.disable()
    Snacks.indent.enable()
  end
end

local function picker(glyphs)
  if Snacks.config.picker then
    Snacks.config.picker.prompt = glyphs.prompt
  end
end

-- which-key reads its icons every time it draws
local function which_key(glyphs)
  local config = package.loaded["which-key.config"]
  if config and config.options then
    config.options.icons =
      vim.tbl_extend("force", config.options.icons, actions.which_key_icons(glyphs))
  end
end

-- satellite's cursor handler shares its config table, so the new thumb shows on the next move
local function scrollbar(glyphs)
  local registry = package.loaded["satellite.handlers"]
  for _, handler in ipairs(registry and registry.handlers or {}) do
    if handler.name == "cursor" and handler.config then
      handler.config.symbols = glyphs.scrollbar
    end
  end
end

--- Applies the skin's glyphs to the options and to every plugin already loaded.
---@param glyphs table skin.glyphs
function M.apply(glyphs)
  vim.opt.listchars = actions.listchars(glyphs)
  vim.opt.fillchars = actions.fillchars(glyphs)
  local pushes = { which_key, scrollbar }
  if package.loaded["noice"] then
    table.insert(pushes, M.register_spinner)
  end
  if package.loaded["snacks"] then
    vim.list_extend(pushes, { indent, picker })
  end
  -- these reach into plugin internals, one that changed must never stop a franchise switch
  for _, push in ipairs(pushes) do
    pcall(push, glyphs)
  end
end

return M
