-- Rules for running inside Cursor or VS Code through the vscode-neovim extension.
-- The editor draws everything there, so only pure text editing plugins load.
local M = {}

M.ALLOWED_PLUGINS = {
  ["lazy.nvim"] = true,
  ["flash.nvim"] = true,
  ["nvim-surround"] = true,
  ["mini.ai"] = true,
  ["nvim-treesitter"] = true,
  ["nvim-treesitter-textobjects"] = true,
}

function M.allowed(plugin)
  return M.ALLOWED_PLUGINS[plugin.name] == true
end

-- same muscle memory as the terminal config, routed to the editor's own commands
M.bindings = {
  { lhs = "gd", command = "editor.action.revealDefinition" },
  { lhs = "gp", command = "editor.action.peekDefinition" },
  { lhs = "gR", command = "editor.action.referenceSearch.trigger" },
  { lhs = "gr", command = "references-view.findReferences" },
  { lhs = "gI", command = "editor.action.goToImplementation" },
  { lhs = "gP", command = "editor.action.peekImplementation" },
  { lhs = "gy", command = "editor.action.goToTypeDefinition" },
  { lhs = "K", command = "editor.action.showHover" },
  { lhs = "[d", command = "editor.action.marker.prev" },
  { lhs = "]d", command = "editor.action.marker.next" },
  { lhs = "<S-h>", command = "workbench.action.previousEditor" },
  { lhs = "<S-l>", command = "workbench.action.nextEditor" },
  { lhs = "<leader>ca", command = "editor.action.quickFix" },
  { lhs = "<leader>cr", command = "editor.action.rename" },
  { lhs = "<leader>cf", command = "editor.action.formatDocument" },
  { lhs = "<leader>ff", command = "workbench.action.quickOpen" },
  { lhs = "<leader>fg", command = "workbench.action.findInFiles" },
  { lhs = "<leader>fp", command = "workbench.action.openRecent" },
  { lhs = "<leader>fe", command = "workbench.view.explorer" },
  { lhs = "<leader>xx", command = "workbench.actions.view.problems" },
  { lhs = "<leader>w", command = "workbench.action.files.save" },
  { lhs = "<leader>bd", command = "workbench.action.closeActiveEditor" },
  { lhs = "<leader>gl", command = "workbench.view.scm" },
  { lhs = "<leader>tt", command = "workbench.action.terminal.toggleTerminal" },
}

return M
