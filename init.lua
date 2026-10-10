-- Eldentree: a Neovim config forged in the Lands Between
-- macOS, Linux and Windows | Neovim >= 0.11 | also runs inside Cursor and VS Code

-- Leader keys must be set before lazy.nvim loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("core.options")
require("core.keymaps")
require("core.autocmds")

if vim.g.vscode then
  require("core.vscode").setup()
else
  require("core.repos").setup()
  require("core.motion").setup()
  require("core.banner").setup()
  require("core.hub").setup()
  require("core.trial").setup()
  require("core.runes").setup()
  require("core.rest").setup()
end

-- ── Bootstrap lazy.nvim ──────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy    = true,
    version = false,
    -- inside Cursor or VS Code the editor draws the UI, so only editing plugins load
    cond    = function(plugin)
      return not vim.g.vscode or require("core.vscode").allowed(plugin)
    end,
  },
  install = {
    colorscheme = { "catppuccin", "habamax" },
  },
  checker = {
    enabled   = true,
    notify    = false,
    frequency = 86400,
  },
  change_detection = {
    notify = false,
  },
  ui = {
    border  = "rounded",
    backdrop = 60,
  },
  performance = {
    cache = { enabled = true },
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
