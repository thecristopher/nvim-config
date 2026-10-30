-- back-to-basics inside Eldentree: the franchise picks the coach, the HUD portrait draws them,
-- the franchise sounds and banners celebrate the solves, and the HUD carries the lessons.
local actions = require("core.btb.actions")

local M = {}

local lessons = {}
-- what is left of today's training, for the HUD's training key
local day = nil
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
  btb.btb({ "today" }, function(data)
    day = actions.day_status(data)
    require("core.hud").refresh(true)
  end)
end

---What is left of today's training as the HUD reads it, and whether something still waits.
---@return string|nil line nil until btb answers
---@return boolean pending
function M.day()
  return actions.day_line(day), day ~= nil and not day.done
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
  require("core.utils").refresh_statusline()
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

local path_ns = vim.api.nvim_create_namespace("eldentree_btb_path")

local function show_path(status)
  local lines, marks = actions.path_map(status)
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 2)
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(buf, path_ns, mark.row, mark.col, {
      end_col = mark.end_col,
      hl_group = mark.group,
    })
  end
  vim.bo[buf].modifiable = false
  local footer = ("streak %d · %d XP · %d mastered"):format(
    status.streak or 0,
    status.xp or 0,
    status.mastered or 0
  )
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = math.min(math.max(width, #footer + 4), vim.o.columns - 4),
    height = math.min(#lines, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " "
      .. require("core.skin").title(require("core.franchise").current().coach.training)
      .. " ",
    title_pos = "center",
    footer = " " .. footer .. " ",
    footer_pos = "center",
  })
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true })
  end
  vim.keymap.set("n", "<CR>", function()
    pcall(vim.api.nvim_win_close, win, true)
    require("back-to-basics").lesson()
  end, { buffer = buf, nowait = true })
end

---Opens the path map: every track as a chain of levels, Enter starts the lesson.
function M.path()
  local btb = plugin()
  if not btb then
    return vim.notify("back-to-basics is not installed", vim.log.levels.WARN, { title = "btb" })
  end
  btb.btb({ "status" }, function(data)
    if data.error then
      return vim.notify(data.error, vim.log.levels.ERROR, { title = "btb" })
    end
    show_path(data)
  end)
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
  vim.api.nvim_create_user_command("BtbPath", M.path, { desc = "The back-to-basics path as a map" })
  vim.keymap.set("n", "<leader>km", M.path, { desc = "Path map" })
  M.refresh()
end

return M
