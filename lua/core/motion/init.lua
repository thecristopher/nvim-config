-- The heartbeat behind every Eldentree animation. One switch (vim.g.eldentree_motion = false
-- or <leader>um) stills everything, and ambient loops sleep while the terminal is unfocused.
local actions = require("core.motion.actions")

local M = {}

M.FRAME_MS = 16

local focused = true

function M.enabled()
  return vim.g.eldentree_motion ~= false and not vim.g.vscode and #vim.api.nvim_list_uis() > 0
end

local function new_handle(timer)
  local handle = { timer = timer }
  function handle:stop()
    if self.timer and not self.timer:is_closing() then
      self.timer:stop()
      self.timer:close()
    end
    self.timer = nil
  end
  function handle:running()
    return self.timer ~= nil
  end
  return handle
end

-- runs on_frame(eased, raw) from 0 to 1 over duration ms, then on_done
function M.tween(opts)
  local duration = opts.duration or 300
  local easing = opts.easing or "out_cubic"

  if not M.enabled() or duration <= 0 then
    opts.on_frame(1, 1)
    if opts.on_done then
      opts.on_done()
    end
    return new_handle(nil)
  end

  local started = vim.uv.now()
  local handle = new_handle(vim.uv.new_timer())
  opts.on_frame(actions.ease(easing, 0), 0)

  handle.timer:start(
    opts.frame_ms or M.FRAME_MS,
    opts.frame_ms or M.FRAME_MS,
    vim.schedule_wrap(function()
      if not handle:running() then
        return
      end
      local raw = actions.progress(vim.uv.now() - started, duration)
      local ok, err = pcall(opts.on_frame, actions.ease(easing, raw), raw)
      if not ok or raw >= 1 then
        handle:stop()
        if not ok then
          vim.notify(err, vim.log.levels.ERROR, { title = "Eldentree motion" })
        end
        if ok and opts.on_done then
          opts.on_done()
        end
      end
    end)
  )
  return handle
end

-- an ambient loop that ticks forever with the milliseconds since it began, until stopped
function M.loop(opts)
  -- no early bail on enabled(), the UI may not be attached yet while init.lua runs
  local handle = new_handle(nil)
  local started = vim.uv.now()
  handle.timer = vim.uv.new_timer()
  handle.timer:start(
    0,
    opts.interval or 50,
    vim.schedule_wrap(function()
      if not handle:running() then
        return
      end
      if not focused or not M.enabled() then
        return
      end
      local ok, keep_going = pcall(opts.on_tick, vim.uv.now() - started)
      if not ok or keep_going == false then
        handle:stop()
        if not ok then
          vim.notify(keep_going, vim.log.levels.ERROR, { title = "Eldentree motion" })
        end
      end
    end)
  )
  return handle
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

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_motion", { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      focused = false
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      focused = true
    end,
  })
  vim.api.nvim_create_user_command("Motion", M.toggle, { desc = "Toggle Eldentree animations" })
end

return M
