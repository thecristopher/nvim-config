-- The lines each moment said lately, kept in state so a restart does not bring the same line back
-- right away. Keyed by who speaks and the moment, newest first.
local actions = require("core.voice.actions")

local M = {}

local FILE = vim.fn.stdpath("state") .. "/eldentree_voice_recent.json"

local memory = nil

local function load()
  if memory then
    return memory
  end
  local ok, lines = pcall(vim.fn.readfile, FILE)
  local decoded, data = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  memory = decoded and type(data) == "table" and data or {}
  return memory
end

---The lines said lately for a key, newest first.
---@param key string like elden_ring/haligtree/pushed
---@return string[]
function M.get(key)
  return load()[key] or {}
end

---Remembers a line just said for a key.
---@param key string
---@param line string
function M.note(key, line)
  local all = load()
  all[key] = actions.remember(all[key], line)
  require("core.utils").write_state(FILE, { vim.json.encode(all) })
end

return M
