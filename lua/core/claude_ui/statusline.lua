-- Claude Code's statusline command: reads the session JSON on stdin, gathers the franchise and
-- region colors the editor knows, and prints the rows.
local render = require("core.claude_ui.actions.statusline").render

local M = {}

--- Prints the statusline for the session JSON waiting on stdin.
---@param _root string repo root, unused: everything comes from the lua modules
---@param _args string[] command line arguments, unused
function M.run(_root, _args)
  local ok, data = pcall(vim.json.decode, io.read("*a") or "")
  data = ok and type(data) == "table" and data or {}
  local rows = render(data, {
    lore = require("core.franchise").current(),
    region = require("core.themes").current(),
  })
  io.write(table.concat(rows, "\n"), "\n")
end

return M
