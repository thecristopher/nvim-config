-- Keeps the studio's cache lean: deletes free takes that have a paid version, and takes no role says
-- anymore (dropped fresh ones, a branch's take) once they are a month old. Runs once a day on its
-- own, :Voice prune runs it now and :Voice prune all empties the cache, recorded clips untouched.
local actions = require("core.voice.studio.actions")
local budget = require("core.voice.studio.actions.budget")
local store = require("core.voice.studio.store")

local M = {}

-- a take with holes is cached per branch or boss, and lives this long after nobody can name it
local GRACE_S = 30 * 86400

-- every cache name a cast role can still say, by voice, across every franchise with a script
local function live_names()
  local franchises = require("core.franchise.actions")
  local library = store.library()
  local live = {}
  for _, name in ipairs(franchises.all_names()) do
    for region, script in pairs(franchises.lore(name).script or {}) do
      if script.voice then
        live[script.voice] = live[script.voice] or {}
        local fresh = library[name .. "/" .. region] or {}
        for _, source in ipairs({ script.takes or {}, fresh }) do
          for _, takes in pairs(source) do
            for _, take in ipairs(takes) do
              live[script.voice][actions.cache_name(budget.PAID, take)] = true
              live[script.voice][actions.cache_name(budget.FREE, take)] = true
            end
          end
        end
      end
    end
  end
  return live
end

-- the audio files of one voice's folder with their age
local function files_of(dir, now)
  local files = {}
  for name, kind in vim.fs.dir(dir) do
    local stat = kind == "file" and name:match("%.mp3$") and vim.uv.fs_stat(dir .. "/" .. name)
    if stat then
      table.insert(files, { name = name, age_s = now - stat.mtime.sec })
    end
  end
  return files
end

---Deletes what the cache no longer needs.
---@return integer deleted how many files went
function M.run()
  local root = store.root()
  if vim.fn.isdirectory(root) == 0 then
    return 0
  end
  local live = live_names()
  local now = os.time()
  local deleted = 0
  for voice, kind in vim.fs.dir(root) do
    if kind == "directory" then
      local dir = root .. "/" .. voice
      for _, name in ipairs(actions.prune_plan(files_of(dir, now), live[voice] or {}, GRACE_S)) do
        deleted = deleted + (vim.uv.fs_unlink(dir .. "/" .. name) and 1 or 0)
      end
    end
  end
  return deleted
end

---Empties the cache: every voiced take and every fresh take. Clips recorded in the repo stay.
function M.all()
  vim.fn.delete(store.root(), "rf")
end

---Prunes once a day, remembered in the ledger.
function M.daily()
  local ledger = store.ledger()
  if ledger.pruned == ledger.day then
    return
  end
  M.run()
  ledger.pruned = ledger.day
  store.save_ledger(ledger)
end

return M
