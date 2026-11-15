-- The heartbeat behind every Eldentree animation. One clock drives every tween and ambient loop,
-- so rhythms that share a period land on the same frame and the editor wakes once for all of them.
-- One switch (vim.g.eldentree_motion = false or <leader>um) stills everything, ambient loops sleep
-- while the terminal is unfocused, and a replaying macro skips straight to the last frame.
local actions = require("core.motion.actions")

local M = {}

M.FRAME_MS = 16

local focused = true

-- every subscriber is { step = fn(now) -> keep, interval, due, ambient? }, keyed by itself
local clock = { timer = nil, epoch = vim.uv.now(), subs = {} }

function M.enabled()
  return vim.g.eldentree_motion ~= false and not vim.g.vscode and #vim.api.nvim_list_uis() > 0
end

-- a macro replaying hundreds of mode changes should not start hundreds of fades
local function replaying()
  return vim.fn.reg_executing() ~= ""
end

local function report(err)
  vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Eldentree motion" })
end

-- tweens always finish, ambient loops only tick while someone can see them
local function awake(sub)
  if sub.ambient then
    return focused and M.enabled()
  end
  return true
end

local function awake_dues()
  local dues = {}
  for sub in pairs(clock.subs) do
    if awake(sub) then
      table.insert(dues, sub.due)
    end
  end
  return dues
end

local tick

-- sleeps until the earliest subscriber is due, or stops the clock when nobody is
local function arm()
  clock.timer = clock.timer or vim.uv.new_timer()
  clock.timer:stop()
  local wait = actions.sleep_for(awake_dues(), vim.uv.now())
  if wait then
    clock.timer:start(wait, 0, vim.schedule_wrap(tick))
  end
end

local function run(sub, now)
  local ok, keep = pcall(sub.step, now)
  if not ok then
    report(keep)
  end
  if ok and keep then
    sub.due = actions.next_beat(now, clock.epoch, sub.interval)
    return
  end
  clock.subs[sub] = nil
end

tick = function()
  local now = vim.uv.now()
  -- callbacks may start new animations, so the ones due are collected before any of them runs
  local due = {}
  for sub in pairs(clock.subs) do
    if awake(sub) and sub.due <= now then
      table.insert(due, sub)
    end
  end
  for _, sub in ipairs(due) do
    if clock.subs[sub] then
      run(sub, now)
    end
  end
  arm()
end

local function handle_for(sub)
  local handle = {}
  function handle:stop()
    if sub then
      clock.subs[sub] = nil
    end
  end
  function handle:running()
    return sub ~= nil and clock.subs[sub] ~= nil
  end
  return handle
end

local function subscribe(sub)
  clock.subs[sub] = true
  arm()
  return handle_for(sub)
end

--- Runs on_frame(eased, raw) from 0 to 1 over duration ms, then on_done.
---@param opts { duration?: integer, easing?: string, frame_ms?: integer, on_frame: fun(eased: number, raw: number), on_done?: fun() }
---@return table handle with stop() and running()
function M.tween(opts)
  local duration = opts.duration or 300
  local easing = opts.easing or "out_cubic"

  if not M.enabled() or replaying() or duration <= 0 then
    opts.on_frame(1, 1)
    if opts.on_done then
      opts.on_done()
    end
    return handle_for(nil)
  end

  local started = vim.uv.now()
  local frame_ms = opts.frame_ms or M.FRAME_MS
  opts.on_frame(actions.ease(easing, 0), 0)

  return subscribe({
    interval = frame_ms,
    due = actions.next_beat(started, clock.epoch, frame_ms),
    step = function(now)
      local raw = actions.progress(now - started, duration)
      opts.on_frame(actions.ease(easing, raw), raw)
      if raw < 1 then
        return true
      end
      if opts.on_done then
        opts.on_done()
      end
      return false
    end,
  })
end

--- An ambient loop that ticks with the milliseconds since it began, until stopped or on_tick
--- returns false.
---@param opts { interval?: integer, on_tick: fun(elapsed: integer): boolean|nil }
---@return table handle with stop() and running()
function M.loop(opts)
  -- no early bail on enabled(), the UI may not be attached yet while init.lua runs
  local started = vim.uv.now()
  return subscribe({
    ambient = true,
    interval = opts.interval or 50,
    due = started,
    step = function(now)
      return opts.on_tick(now - started) ~= false
    end,
  })
end

-- fades one highlight group's colors toward new attrs, cancelling any fade already running on it
local group_fades = {}
function M.fade_hl(name, target, opts)
  opts = opts or {}
  if group_fades[name] then
    group_fades[name]:stop()
  end
  local from = vim.api.nvim_get_hl(0, { name = name, link = false })
  target = vim.deepcopy(target)
  for _, key in ipairs({ "fg", "bg", "sp" }) do
    if type(target[key]) == "string" then
      target[key] = actions.to_int(target[key])
    end
  end
  group_fades[name] = M.tween({
    duration = opts.duration or 160,
    easing = opts.easing or "out_cubic",
    on_frame = function(t)
      vim.api.nvim_set_hl(0, name, actions.mix_hl(from, target, t))
    end,
  })
end

function M.toggle()
  vim.g.eldentree_motion = vim.g.eldentree_motion == false
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeMotion", modeline = false })
  local words = require("core.franchise").current().words
  vim.notify(
    vim.g.eldentree_motion and words.motion_on or words.motion_off,
    vim.log.levels.INFO,
    { title = "Eldentree" }
  )
end

-- the plugins that animate on their own (snacks scroll and indent, mini.animate, the smear
-- trail) follow the same switch, so <leader>um and an expedition still everything at once
local function follow_plugins()
  local on = vim.g.eldentree_motion ~= false
  vim.g.snacks_animate = on
  vim.g.minianimate_disable = not on
  -- only when smear already loaded, requiring it here would load the plugin early
  local smear = package.loaded["smear_cursor"]
  if smear then
    smear.enabled = on
  end
end

local function set_focus(value)
  return function()
    focused = value
    arm()
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_motion", { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = set_focus(false) })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = set_focus(true) })
  -- loops subscribed before the UI attached, or while motion was off, start ticking here
  vim.api.nvim_create_autocmd("UIEnter", { group = group, callback = arm })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "EldentreeMotion",
    callback = function()
      follow_plugins()
      arm()
    end,
  })
  -- smear and mini.animate load late, a switch set before they arrived reaches them here
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = follow_plugins,
  })
  vim.api.nvim_create_user_command("Motion", M.toggle, { desc = "Toggle Eldentree animations" })
end

return M
