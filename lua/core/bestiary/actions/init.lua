-- The bestiary: every kind of diagnostic you cleared is a foe you felled, named by its code from
-- the franchise's enemies. The store is shaped like
-- { [repo] = { [code] = { kills = 3, source = "lua_ls", last = "2026-10-29" } } }. Pure logic only.
local M = {}

--- The key a diagnostic is known by: its code with its source, or its source alone.
---@param diagnostic { code?: string|integer, source?: string }
---@return string|nil nil when the diagnostic carries neither
function M.key(diagnostic)
  local code = diagnostic.code ~= nil and diagnostic.code ~= vim.NIL and tostring(diagnostic.code)
    or nil
  local source = diagnostic.source and tostring(diagnostic.source):gsub("%.$", "") or nil
  if code and code ~= "" then
    return source and (source .. " " .. code) or code
  end
  return source
end

--- Counts the diagnostics of a buffer per key, the reading the next one is compared to.
---@param diagnostics table[]
---@return table<string, integer>
function M.tally(diagnostics)
  local counts = {}
  for _, diagnostic in ipairs(diagnostics) do
    local key = M.key(diagnostic)
    if key then
      counts[key] = (counts[key] or 0) + 1
    end
  end
  return counts
end

--- The foes felled between two readings: every key that lost diagnostics, by how many.
---@param before table<string, integer>|nil
---@param after table<string, integer>
---@return table<string, integer>
function M.felled(before, after)
  local kills = {}
  for key, count in pairs(before or {}) do
    local left = after[key] or 0
    if left < count then
      kills[key] = count - left
    end
  end
  return kills
end

--- Writes the kills into the store.
---@param store table
---@param repo string
---@param kills table<string, integer>
---@param today string like "2026-10-29"
---@return table store
function M.record(store, repo, kills, today)
  for key, count in pairs(kills) do
    store[repo] = store[repo] or {}
    local entry = store[repo][key] or { kills = 0 }
    entry.kills = entry.kills + count
    entry.last = today
    store[repo][key] = entry
  end
  return store
end

--- Names the foe behind a key, the same one every time on every machine.
---@param key string
---@param enemies string[]
---@return string
function M.enemy(key, enemies)
  local hash = require("core.utils").hash(key)
  return enemies[hash % #enemies + 1]
end

--- The foes of a repo, the most felled first.
---@param store table
---@param repo string
---@param enemies string[]
---@return { key: string, enemy: string, kills: integer, last: string }[]
function M.entries(store, repo, enemies)
  local entries = {}
  for key, entry in pairs(store[repo] or {}) do
    table.insert(
      entries,
      { key = key, enemy = M.enemy(key, enemies), kills = entry.kills, last = entry.last }
    )
  end
  table.sort(entries, function(a, b)
    if a.kills ~= b.kills then
      return a.kills > b.kills
    end
    return a.key < b.key
  end)
  return entries
end

return M
