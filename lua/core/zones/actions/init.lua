-- Zones: every folder of a project is a place in the Lands Between. Pure naming and timing only.
local utils = require("core.utils")

local M = {}

M.COOLDOWN_MS = 20 * 1000
M.DEPTH = 2

-- folders every project has get the place that fits them best
M.LANDMARKS = {
  tests        = "Stranded Graveyard",
  test         = "Stranded Graveyard",
  spec         = "Stranded Graveyard",
  __tests__    = "Stranded Graveyard",
  docs         = "Raya Lucaria Academy",
  scripts      = "Roundtable Hold",
  node_modules = "Lake of Rot",
  vendor       = "Lake of Rot",
  [".github"]  = "Church of Elleh",
  assets       = "Siofra River",
  images       = "Siofra River",
  config       = "Caria Manor",
  lib          = "Leyndell, Royal Capital",
  components   = "Sellia, Town of Sorcery",
  api          = "Bellum Highway",
}

M.PLACES = {
  "Stormhill", "Weeping Peninsula", "Castle Morne", "Liurnia of the Lakes", "Caria Manor",
  "Altus Plateau", "Mt. Gelmir", "Siofra River", "Ainsel River", "Deeproot Depths",
  "Lake of Rot", "Consecrated Snowfield", "Mohgwyn Palace", "Raya Lucaria Academy",
  "Redmane Castle", "Sellia, Town of Sorcery", "Dragonbarrow", "Murkwater Cave",
  "Stranded Graveyard", "Church of Elleh", "Gatefront Ruins", "Agheel Lake", "Shaded Castle",
  "Elphael, Brace of the Haligtree", "Volcano Manor", "Nokstella, Eternal City",
  "Mountaintops of the Giants", "Forbidden Lands", "Academy Gate Town", "Bellum Highway",
  "Fort Haight", "Stormveil Castle", "Castle Sol", "Ordina, Liturgical Town",
}

--- Returns the zone a file lives in: its folder under the repo root, cut to DEPTH segments.
---@param file string absolute file path
---@param root string|nil repo root
---@return string|nil zone like "lua/core", nil for files at the root or outside it
function M.zone_key(file, root)
  if not root or file:sub(1, #root + 1) ~= root .. "/" then return nil end
  local relative_dir = vim.fs.dirname(file:sub(#root + 2))
  if relative_dir == "." or relative_dir == "" then return nil end
  local segments = vim.split(relative_dir, "/", { plain = true })
  return table.concat(vim.list_slice(segments, 1, M.DEPTH), "/")
end

--- Names a zone: a landmark when its folder is a well known one, otherwise a stable place for it.
---@param key string zone from M.zone_key
---@return string
function M.zone_name(key)
  local segments = vim.split(key, "/", { plain = true })
  for index = #segments, 1, -1 do
    local landmark = M.LANDMARKS[segments[index]]
    if landmark then return landmark end
  end
  return M.PLACES[utils.hash(key) % #M.PLACES + 1]
end

--- Decides whether entering a zone deserves its banner.
---@param opts { key: string|nil, seen: table<string, boolean>, now: number, last_shown: number|nil, busy: boolean }
---@return boolean
function M.should_announce(opts)
  if not opts.key or opts.seen[opts.key] or opts.busy then return false end
  return not opts.last_shown or opts.now - opts.last_shown >= M.COOLDOWN_MS
end

return M
