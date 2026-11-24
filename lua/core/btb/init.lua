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
  local lore = require("core.franchise").current()
  return actions.coach_of(require("core.themes").current(), lore.title, lore.coach)
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
  local file =
    actions.portrait_file(require("core.utils").root(), persona, require("core.themes").current())
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

-- the day the coach last asked whether you are ready, so the stage only asks the first time
local asked_on = nil

-- what the coach says out loud at a coach event, over the stage that already shows her words
local function speak(event)
  local today = os.date("%Y-%m-%d")
  if event == "coach_open" and asked_on ~= today then
    asked_on = today
    return require("core.voice").say("lesson_started", nil, { quiet = true })
  end
  if event == "hint" then
    return require("core.voice").say("hint", nil, { quiet = true })
  end
  return false
end

---Plays the franchise sound that fits a coach event, unless the coach is talking: the voice goes
---first and a bell or a summon clip never crosses it.
---@param event string
function M.sound(event)
  speak(event)
  local sound = require("core.sound")
  local sounds = actions.sound_for(event, sound.speaking())
  if sounds then
    sound.play_first(sounds)
  end
end

---btb's sound hook: every coach event and moment, except the ones another event already voices.
---@param event string
function M.on_sound(event)
  if actions.hook_plays(event) then
    M.sound(event)
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

-- clean solves in a row today, the coach counts them out loud. Kept on disk so closing nvim
-- between exercises does not break the run
local streak_file = vim.fn.stdpath("state") .. "/eldentree_btb_streak"

local function solve_moment(result)
  local today = os.date("%Y-%m-%d")
  local ok, lines = pcall(vim.fn.readfile, streak_file, "", 1)
  local moment, run =
    actions.solve_moment(result, actions.saved_streak(ok and lines[1] or nil, today))
  require("core.utils").write_state(streak_file, { today .. " " .. run })
  return moment
end

local function celebrate(result)
  local fanfare = actions.celebration(result)
  local moment = solve_moment(result)
  if moment then
    require("core.voice").say(moment)
  end
  if fanfare.banner then
    require("core.banner").show(fanfare.banner, { reward = false, subtitle = fanfare.subtitle })
  end
  -- a lesson belongs to the coach, the merchant never talks over it
  if fanfare.runes > 0 then
    require("core.runes").award(fanfare.runes, { merchant = false })
  end
end

local path_ns = vim.api.nvim_create_namespace("eldentree_btb_path")

-- a float of rooms like the path and the concepts, Enter does what the map is for
local function show_rooms(map)
  local width = 0
  for _, line in ipairs(map.lines) do
    width = math.max(width, vim.api.nvim_strwidth(line) + 2)
  end
  width = math.max(width, #map.footer + 4)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, map.lines)
  for _, mark in ipairs(map.marks) do
    vim.api.nvim_buf_set_extmark(buf, path_ns, mark.row, mark.col, {
      end_col = mark.end_col,
      hl_group = mark.group,
    })
  end
  vim.bo[buf].modifiable = false
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = require("core.skin").border(),
    width = math.min(width, vim.o.columns - 4),
    height = math.min(#map.lines, vim.o.lines - 6),
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
    title = " " .. require("core.skin").title(map.title) .. " ",
    title_pos = "center",
    footer = " " .. map.footer .. " ",
    footer_pos = "center",
  })
  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end
  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    close()
    map.on_enter(row)
  end, { buffer = buf, nowait = true })
end

local function show_path(status)
  local lines, marks = actions.path_map(status)
  show_rooms({
    lines = lines,
    marks = marks,
    title = require("core.franchise").current().coach.training,
    footer = ("streak %d · %d XP · %d mastered"):format(
      status.streak or 0,
      status.xp or 0,
      status.mastered or 0
    ),
    on_enter = function()
      require("back-to-basics").lesson()
    end,
  })
end

local function show_concepts(status)
  local concepts = status.concepts or {}
  if #concepts == 0 then
    return vim.notify("No concepts fought yet", vim.log.levels.INFO, { title = "btb" })
  end
  local lines, marks, tracks = actions.concept_map(concepts)
  local owned = #vim.tbl_filter(function(row)
    return row.standing == "owned"
  end, concepts)
  show_rooms({
    lines = lines,
    marks = marks,
    title = require("core.franchise").current().coach.concepts,
    footer = ("%d of %d owned · <CR> lessons"):format(owned, #concepts),
    on_enter = function(row)
      require("back-to-basics").lessons(tracks[row])
    end,
  })
end

local function with_status(show)
  local btb = plugin()
  if not btb then
    return vim.notify("back-to-basics is not installed", vim.log.levels.WARN, { title = "btb" })
  end
  btb.btb({ "status" }, function(data)
    if data.error then
      return vim.notify(data.error, vim.log.levels.ERROR, { title = "btb" })
    end
    show(data)
  end)
end

---Opens the path map: every track as a chain of levels, Enter starts the lesson.
function M.path()
  with_status(show_path)
end

---Opens the concept map: every concept fought so far as a room, Enter opens that track's lessons.
function M.concepts()
  with_status(show_concepts)
end

-- an onsite run stages the region's boss on the solution, one hit per test that starts passing.
-- The pass itself is celebrated by BtbResult, so the boss falls without a banner of its own
local function stage_onsite(fight)
  local lore = require("core.franchise").current()
  local boss = require("core.boss.actions").boss_for(require("core.themes").current().name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].btb_exercise == fight.id and vim.b[buf].btb_redo ~= true then
      require("core.boss").stage(buf, {
        name = actions.onsite_name(boss, lore.coach),
        count = fight.remaining,
        peak = fight.total,
        banner = false,
      })
    end
  end
end

---Asked before a hint is revealed: the shop names the price in silence, you buy or leave.
---@param info { id: string, hints_left?: integer, cost?: integer, nudge_ready?: boolean }
---@param buy fun()
function M.before_hint(info, buy)
  local coach = require("core.franchise").current().coach
  local offer = actions.hint_offer(coach, info)
  if not offer then
    return buy()
  end
  vim.ui.select({ coach.buy, coach.leave }, { prompt = offer }, function(choice)
    if choice == coach.buy then
      buy()
    end
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
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "BtbFight",
    callback = function(event)
      stage_onsite(event.data)
    end,
  })
  -- the hint is paid in the franchise's currency too, the XP it costs leaves the purse.
  -- the hook skips the hint, so it is voiced here on every hint bought, coach line or not
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "BtbHint",
    callback = function(event)
      require("core.runes").spend((event.data or {}).cost or 0)
      M.sound("hint")
    end,
  })
  vim.api.nvim_create_user_command("BtbPath", M.path, { desc = "The back-to-basics path as a map" })
  vim.api.nvim_create_user_command(
    "BtbConcepts",
    M.concepts,
    { desc = "The back-to-basics concepts as a map" }
  )
  vim.keymap.set("n", "<leader>km", M.path, { desc = "Path map" })
  vim.keymap.set("n", "<leader>kC", M.concepts, { desc = "Concept map" })
  M.refresh()
end

return M
