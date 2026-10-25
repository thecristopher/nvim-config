-- A boss health bar for buffers that stay full of errors. The region's boss shows up after the
-- errors linger, every fix lands as a hit with a gold chip of damage, and the last fix fells it.
-- Worlds where the boss is a stalker draw a hall instead, with the boss walking toward you.
local actions = require("core.boss.actions")
local motion = require("core.motion")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_boss")
local fights = {}
local view
local animation
local hunt

local function palette()
  return require("core.themes").palette()
end

local function define_highlights()
  local p = palette()
  -- the space around the text stays see through, only the bar and its letters are drawn
  local clear = { bg = p.base, blend = 100 }
  vim.api.nvim_set_hl(0, "EldenBossVeil", clear)
  vim.api.nvim_set_hl(0, "EldenBossName", vim.tbl_extend("force", clear, { fg = p.text }))
  vim.api.nvim_set_hl(
    0,
    "EldenBossDamage",
    vim.tbl_extend("force", clear, { fg = p.subtext1, bold = true })
  )
  vim.api.nvim_set_hl(0, "EldenBossFill", vim.tbl_extend("force", clear, { fg = p.red }))
  vim.api.nvim_set_hl(0, "EldenBossChip", vim.tbl_extend("force", clear, { fg = p.yellow }))
  vim.api.nvim_set_hl(0, "EldenBossEmpty", vim.tbl_extend("force", clear, { fg = p.surface2 }))
end

local function stalker_mode()
  return require("core.franchise").mechanic("boss") == "stalker"
end

local function enabled()
  return vim.g.eldentree_boss ~= false
end

local function error_count(buf)
  return vim.diagnostic.count(buf, { severity = vim.diagnostic.severity.ERROR })[vim.diagnostic.severity.ERROR]
    or 0
end

-- with motion stilled every animation is already over, so the bar shows its final state
local function now()
  return motion.enabled() and vim.uv.now() or math.huge
end

local function row_for_cursor()
  return actions.placement({
    lines = vim.o.lines,
    cmdheight = vim.o.cmdheight,
    statusline = vim.o.laststatus > 0 and 1 or 0,
    cursor_row = vim.fn.screenrow(),
    top = 1,
  })
end

local function close_view()
  if not view then
    return
  end
  pcall(vim.api.nvim_win_close, view.win, true)
  pcall(vim.api.nvim_buf_delete, view.buf, { force = true })
  view = nil
end

-- stops the animation too, or its next frame would draw the bar again over another buffer
local function hide()
  if animation then
    animation:stop()
  end
  if hunt then
    hunt:stop()
  end
  animation, hunt = nil, nil
  close_view()
end

local function window_config(width)
  return {
    relative = "editor",
    row = row_for_cursor(),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = actions.HEIGHT,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 40,
    noautocmd = true,
  }
end

local function open_view()
  local width = actions.width(vim.o.columns)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, false, window_config(width))
  -- any winblend switches on per cell blending, the groups then decide what shows through
  vim.wo[win].winblend = 1
  vim.wo[win].winhighlight = "Normal:EldenBossVeil"
  view = { buf = buf, win = win, width = width }
end

local function bar_line(segments)
  local runs = {
    { segments.fill, "EldenBossFill" },
    { segments.chip, "EldenBossChip" },
    { segments.empty, "EldenBossEmpty" },
  }
  local text, marks, byte = "", {}, 0
  for _, run in ipairs(runs) do
    local piece = ("━"):rep(run[1])
    table.insert(marks, { byte, byte + #piece, run[2] })
    text, byte = text .. piece, byte + #piece
  end
  return text, marks
end

local function hall_line(hall)
  local runs = {
    { "●", "EldenBossChip" },
    { ("┈"):rep(hall.near), "EldenBossFill" },
    { "◆", "EldenBossFill" },
    { ("┈"):rep(hall.far), "EldenBossEmpty" },
  }
  local text, marks = "", {}
  for _, run in ipairs(runs) do
    table.insert(marks, { #text, #text + #run[1], run[2] })
    text = text .. run[1]
  end
  return text, marks
end

local function paint(header, name_end, line, marks)
  vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, { header, line })
  vim.api.nvim_buf_clear_namespace(view.buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(
    view.buf,
    ns,
    0,
    0,
    { end_col = name_end, hl_group = "EldenBossName" }
  )
  vim.api.nvim_buf_set_extmark(
    view.buf,
    ns,
    0,
    name_end,
    { end_col = #header, hl_group = "EldenBossDamage" }
  )
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(
      view.buf,
      ns,
      1,
      mark[1],
      { end_col = mark[2], hl_group = mark[3] }
    )
  end
end

-- the stalker keeps walking between fixes, so the hall redraws on its own while the hunt is on
local function render_stalker(fight)
  local closeness = actions.closeness(fight.errors, fight.peak, now() - fight.entered_at)
  local line, marks = hall_line(actions.hall(view.width, closeness))
  paint(actions.stalker_header(fight.name, closeness, view.width), #fight.name, line, marks)
  if hunt and hunt:running() then
    return
  end
  hunt = motion.loop({
    interval = 250,
    on_tick = function()
      if not view or animation and animation:running() then
        return
      end
      local current = fights[vim.api.nvim_get_current_buf()]
      if current then
        render_stalker(current)
      end
    end,
  })
end

local function render(fight)
  if not view or not vim.api.nvim_win_is_valid(view.win) then
    open_view()
  end
  if stalker_mode() then
    return render_stalker(fight)
  end
  local frame = actions.frame(fight, now())
  local header = actions.header(fight.name, frame.damage, view.width)
  local bar, marks = bar_line(actions.segments(view.width, frame.fill, frame.chip))
  paint(header, #fight.name, bar, marks)
end

local function animate(fight, duration, on_done)
  if animation then
    animation:stop()
  end
  animation = motion.tween({
    duration = duration,
    easing = "linear",
    frame_ms = 33,
    on_frame = function()
      render(fight)
    end,
    on_done = on_done,
  })
end

local function felled(buf, fight)
  fights[buf] = nil
  hide()
  require("core.banner").show("felled", { subtitle = fight.name })
end

local function engage(fight)
  fight.engaged = true
  fight.peak = fight.errors
  fight.health = 1
  fight.entered_at = vim.uv.now()
  fight.name = actions.boss_for(require("core.themes").current().name)
  require("core.sound").play("boss")
  animate(fight, actions.ENTRANCE_MS)
end

-- a fix is a hit: the health drops at once and the gold chip drains behind it
local function hit(buf, fight, errors)
  local landed = fight.errors - errors
  local fresh = fight.hit_at and vim.uv.now() - fight.hit_at < actions.hit_duration()
  fight.chip_from = fresh
      and actions.chip_at(fight.chip_from, fight.health, vim.uv.now() - fight.hit_at)
    or fight.health
  fight.damage = (fresh and fight.damage or 0) + landed
  fight.hit_at = vim.uv.now()
  fight.errors = errors
  fight.health = actions.health(errors, fight.peak)
  local on_done = errors == 0 and function()
    felled(buf, fight)
  end or nil
  animate(fight, actions.hit_duration(), on_done)
end

-- new errors heal the boss, and a worse moment than before raises its full health
local function heal(fight, errors)
  fight.errors = errors
  fight.peak = math.max(fight.peak, errors)
  fight.health = actions.health(errors, fight.peak)
  fight.hit_at = nil
  render(fight)
end

local function update_engaged(buf, fight, errors)
  if errors < fight.errors then
    return hit(buf, fight, errors)
  end
  if errors > fight.errors then
    return heal(fight, errors)
  end
  render(fight)
end

local function watch_for_fight(buf, errors)
  local fight = fights[buf] or { since = vim.uv.now() }
  fight.errors = errors
  fights[buf] = fight
  if actions.should_engage({ errors = errors, since = fight.since, now = vim.uv.now() }) then
    return engage(fight)
  end
  if fight.pending then
    return
  end
  -- check again once the errors have lingered long enough to count, one timer per fight
  fight.pending = true
  vim.defer_fn(function()
    fight.pending = false
    M.refresh()
  end, actions.ENGAGE_AFTER_MS)
end

--- Reconciles the bar with the current buffer's errors: starts, updates, hides or ends the fight.
function M.refresh()
  local buf = vim.api.nvim_get_current_buf()
  if not enabled() or vim.bo[buf].buftype ~= "" then
    return hide()
  end

  local errors, fight = error_count(buf), fights[buf]
  if fight and fight.engaged then
    return update_engaged(buf, fight, errors)
  end

  hide()
  if errors < actions.THRESHOLD then
    fights[buf] = nil
    return
  end
  watch_for_fight(buf, errors)
end

--- Tells whether a boss is fighting in a buffer, so other celebrations can step aside.
---@param buf integer
---@return boolean
function M.engaged(buf)
  return fights[buf] ~= nil and fights[buf].engaged == true
end

--- Flips boss fights on or off.
function M.toggle()
  vim.g.eldentree_boss = not enabled()
  M.refresh()
  vim.notify("Boss fights " .. (enabled() and "on" or "off"))
end

local function follow_cursor()
  if not view or not vim.api.nvim_win_is_valid(view.win) then
    return
  end
  local row = row_for_cursor()
  if vim.api.nvim_win_get_config(view.win).row ~= row then
    vim.api.nvim_win_set_config(
      view.win,
      { relative = "editor", row = row, col = window_config(view.width).col }
    )
  end
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_boss", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = group,
    callback = function()
      vim.schedule(M.refresh)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev)
      fights[ev.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      hide()
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "WinScrolled" },
    { group = group, callback = follow_cursor }
  )
  vim.api.nvim_create_user_command("Boss", M.toggle, { desc = "Toggle Eldentree boss fights" })
end

return M
