-- Wires the Eldentree statusline, sound hooks, spinner verbs and theme into Claude Code's
-- settings.json, keeping everything already there and a backup next to it.
--   nvim -l claude/install.lua            apply
--   nvim -l claude/install.lua --dry-run  only list what would change
local settings = require("core.claude_ui.actions.settings")
local franchise = require("core.franchise.actions")

local M = {}

local function claude_dir()
  return vim.env.CLAUDE_CONFIG_DIR or vim.fs.joinpath(vim.uv.os_homedir() or "", ".claude")
end

local function read_settings(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok or #lines == 0 then
    return vim.empty_dict()
  end
  return vim.json.decode(table.concat(lines, "\n"))
end

local function plan(root)
  local lores = vim.tbl_map(franchise.lore, franchise.names())
  -- the PATH entry survives upgrades, progpath points inside a versioned install folder
  local nvim = ('"%s" -l'):format(
    vim.fn.exepath("nvim") ~= "" and vim.fn.exepath("nvim") or vim.v.progpath
  )
  return {
    statusline = ('%s "%s/claude/statusline.lua"'):format(nvim, root),
    hook = ('%s "%s/claude/hook.lua"'):format(nvim, root),
    verbs = settings.verbs(lores),
    theme = require("core.claude_ui.actions").THEME_SLUG,
  }
end

--- Merges the Eldentree pieces into settings.json, or lists them with --dry-run.
---@param root string repo root
---@param args string[] command line arguments
function M.run(root, args)
  local file = vim.fs.joinpath(claude_dir(), "settings.json")
  local data = read_settings(file)
  local changes = settings.merge(data, plan(root))
  if #changes == 0 then
    return print("Claude Code already wears Eldentree, nothing to change")
  end
  print("Changes to " .. file .. ":\n  " .. table.concat(changes, "\n  "))
  if vim.tbl_contains(args, "--dry-run") then
    return
  end
  -- the first backup is the settings from before Eldentree, later runs never overwrite it
  if vim.uv.fs_stat(file) and not vim.uv.fs_stat(file .. ".eldentree.bak") then
    vim.uv.fs_copyfile(file, file .. ".eldentree.bak")
  end
  vim.fn.mkdir(claude_dir(), "p")
  vim.fn.writefile(
    vim.split(vim.json.encode(data, { indent = "  ", sort_keys = true }), "\n"),
    file
  )
  require("core.claude_ui").write_theme()
  print("Done. The settings from before Eldentree are in " .. file .. ".eldentree.bak")
end

return M
