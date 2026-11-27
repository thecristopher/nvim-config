-- Progress for anything that takes a while: one notification that stays on screen with a moving
-- bar and the elapsed time until the work ends, so a long wait is never silent or cut short.
local actions = require("core.progress.actions")

local M = {}

---@class EldenProgress
---@field update fun(self: EldenProgress, message?: string, fraction?: number)
---@field done fun(self: EldenProgress, message?: string)
---@field fail fun(self: EldenProgress, message: string)

local function style()
  local ok, franchise = pcall(require, "core.franchise")
  return actions.style(ok and franchise.current().skin or nil)
end

local function stop(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

---Starts a progress notification that redraws itself until done or fail is called.
---@param opts { id: string, title: string, message: string, fraction?: number }
---@return EldenProgress
function M.start(opts)
  local task = {
    id = opts.id,
    title = opts.title,
    message = opts.message,
    fraction = opts.fraction,
    started = vim.uv.now(),
    bar = style(),
  }

  local function draw()
    local width = actions.text_width(vim.o.columns)
    local text =
      actions.text(task.message, task.fraction, vim.uv.now() - task.started, task.bar, width)
    vim.notify(text, vim.log.levels.INFO, { id = task.id, title = task.title, timeout = false })
  end

  local function finish(message, level)
    stop(task.timer)
    task.timer = nil
    local took = actions.elapsed(vim.uv.now() - task.started)
    local text = actions.wrap(("%s (%s)"):format(message, took), actions.text_width(vim.o.columns))
    -- the final word replaces the bar under the same id and fades with the notifier's timeout
    vim.notify(text, level, { id = task.id, title = task.title })
  end

  function task:update(message, fraction)
    self.message = message or self.message
    self.fraction = fraction or self.fraction
    if self.timer then
      draw()
    end
  end

  function task:done(message)
    if self.timer then
      finish(message or self.message, vim.log.levels.INFO)
    end
  end

  function task:fail(message)
    if self.timer then
      finish(message, vim.log.levels.ERROR)
    end
  end

  task.timer = vim.uv.new_timer()
  task.timer:start(
    0,
    actions.FRAME_MS,
    vim.schedule_wrap(function()
      if task.timer then
        draw()
      end
    end)
  )
  return task
end

return M
