-- The season of the day: on the few days that have one, its weather drifts through the HUD and
-- prose in every region, it picks the franchise (unless :Franchise or vim.g.eldentree_franchise
-- already did) and it announces itself once a day. vim.g.eldentree_seasons = false turns it off.
local actions = require("core.season.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_season"
-- after the title screen, so the two never share the screen
local ANNOUNCE_AFTER_MS = 9000

--- The season of today, nil on an ordinary day or when seasons are off.
---@return table|nil
function M.current()
  if vim.g.eldentree_seasons == false then
    return nil
  end
  return actions.season(os.date("*t") --[[@as osdate]], vim.g.eldentree_anniversary)
end

--- The weather the season brings, nil when the region keeps its own.
---@return table|nil
function M.weather()
  local season = M.current()
  return season and season.weather or nil
end

--- The franchise the season brings, nil when it brings none or it does not play here.
---@return string|nil
function M.franchise()
  return actions.franchise(M.current(), require("core.franchise.actions").names())
end

local function announced_today()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  return ok and lines[1] == os.date("%Y-%m-%d")
end

local function announce()
  local season = M.current()
  if not season or announced_today() then
    return
  end
  if require("core.banner").busy() then
    return vim.defer_fn(announce, 3000)
  end
  require("core.utils").write_state(state_file, { tostring(os.date("%Y-%m-%d")) })
  require("core.banner").region({ title = season.title, tagline = season.tagline })
end

function M.setup()
  vim.defer_fn(announce, ANNOUNCE_AFTER_MS)
end

return M
