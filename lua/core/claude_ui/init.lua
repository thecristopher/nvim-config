-- Keeps Claude Code dressed like the editor: rewrites its custom theme (~/.claude/themes/eldentree.json)
-- and the spinner verbs in settings.json whenever the region or the franchise changes, so the
-- spinner speaks of the character in use. The statusline reads its bars from the region on its own.
-- The statusline and sound hooks live in claude/ at the repo root, claude/install.lua wires them
-- into settings.json, and the verbs are only rewritten once it has.
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

--- Puts the verbs of the role in use in Claude Code's spinner, once install.lua has wired it.
function M.write_verbs()
  if vim.g.eldentree_claude_ui == false then
    return
  end
  local file = vim.fs.joinpath(claude_dir(), "settings.json")
  local ok, lines = pcall(vim.fn.readfile, file)
  local decoded, data = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  if not decoded or type(data) ~= "table" or type(data.spinnerVerbs) ~= "table" then
    return
  end
  local settings = require("core.claude_ui.actions.settings")
  local franchise = require("core.franchise.actions")
  local verbs =
    settings.verbs_for(require("core.franchise").current(), require("core.themes").current())
  local known = settings.known_verbs(vim.tbl_map(franchise.lore, franchise.all_names()))
  if not settings.set_verbs(data, verbs, known) then
    return
  end
  -- written beside it and renamed, so Claude Code never reads half a file
  local tmp = file .. ".eldentree.tmp"
  local encoded = vim.json.encode(data, { indent = "  ", sort_keys = true })
  if pcall(vim.fn.writefile, vim.split(encoded, "\n"), tmp) then
    vim.uv.fs_rename(tmp, file)
  end
end

local function dress()
  M.write_theme()
  M.write_verbs()
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_claude_ui", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "EldentreeRegionSettled", "EldentreeFranchise" },
    callback = dress,
  })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = dress })
end

return M
