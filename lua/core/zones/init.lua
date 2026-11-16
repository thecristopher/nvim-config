-- Announces each part of a project the first time you walk into it each day, the way the game
-- names a new area. Each folder keeps the same place every session, and tests are always the Stranded
-- Graveyard. The days each zone was announced live in eldentree_zones.json in state.
local actions = require("core.zones.actions")

local M = {}

local last_shown
local state_file = vim.fn.stdpath("state") .. "/eldentree_zones.json"
-- day per "<root>/<zone>", read once and written on every announcement
local shown

local function read_shown()
  if shown then
    return shown
  end
  local ok, lines = pcall(vim.fn.readfile, state_file)
  local decoded_ok, decoded = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  shown = (decoded_ok and type(decoded) == "table") and decoded or {}
  return shown
end

-- only today's entries are kept, so the file never grows past the zones of one day
local function remember(place, day)
  local kept = { [place] = day }
  for other, seen_day in pairs(read_shown()) do
    if seen_day == day then
      kept[other] = seen_day
    end
  end
  shown = kept
  require("core.utils").write_state(state_file, { vim.json.encode(kept) })
end

-- the zones already announced today, as a set
local function seen_on(day)
  local set = {}
  for place, seen_day in pairs(read_shown()) do
    set[place] = seen_day == day or nil
  end
  return set
end

local function enter(buf)
  -- scheduled from BufEnter, so the buffer may be gone already (the HUD wipes itself on leaving)
  if
    vim.g.eldentree_zones == false
    or not vim.api.nvim_buf_is_valid(buf)
    or vim.bo[buf].buftype ~= ""
  then
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  local root = require("core.repos").root(vim.fs.dirname(file))
  local key = actions.zone_key(file, root)
  local banner = require("core.banner")
  local now = vim.uv.now()
  local day = os.date("%Y-%m-%d")
  -- zones share names across repos (every repo has a lua/core), so each is kept with its root
  local place = key and (root .. "/" .. key)
  if
    not actions.should_announce({
      key = place,
      seen = seen_on(day),
      now = now,
      last_shown = last_shown,
      busy = banner.busy(),
    })
  then
    return
  end
  last_shown = now
  remember(place, day)
  banner.show("zone", { kind = { text = actions.zone_name(key) }, subtitle = key, reward = false })
end

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("eldentree_zones", { clear = true }),
    callback = function(ev)
      vim.schedule(function()
        enter(ev.buf)
      end)
    end,
  })
end

return M
