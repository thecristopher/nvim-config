-- Announces each part of a project the first time you walk into it this session, the way the game
-- names a new area. Each folder keeps the same place every session, and tests are always the Stranded Graveyard.
local actions = require("core.zones.actions")

local M = {}

local seen = {}
local last_shown

local function enter(buf)
  if vim.g.eldentree_zones == false or vim.bo[buf].buftype ~= "" then return end
  local file = vim.api.nvim_buf_get_name(buf)
  local key = actions.zone_key(file, require("core.repos").root(vim.fs.dirname(file)))
  local banner = require("core.banner")
  local now = vim.uv.now()
  if not actions.should_announce({ key = key, seen = seen, now = now, last_shown = last_shown, busy = banner.busy() }) then
    return
  end
  seen[key] = true
  last_shown = now
  banner.show("zone", { kind = { text = actions.zone_name(key) }, subtitle = key, reward = false })
end

function M.setup()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("eldentree_zones", { clear = true }),
    callback = function(ev) vim.schedule(function() enter(ev.buf) end) end,
  })
end

return M
