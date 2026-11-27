-- Where the voice studio keeps things: the cached audio and fresh takes in nvim's data folder (out
-- of the repo, exported with :Voice export), the money ledger in state and the Fish Audio key.
local actions = require("core.voice.studio.actions")
local budget = require("core.voice.studio.actions.budget")

local M = {}

local LEDGER_FILE = vim.fn.stdpath("state") .. "/eldentree_studio.json"
local DEFAULT_KEY_FILE = "~/.config/fish-audio/key"

---The folder that holds every voice's audio and the fresh takes, the one an export packs.
---@return string
function M.root()
  return vim.fn.stdpath("data") .. "/eldentree/voices"
end

local function lines_file()
  return M.root() .. "/lines.json"
end

local function read_json(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded and type(data) == "table" and data or nil
end

local function write_json(path, data)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  return require("core.utils").write_state(path, { vim.json.encode(data) })
end

---The Fish Audio API key, from FISH_API_KEY or the key file, nil when there is none.
---@return string|nil
function M.key()
  if vim.env.FISH_API_KEY and vim.env.FISH_API_KEY ~= "" then
    return vim.env.FISH_API_KEY
  end
  local path = vim.fn.expand(vim.g.eldentree_fish_key_file or DEFAULT_KEY_FILE)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  local key = ok and lines[1] and vim.trim(lines[1]) or ""
  return key ~= "" and key or nil
end

---The money ledger, rolled over to today.
---@return table
function M.ledger()
  return budget.rollover(read_json(LEDGER_FILE), os.date("%Y-%m-%d"))
end

---Keeps the ledger for the next take and the next session.
---@param ledger table
function M.save_ledger(ledger)
  write_json(LEDGER_FILE, ledger)
end

---Every role's fresh takes, by role then moment.
---@return table<string, table<string, string[]>>
function M.library()
  return read_json(lines_file()) or {}
end

---Keeps the fresh takes of every role.
---@param library table<string, table<string, string[]>>
function M.save_library(library)
  write_json(lines_file(), library)
end

---Where a take's audio lives for a voice and a model, whether it exists yet or not.
---@param voice string
---@param model string
---@param text string the take exactly as written in the script
---@return string
function M.path(voice, model, text)
  return ("%s/%s/%s"):format(M.root(), voice, actions.cache_name(model, text))
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

---The cached audio of a take, the paid model's first, nil when nobody has voiced it.
---@param voice string
---@param text string
---@return string|nil
function M.cached(voice, text)
  for _, model in ipairs({ budget.PAID, budget.FREE }) do
    local path = M.path(voice, model, text)
    if exists(path) then
      return path
    end
  end
  return nil
end

---Whether a take already has the paid model's audio, the one the baker aims for.
---@param voice string
---@param text string
---@return boolean
function M.has_paid(voice, text)
  return exists(M.path(voice, budget.PAID, text))
end

return M
