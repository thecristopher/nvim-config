-- Keeps the rune tally, persists it between sessions, and feeds the statusline components.
local actions = require("core.runes.actions")
local motion  = require("core.motion")
local color   = require("core.motion.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_runes"
local state = { held = 0, bloodstain = 0 }
local shown = 0
local gain = { amount = 0, until_ms = 0 }
local edits = {}
local roll

local function load()
  local ok, lines = pcall(vim.fn.readfile, state_file, "", 1)
  state = actions.decode(ok and lines[1] or nil)
  shown = state.held
end

local function save()
  pcall(vim.fn.writefile, { actions.encode(state) }, state_file)
end

local function refresh_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then lualine.refresh({ place = { "statusline" } }) end
end

local function settle(next_state, gained)
  local from = shown
  state = next_state
  save()
  if gained and gained > 0 then gain = { amount = gained, until_ms = vim.uv.now() + 2600 } end
  if roll then roll:stop() end
  roll = motion.tween({
    duration = 1200,
    easing   = "linear",
    frame_ms = 50,
    on_frame = function(t)
      shown = actions.roll(from, state.held, t)
      refresh_statusline()
    end,
  })
end

function M.award(amount)
  if amount > 0 then settle(actions.award(state, amount), amount) end
end

function M.after_banner(kind)
  local before = state.held
  local next_state = actions.after_banner(state, kind)
  settle(next_state, next_state.held - before)
end

-- statusline pieces -------------------------------------------------------------------

function M.held()
  local text = "◈ " .. actions.format(shown)
  if state.bloodstain > 0 then text = text .. "  󰈸 " .. actions.format(state.bloodstain) end
  return text
end

function M.gain()
  if vim.uv.now() > gain.until_ms then return "" end
  return "+" .. actions.format(gain.amount)
end

function M.grace()
  return "✦ " .. require("core.themes").current().title
end

local function paint_glow(elapsed)
  local p = require("core.themes").palette()
  local glow = color.mix(color.to_int(p.overlay2), color.to_int(p.yellow), actions.breath(elapsed or 0))
  vim.api.nvim_set_hl(0, "EldenGraceGlow", { fg = glow, bg = p.surface0, bold = true })
end

function M.setup()
  load()
  paint_glow(0)
  local group = vim.api.nvim_create_augroup("eldentree_runes", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(ev) edits[ev.buf] = (edits[ev.buf] or 0) + 1 end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      M.award(actions.gain_for_edits(edits[ev.buf]))
      edits[ev.buf] = 0
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = function() paint_glow(0) end })
  -- the grace breathes slowly, ten frames a second is plenty for something this gentle
  M.glow = motion.loop({ interval = 100, on_tick = paint_glow })
end

return M
