-- The soundtrack of the run: shows what Cider or Apple Music plays in the statusline and drives
-- play/pause, next and previous from a panel with the album cover. Cider is asked first because it
-- runs on every OS, Apple Music after it on macOS and Windows. `vim.g.eldentree_music = false`
-- turns it off, `vim.g.eldentree_cider_token` carries Cider's API token when its auth is on.
-- A new song tints the music groups after its cover, says its name in a quiet notice and fires
-- `User EldentreeMusicChanged`, and while the panel is closed the statusline sings its lyrics.
local actions = require("core.music.actions")
local panel = require("core.music.panel")
local ticker = require("core.music.ticker")
local tint = require("core.music.tint")

local M = {}

local POLL_MS = 3000
local MAX_TEXT = 40
-- the players answer for the first time a moment after startup, that song is not news
local STARTUP_MS = 10000
local NOTICE_ID = "eldentree_music_notice"
local apple = actions.apple_music(require("core.utils").platform())

local timer
local polling = false
local now = { source = nil, track = nil, label = "", polled_at = 0 }
local warned_token = false
local focused = true
-- the song playing now and the last one heard, nil before any song was
local song = { key = nil, last = nil }
local started_at = vim.uv.now()

local function enabled()
  return vim.g.eldentree_music ~= false
end

local function refresh_statusline()
  require("core.utils").refresh_statusline()
end

local function run(cmd, on_done)
  local ok = pcall(
    vim.system,
    cmd,
    { text = true },
    vim.schedule_wrap(function(result)
      on_done(result.code == 0 and result.stdout or nil)
    end)
  )
  -- curl, osascript or powershell missing on this machine reads as a closed player
  if not ok then
    on_done(nil)
  end
end

local function announce(track)
  local lore = require("core.franchise").current()
  vim.notify(actions.notice(track, lore.skin.music.divider.gem), vim.log.levels.INFO, {
    -- skipping through songs replaces the notice in place instead of stacking one per song
    id = NOTICE_ID,
    title = lore.music.now_playing,
    timeout = 2500,
  })
end

local function hud_visible()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "eldentree_hud" then
      return true
    end
  end
  return false
end

-- the panel and the HUD's player already name the song, and the first answers after startup are
-- what was playing all along
local function song_on_screen()
  return panel.is_open() or hud_visible() or vim.uv.now() - started_at < STARTUP_MS
end

-- the karaoke timer runs only while a song plays and someone looks at the editor
local function follow_ticker()
  if focused and now.track and now.track.playing then
    return ticker.start()
  end
  ticker.stop()
end

local history_file = vim.fn.stdpath("state") .. "/eldentree_music.json"

-- every new song heard while working counts one play toward the year card
local function count_play(key, track)
  if not key or not track.playing then
    return
  end
  local history = require("core.music.actions.history")
  local ok, lines = pcall(vim.fn.readfile, history_file)
  local decoded_ok, store = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  store = (decoded_ok and type(store) == "table") and store or {}
  history.record(store, tostring(os.date("%Y")), key, track)
  require("core.utils").write_state(history_file, { vim.json.encode(store) })
end

-- a new song (or the silence after one) tints the groups, may be announced and tells the HUD
local function follow_song(source, track)
  local key = actions.track_key(track)
  if key == song.key then
    return
  end
  song.key = key
  count_play(key, track)
  tint.follow(track, source)
  if actions.announces(song.last, key, focused, song_on_screen()) then
    announce(track)
  end
  song.last = key or song.last
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeMusicChanged", modeline = false })
end

local function show(source, track, asked_at)
  polling = false
  follow_song(source, track)
  now.source, now.track = source, track
  -- the player read its position somewhere between the question and the answer, the middle is
  -- the best guess, and the lyrics count the seconds from there until the next answer
  local answered = vim.uv.now()
  now.polled_at = asked_at and (asked_at + answered) / 2 or answered
  follow_ticker()
  local label = actions.label(track, MAX_TEXT)
  if label == now.label then
    return
  end
  now.label = label
  refresh_statusline()
  panel.update(track, source)
end

local function ask_music()
  if not apple then
    return show(nil, nil)
  end
  local asked_at = vim.uv.now()
  run(apple.status(), function(stdout)
    local track = actions.parse_music(stdout)
    show(track and "music" or nil, track, asked_at)
  end)
end

-- a refused token looks just like a closed Cider from the statusline, so it gets said once
local function warn_refused(status)
  if warned_token or not actions.cider_refused(status) then
    return
  end
  warned_token = true
  vim.notify(
    "Cider refused the token, set vim.g.eldentree_cider_token or turn its auth off",
    vim.log.levels.WARN,
    { title = "Music" }
  )
end

local function ask_cider()
  local token = vim.g.eldentree_cider_token
  run(actions.cider_command("is-playing", "GET", token), function(stdout)
    local body, status = actions.cider_answer(stdout)
    warn_refused(status)
    local playing = actions.parse_cider_playing(body)
    if playing == nil then
      return ask_music()
    end
    local asked_at = vim.uv.now()
    run(actions.cider_command("now-playing", "GET", token), function(track_stdout)
      local track = actions.parse_cider_track(actions.cider_answer(track_stdout), playing)
      if not track then
        return ask_music()
      end
      show("cider", track, asked_at)
    end)
  end)
end

--- Asks the players what is playing and updates the statusline when it changed.
function M.poll()
  if polling then
    return
  end
  if not enabled() then
    return show(nil, nil)
  end
  polling = true
  ask_cider()
end

--- Sends play/pause, next or previous to whichever player answered last.
---@param control string one of actions.CONTROLS
function M.control(control)
  if not vim.tbl_contains(actions.CONTROLS, control) then
    return vim.notify("Unknown control: " .. control, vim.log.levels.WARN, { title = "Music" })
  end
  -- the players take a moment to switch tracks before they report the new one
  local function poll_soon()
    vim.defer_fn(M.poll, 400)
  end
  if now.source == "music" and apple then
    return run(apple.control(control), poll_soon)
  end

  run(actions.cider_command(control, "POST", vim.g.eldentree_cider_token), function(stdout)
    if actions.cider_answer(stdout) or not apple then
      return poll_soon()
    end
    run(apple.control(control), poll_soon)
  end)
end

--- Opens the now playing panel with the cover and the controls.
function M.open()
  if not require("core.music.actions.panel").fits(vim.o.columns) then
    return vim.notify("The editor is too narrow for the music panel", vim.log.levels.INFO, {
      title = "Music",
    })
  end
  if not now.track then
    return vim.notify(
      "Nothing is playing in Cider or Apple Music",
      vim.log.levels.INFO,
      { title = "Music" }
    )
  end
  panel.open(now.track, now.source)
end

--- How many seconds into the song the player is right now, counting since the last answer.
---@return number|nil nil when nothing plays or the player did not say
function M.elapsed()
  local track = now.track
  if not track or not track.position then
    return nil
  end
  if not track.playing then
    return track.position
  end
  return track.position + (vim.uv.now() - now.polled_at) / 1000
end

--- What is playing right now, for the HUD and the tint.
---@return table|nil track nil when nothing plays
---@return string|nil source "cider" or "music"
function M.now_playing()
  return now.track, now.source
end

--- The statusline piece: the line being sung while lyrics show and the panel is closed, otherwise
--- icon, artist and title, empty when nothing plays.
---@return string
function M.statusline()
  local line = ticker.line()
  if line then
    return actions.lyric_label(line, MAX_TEXT)
  end
  return now.label
end

local function start()
  if not timer then
    timer = vim.uv.new_timer()
  end
  timer:start(0, POLL_MS, vim.schedule_wrap(M.poll))
end

local function stop()
  if timer then
    timer:stop()
  end
end

function M.setup()
  panel.setup()
  tint.setup()
  require("core.music.duck").setup()
  start()
  -- nobody reads the statusline while nvim is in the background, so the players get a rest too
  local group = vim.api.nvim_create_augroup("eldentree_music", { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      focused = false
      stop()
      follow_ticker()
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      focused = true
      start()
      follow_ticker()
    end,
  })

  vim.api.nvim_create_user_command("Music", function(opts)
    M.control(opts.args ~= "" and opts.args or "playpause")
  end, {
    nargs = "?",
    complete = function()
      return actions.CONTROLS
    end,
    desc = "Play/pause, next or previous in Cider or Apple Music",
  })
end

return M
