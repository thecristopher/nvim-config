-- Zones: every folder of a project is a place in the franchise's world. Pure naming and timing only.
local utils = require("core.utils")

local M = {}

M.COOLDOWN_MS = 20 * 1000
M.DEPTH = 2

--- Returns the zone a file lives in: its folder under the repo root, cut to DEPTH segments.
---@param file string absolute file path
---@param root string|nil repo root
---@return string|nil zone like "lua/core", nil for files at the root or outside it
function M.zone_key(file, root)
  if not root or file:sub(1, #root + 1) ~= root .. "/" then
    return nil
  end
  local relative_dir = vim.fs.dirname(file:sub(#root + 2))
  if relative_dir == "." or relative_dir == "" then
    return nil
  end
  local segments = vim.split(relative_dir, "/", { plain = true })
  return table.concat(vim.list_slice(segments, 1, M.DEPTH), "/")
end

local function landmark_of(key, landmarks)
  local segments = vim.split(key, "/", { plain = true })
  for index = #segments, 1, -1 do
    local landmark = landmarks[segments[index]]
    if landmark then
      return landmark
    end
  end
  return nil
end

local function place_index(key, places)
  return utils.hash(key) % #places + 1
end

--- The places a zone may be named after: the region's own world first, then the lore's shared ones,
--- so a franchise whose regions are different worlds never lands in another region's.
---@param lore { places: string[] }
---@param region { places?: string[] }|nil
---@return string[]
function M.places_of(lore, region)
  return vim.list_extend(vim.list_extend({}, region and region.places or {}), lore.places or {})
end

local function current_places(lore)
  return M.places_of(lore, require("core.themes").current())
end

--- Names a zone: a landmark when its folder is a well known one, otherwise a stable place for it.
---@param key string zone from M.zone_key
---@return string
function M.zone_name(key)
  local lore = require("core.franchise").current()
  local places = current_places(lore)
  return landmark_of(key, lore.landmarks) or places[place_index(key, places)]
end

M.NUMERALS = { "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }

-- the first place from the key's own that nobody in the project took yet, nil when all are taken
local function free_place(key, places, taken)
  local start = place_index(key, places)
  for step = 0, #places - 1 do
    local place = places[(start - 1 + step) % #places + 1]
    if not taken[place] then
      return place
    end
  end
  return nil
end

-- a name already taken gets the next numeral, like a second wing of the same building
local function numbered(name, taken)
  for _, numeral in ipairs(M.NUMERALS) do
    local candidate = name .. " " .. numeral
    if not taken[candidate] then
      return candidate
    end
  end
  return name
end

--- Names every zone of one project so no two share a name: landmarks keep their name with a
--- numeral for the second wing, any other folder walks on to the next free place.
---@param keys string[] zones from M.zone_key, in the order they should claim their names
---@return table<string, string> name per key
function M.zone_names(keys)
  local lore = require("core.franchise").current()
  local places = current_places(lore)
  local taken, names = {}, {}
  for _, key in ipairs(keys) do
    local landmark = landmark_of(key, lore.landmarks)
    local name = landmark or free_place(key, places, taken)
    if not name or taken[name] then
      name = numbered(name or places[place_index(key, places)], taken)
    end
    taken[name], names[key] = true, name
  end
  return names
end

--- Decides whether entering a zone deserves its banner.
---@param opts { key: string|nil, seen: table<string, boolean>, now: number, last_shown: number|nil, busy: boolean }
---@return boolean
function M.should_announce(opts)
  if not opts.key or opts.seen[opts.key] or opts.busy then
    return false
  end
  return not opts.last_shown or opts.now - opts.last_shown >= M.COOLDOWN_MS
end

return M
