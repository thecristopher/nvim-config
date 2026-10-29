-- back-to-basics inside Eldentree: the franchise picks the coach, the HUD portrait draws them,
-- the franchise sounds and banners celebrate the solves, and the HUD carries the lessons.
local actions = require("core.btb.actions")

local M = {}

local lessons = {}
-- the last User BtbAhead, what btb gets ready in the background for the statusline
local ahead = nil
-- the stage window showing the coach, so a stage closing right before the next one opens
-- does not bring the HUD's portrait back in between
local stage_win = nil

local function plugin()
  local ok, btb = pcall(require, "back-to-basics")
  return ok and btb or nil
end

---The coach of today's franchise.
---@return string|nil
function M.persona()
  return actions.persona_of(require("core.franchise").current())
end

local function draw_portrait(win, file)
  if stage_win ~= win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local anchor =
    actions.portrait_anchor(vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win))
  require("core.hud.portrait").show(win, file, anchor, "btb")
end

local function stage_closed(win)
  if stage_win ~= win then
    return
  end
  stage_win = nil
  require("core.hud.portrait").close("btb")
  vim.defer_fn(function()
    if stage_win == nil then
      require("core.hud").hide_portrait(false)
    end
  end, 150)
end

---Draws the coach's portrait in the stage's portrait window, and takes it away with the stage.
---The HUD's own portrait steps aside meanwhile, the terminal would paint it over the stage.
---@param _ integer buffer of the portrait window
---@param win integer
---@param persona { portrait?: string }
function M.portrait(_, win, persona)
  local file = actions.portrait_file(vim.fn.stdpath("config"), persona)
  if not file then
    return
  end
  stage_win = win
  require("core.hud").hide_portrait(true)
  -- the image goes out once the stage is on screen, sent before that it can land nowhere
  vim.defer_fn(function()
    draw_portrait(win, file)
  end, 60)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      stage_closed(win)
    end,
  })
end

---Plays the franchise sound that fits a coach event.
---@param event string
function M.sound(event)
  local sounds = actions.sound_for(event)
  if sounds then
    require("core.sound").play_first(sounds)
  end
end

---Refreshes the lessons the HUD shows, in the background.
function M.refresh()
  local btb = plugin()
  if not btb then
    return
  end
  btb.btb({ "lessons" }, function(data)
    lessons = data.lessons or {}
  end)
end

local function read_lesson(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  return ok and lines or {}
end

---The lessons fought so far as HUD items: use has the coach explain it again, check reads it.
---@param limit? integer
---@return table[]
function M.hud_items(limit)
  return vim.tbl_map(function(entry)
    local fields = actions.hud_fields(entry)
    return vim.tbl_extend("force", fields, {
      icon_hl = "EldenMessage",
      use = function()
        require("back-to-basics").subcommands.brief({ entry.id })
      end,
      check = function()
        return read_lesson(entry.lesson)
      end,
    })
  end, actions.hud_lessons(lessons, limit or 12))
end

---The statusline piece for the next exercise getting ready, empty when nothing is.
---@return string
function M.statusline()
  return actions.ahead_text(ahead)
end

local function refresh_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh({ place = { "statusline" } })
  end
end

local function celebrate(result)
  local fanfare = actions.celebration(result)
  if fanfare.banner then
    require("core.banner").show(fanfare.banner, { reward = false, subtitle = fanfare.subtitle })
  end
  if fanfare.runes > 0 then
    require("core.runes").award(fanfare.runes)
  end
end

---Celebrates every solve, keeps the HUD's lessons fresh and the statusline on what gets ready ahead.
function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_btb", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "BtbResult",
    callback = function(event)
      celebrate(event.data)
      M.refresh()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "BtbAhead",
    callback = function(event)
      ahead = event.data
      refresh_statusline()
    end,
  })
  M.refresh()
end

return M
