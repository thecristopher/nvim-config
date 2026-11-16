-- Claude Code's statusline command: reads the session JSON on stdin, gathers the franchise and
-- region colors the editor knows, and prints the rows.
local statusline = require("core.claude_ui.actions.statusline")

-- the branch from .git/HEAD, read straight from the file so the statusline never waits on git.
-- Inside nvim the editor's statusline already shows it, so it is left out there
local function branch(data)
  if vim.env.NVIM then
    return nil
  end
  local dir = type(data.workspace) == "table" and data.workspace.current_dir or data.cwd
  local git = dir and vim.fs.find(".git", { path = dir, upward = true })[1]
  if not git then
    return nil
  end
  local ok, lines = pcall(vim.fn.readfile, git .. "/HEAD", "", 1)
  return ok and statusline.branch(lines[1]) or nil
end

local M = {}

--- Prints the statusline for the session JSON waiting on stdin.
---@param _root string repo root, unused: everything comes from the lua modules
---@param _args string[] command line arguments, unused
function M.run(_root, _args)
  local ok, data = pcall(vim.json.decode, io.read("*a") or "")
  data = ok and type(data) == "table" and data or {}
  local rows = statusline.render(data, {
    lore = require("core.franchise").current(),
    region = require("core.themes").current(),
    branch = branch(data),
  })
  io.write(table.concat(rows, "\n"), "\n")
end

return M
