-- What the HUD reads from slow sources (git, the map survey) stays cached and is fetched again in
-- the background, so building the tabs never waits on a process. When a fetch brings something new
-- the HUD rebuilds its tabs from the cache.
local actions = require("core.hud.actions")

local M = {}

M.TTL_MS = 10000

-- key -> { value, at, running }
local entries = {}

--- The cached value for a key, nil until the first fetch lands. Starts a fetch when the value is
--- missing or older than TTL_MS and none is running.
---@param key string
---@param fetch fun(done: fun(value: any)) gathers the value and calls done once, on the main loop
---@return any
function M.get(key, fetch)
  local entry = entries[key] or {}
  entries[key] = entry
  if entry.running or not actions.stale(entry.at, vim.uv.now(), M.TTL_MS) then
    return entry.value
  end
  entry.running = true
  fetch(function(value)
    entry.running = false
    entry.at = vim.uv.now()
    if vim.deep_equal(entry.value, value) then
      return
    end
    entry.value = value
    require("core.hud").refresh(true)
  end)
  return entry.value
end

--- Drops every cached value, so the next build fetches fresh ones (after a branch switch, say).
function M.forget()
  entries = {}
end

--- Runs git in the background and hands over its output lines, empty when it fails.
---@param root string repo
---@param args string[]
---@param done fun(lines: string[], ok: boolean)
function M.git(root, args, done)
  -- spawning costs ~0.6 ms a process, so it waits until the HUD being built is on screen
  vim.schedule(function()
    vim.system(
      vim.list_extend({ "git", "-C", root }, args),
      { text = true },
      vim.schedule_wrap(function(result)
        local ok = result.code == 0
        done(ok and vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true }) or {}, ok)
      end)
    )
  end)
end

return M
