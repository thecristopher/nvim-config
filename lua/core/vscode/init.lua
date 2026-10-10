-- Loaded only when nvim runs inside Cursor or VS Code via vscode-neovim
local actions = require("core.vscode.actions")

local M = {}

M.allowed = actions.allowed

function M.setup()
  local ok, vscode = pcall(require, "vscode")
  if not ok then return end

  for _, binding in ipairs(actions.bindings) do
    vim.keymap.set("n", binding.lhs, function() vscode.action(binding.command) end, {
      desc = binding.command,
    })
  end

  -- the editor owns the clipboard, line numbers and scrolling there
  vim.opt.clipboard = "unnamedplus"
  vim.opt.cursorline = false
  vim.opt.relativenumber = false
end

return M
