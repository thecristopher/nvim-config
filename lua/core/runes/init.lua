-- Keeps the rune tally, persists it between sessions, and feeds the statusline components.
local actions = require("core.runes.actions")
local motion = require("core.motion")
local color = require("core.motion.actions")

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
  require("core.utils").refresh_statusline()
end

-- worlds with a merchant greet you each time your purse crosses another milestone
local function visit_merchant(before, after)
  local lines = require("core.franchise").current().merchant
  if not lines or not actions.crossed(before, after) then
    return
  end
  require("core.sound").play("merchant")
  vim.notify(lines[math.random(#lines)], vim.log.levels.INFO, { title = "Merchant" })
end

local function settle(next_state, gained)
  local from = shown
  visit_merchant(state.held, next_state.held)
  state = next_state
  save()
  if gained and gained > 0 then
    gain = { amount = gained, until_ms = vim.uv.now() + 2600 }
  end
  if roll then
    roll:stop()
  end
  roll = motion.tween({
    duration = 1200,
    easing = "linear",
    frame_ms = 50,
    on_frame = function(t)
      shown = actions.roll(from, state.held, t)
      refresh_statusline()
    end,
  })
end

function M.award(amount)
  if amount > 0 then
    settle(actions.award(state, amount), amount)
  end
end

function M.after_banner(kind)
  local before = state.held
  local next_state = actions.after_banner(state, kind)
  settle(next_state, next_state.held - before)
end

-- statusline pieces -------------------------------------------------------------------

function M.held()
  local currency = require("core.franchise").current().currency
  local text = currency.glyph .. " " .. actions.format(shown)
  if state.bloodstain > 0 then
    text = text .. "  " .. currency.stain .. " " .. actions.format(state.bloodstain)
  end
  return text
end

function M.gain()
  if vim.uv.now() > gain.until_ms then
    return ""
  end
  return "+" .. actions.format(gain.amount)
end

local glow_level = 1

function M.grace()
  return ("%%#EldenGraceGlow%d#✦ %s"):format(glow_level, require("core.themes").current().title)
end

-- every step of the breath gets its own group once, so breathing never redefines a highlight
local function define_glow()
  local p = require("core.themes").palette()
  local dim, bright = color.to_int(p.overlay2), color.to_int(p.yellow)
  for level = 1, actions.GLOW_LEVELS do
    local glow = color.mix(dim, bright, (level - 1) / (actions.GLOW_LEVELS - 1))
    vim.api.nvim_set_hl(0, "EldenGraceGlow" .. level, { fg = glow, bg = p.surface0, bold = true })
  end
end

-- changing a highlight repaints every window, switching groups only repaints the statusline
local function breathe(elapsed)
  local level = actions.glow_level(elapsed)
  if level == glow_level then
    return
  end
  glow_level = level
  refresh_statusline()
end

function M.setup()
  load()
  define_glow()
  local group = vim.api.nvim_create_augroup("eldentree_runes", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(ev)
      edits[ev.buf] = (edits[ev.buf] or 0) + 1
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      M.award(actions.gain_for_edits(edits[ev.buf]))
      edits[ev.buf] = 0
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_glow })
  -- the grace breathes slowly, ten frames a second is plenty for something this gentle
  M.glow = motion.loop({ interval = 100, on_tick = breathe })
end

return M
