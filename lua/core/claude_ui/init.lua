-- Keeps Claude Code dressed like the editor: rewrites its custom theme (~/.claude/themes/eldentree.json)
-- whenever the region or the franchise changes, and Claude Code reloads it on the spot. The statusline
-- and sound hooks live in claude/ at the repo root, claude/install.lua wires them into settings.json.
-- vim.g.eldentree_claude_ui = false leaves Claude Code alone.
local actions = require("core.claude_ui.actions")

local M = {}

local function claude_dir()
  return vim.env.CLAUDE_CONFIG_DIR or vim.fs.joinpath(vim.uv.os_homedir() or "", ".claude")
end

--- Writes the theme for the region in use, if Claude Code is installed and the theme changed.
function M.write_theme()
  if vim.g.eldentree_claude_ui == false or not vim.uv.fs_stat(claude_dir()) then
    return
  end
  local dir = vim.fs.joinpath(claude_dir(), "themes")
  vim.fn.mkdir(dir, "p")
  local file = vim.fs.joinpath(dir, actions.THEME_SLUG .. ".json")
  local theme =
    actions.theme(require("core.themes").current(), require("core.franchise").current().title)
  local lines = vim.split(vim.json.encode(theme, { indent = "  ", sort_keys = true }), "\n")
  local ok, current = pcall(vim.fn.readfile, file)
  -- Claude Code reloads on every write, so an unchanged theme is left as it is
  if ok and vim.deep_equal(current, lines) then
    return
  end
  pcall(vim.fn.writefile, lines, file)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_claude_ui", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "EldentreeRegionSettled", "EldentreeFranchise" },
    callback = M.write_theme,
  })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = M.write_theme })
end

return M
