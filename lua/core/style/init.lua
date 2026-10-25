-- Reads the single my-style guide that lives in this repo, swap that file to make the config yours.
local actions = require("core.style.actions")

local M = {}

---@return string absolute path of the guide inside the config
function M.path()
  return vim.fn.stdpath("config") .. "/.claude/commands/my-style.md"
end

---@return string|nil guide contents, nil when the file is missing or unreadable
function M.read()
  local ok, lines = pcall(vim.fn.readfile, M.path())
  if not ok or #lines == 0 then
    return nil
  end
  return table.concat(lines, "\n")
end

---@return string[] style lines ready to drop into a claude prompt
function M.prompt_lines()
  return actions.prompt_lines(M.read())
end

return M
