-- The season of the day: on the few days that have one, its weather drifts through the HUD and
-- prose in every region, it picks the franchise (unless :Franchise or vim.g.eldentree_franchise
-- already did) and it announces itself once a day. vim.g.eldentree_seasons = false turns it off,
-- and :Season <name> brings one for the session to see it on any day.
local actions = require("core.season.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_season"
-- after the title screen, so the two never share the screen
local ANNOUNCE_AFTER_MS = 9000
-- the season :Season brought for this session, over the calendar's
local previewing

--- The season of today, nil on an ordinary day or when seasons are off.
---@return table|nil
function M.current()
  if vim.g.eldentree_seasons == false then
    return nil
  end
  if previewing then
    return previewing
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

--- Brings a season for this session (its weather and banner, the franchise stays), or with "off"
--- goes back to the calendar.
---@param name string a season name or "off"
function M.preview(name)
  if name == "off" or name == "" then
    previewing = nil
    return vim.notify("Back to the calendar's season", vim.log.levels.INFO, { title = "Season" })
  end
  local season = actions.named(name)
  if not season then
    local known = table.concat(actions.names(), ", ")
    return vim.notify("Unknown season, try " .. known, vim.log.levels.WARN, { title = "Season" })
  end
  previewing = season
  require("core.banner").region({ title = season.title, tagline = season.tagline })
end

function M.setup()
  vim.defer_fn(announce, ANNOUNCE_AFTER_MS)
  vim.api.nvim_create_user_command("Season", function(cmd)
    M.preview(cmd.args)
  end, {
    nargs = 1,
    complete = function()
      return vim.list_extend(actions.names(), { "off" })
    end,
    desc = "Bring a season for this session, or off for the calendar's",
  })
end

return M
