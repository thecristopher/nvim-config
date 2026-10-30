-- The soundtrack of the run: shows what Cider or Apple Music plays in the statusline and drives
-- play/pause, next and previous from a panel with the album cover. Cider is asked first because it
-- runs on every OS, Apple Music after it on macOS and Windows. `vim.g.eldentree_music = false`
-- turns it off, `vim.g.eldentree_cider_token` carries Cider's API token when its auth is on.
local actions = require("core.music.actions")
local panel = require("core.music.panel")

local M = {}

local POLL_MS = 3000
local MAX_TEXT = 40
local apple = actions.apple_music(require("core.utils").platform())

local timer
local polling = false
local now = { source = nil, track = nil, label = "", polled_at = 0 }
local warned_token = false

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

local function show(source, track, asked_at)
  polling = false
  now.source, now.track = source, track
  -- the player read its position somewhere between the question and the answer, the middle is
  -- the best guess, and the lyrics count the seconds from there until the next answer
  local answered = vim.uv.now()
  now.polled_at = asked_at and (asked_at + answered) / 2 or answered
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

--- The statusline piece: icon, artist and title, empty when nothing plays.
---@return string
function M.statusline()
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
  start()
  -- nobody reads the statusline while nvim is in the background, so the players get a rest too
  local group = vim.api.nvim_create_augroup("eldentree_music", { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = stop })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = start })

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
