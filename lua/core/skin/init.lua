-- Dresses every component in the franchise's skin: float borders through winborder, the gutter
-- signs, lualine separators and bufferline tabs. Runs at startup and again on :Franchise.
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

local function apply_signs()
  local severity = vim.diagnostic.severity
  vim.diagnostic.config({
    signs = { text = actions.sign_text(M.current().signs, severity) },
    float = { border = M.border(), source = true, header = "", prefix = "" },
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
  local opts = require("lazy.core.plugin").values(config.spec.plugins[plugin], "opts", false)
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
  apply_signs()
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
