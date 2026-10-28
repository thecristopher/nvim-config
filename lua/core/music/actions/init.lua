-- Music: what is playing in Cider (any OS, through its local REST API) or Apple Music (AppleScript
-- on macOS, the system media controls on Windows), and the commands that drive them. Pure building
-- and parsing only, so it can be tested headless without either player open.
local M = {}

M.CIDER_URL = "http://localhost:10767/api/v1/playback"

-- big enough for real pixels in the panel, small enough to download in a blink
local COVER_PIXELS = 300

-- the controls both players understand, named the way Cider's routes name them
M.CONTROLS = { "playpause", "next", "previous" }

local MUSIC_COMMANDS = { playpause = "playpause", next = "next track", previous = "previous track" }

--- Builds the curl call for one Cider route.
---@param route string like "now-playing" or "next"
---@param method "GET"|"POST"
---@param token string|nil from Settings > Connectivity in Cider, nil when auth is off
---@return string[]
function M.cider_command(route, method, token)
  -- a closed Cider refuses at once, a frozen one should not hold the statusline for long
  local cmd = { "curl", "-s", "--max-time", "1", "-X", method }
  if token and token ~= "" then
    -- the docs say apptoken and some clients send apitoken, both cost nothing
    vim.list_extend(cmd, { "-H", "apptoken: " .. token, "-H", "apitoken: " .. token })
  end
  -- the status code goes on its own last line, so a refused token can be told from a closed Cider
  vim.list_extend(cmd, { "-w", "\n%{http_code}", M.CIDER_URL .. "/" .. route })
  return cmd
end

--- Splits what curl printed for a Cider route into the body and the HTTP status.
---@param stdout string|nil
---@return string|nil body, nil unless Cider answered with a 2xx
---@return integer|nil status, nil when Cider did not answer at all
function M.cider_answer(stdout)
  local body, status = (stdout or ""):match("^(.*)\n(%d%d%d)%s*$")
  status = tonumber(status)
  if not status or status == 0 then
    return nil, nil
  end
  if status < 200 or status > 299 then
    return nil, status
  end
  return body, status
end

--- Tells whether Cider turned the request away for a missing or wrong token.
---@param status integer|nil from cider_answer
---@return boolean
function M.cider_refused(status)
  return status == 401 or status == 403
end

--- Fills the size placeholders Apple Music leaves in artwork URLs.
---@param url string
---@param size integer pixels per side
---@return string
function M.cover_url(url, size)
  return (url:gsub("{w}", tostring(size)):gsub("{h}", tostring(size)))
end

local function decode(body)
  if not body or body == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, body)
  if not ok or type(data) ~= "table" or data.status ~= "ok" then
    return nil
  end
  return data
end

--- Reads Cider's `/is-playing` answer.
---@param body string|nil
---@return boolean|nil playing, nil when Cider did not answer
function M.parse_cider_playing(body)
  local data = decode(body)
  if not data then
    return nil
  end
  return data.is_playing == true
end

--- Reads Cider's `/now-playing` answer into a track.
---@param body string|nil
---@param playing boolean
---@return { title: string, artist: string, album: string, cover: string|nil, playing: boolean, position: number|nil, duration: number|nil }|nil track, nil when nothing is loaded
function M.parse_cider_track(body, playing)
  local data = decode(body)
  local info = data and data.info
  if type(info) ~= "table" or not info.name then
    return nil
  end
  local artwork = type(info.artwork) == "table" and info.artwork.url or nil
  return {
    title = info.name,
    artist = info.artistName or "",
    album = info.albumName or "",
    cover = artwork and M.cover_url(artwork, COVER_PIXELS) or nil,
    playing = playing,
    position = tonumber(info.currentPlaybackTime),
    duration = tonumber(info.durationInMillis) and info.durationInMillis / 1000 or nil,
  }
end

-- AppleScript would launch Music.app just to answer, so every script asks first if it is running
local MUSIC_STATUS = [[
if application "Music" is running then
  tell application "Music"
    if player state is stopped then return "stopped"
    set this_track to current track
    return (player state as text) & tab & (player position as text) & tab & (duration of this_track as text) & tab & (name of this_track) & tab & (artist of this_track) & tab & (album of this_track)
  end tell
end if
return "closed"]]

--- Builds the osascript call that asks Music.app what is playing.
---@return string[]
function M.music_status_command()
  return { "osascript", "-e", MUSIC_STATUS }
end

--- Builds the osascript call for one control, ignored when Music.app is closed.
---@param control string one of M.CONTROLS
---@return string[]|nil
function M.music_control_command(control)
  local command = MUSIC_COMMANDS[control]
  if not command then
    return nil
  end
  return {
    "osascript",
    "-e",
    ('if application "Music" is running then tell application "Music" to %s'):format(command),
  }
end

-- AppleScript writes numbers the way the system locale does, so 12,5 has to read as 12.5
local function locale_number(text)
  return tonumber((text:gsub(",", ".")))
end

--- Reads the answer of the Music.app status script into a track.
---@param stdout string|nil
---@return { title: string, artist: string, album: string, playing: boolean, position: number|nil, duration: number|nil }|nil track, nil when closed or stopped
function M.parse_music(stdout)
  -- only the newline goes, a full trim would eat the tab before an empty album
  local answer = (stdout or ""):gsub("\r?\n$", "")
  local state, position, duration, title, artist, album =
    answer:match("^(%S+)\t(.-)\t(.-)\t(.-)\t(.-)\t(.*)$")
  if not state or title == "" then
    return nil
  end
  return {
    title = title,
    artist = artist,
    album = album,
    playing = state == "playing",
    position = locale_number(position),
    duration = locale_number(duration),
  }
end

-- writes the cover's raw bytes to %s and answers with its format, empty when the song has none
local MUSIC_COVER = [[
if application "Music" is running then
  tell application "Music"
    if player state is stopped then return ""
    if (count of artworks of current track) is 0 then return ""
    set art to artwork 1 of current track
    set fmt to (format of art) as text
    set raw to raw data of art
  end tell
  set f to open for access POSIX file "%s" with write permission
  set eof f to 0
  write raw to f
  close access f
  return fmt
end if
return ""]]

--- Builds the osascript call that saves Music.app's current cover to a file.
---@param path string where the cover lands
---@return string[]
function M.music_cover_command(path)
  local quoted = path:gsub("\\", "\\\\"):gsub('"', '\\"')
  return { "osascript", "-e", MUSIC_COVER:format(quoted) }
end

--- Picks the commands that reach Apple Music on this OS: AppleScript on macOS, the system media
--- controls on Windows.
---@param platform string from core.utils.platform
---@return { status: fun(): string[], control: fun(control: string): string[]|nil, cover: fun(path: string): string[] }|nil apple, nil where Apple Music cannot be reached
function M.apple_music(platform)
  if platform == "mac" then
    return {
      status = M.music_status_command,
      control = M.music_control_command,
      cover = M.music_cover_command,
    }
  end
  if platform == "windows" then
    local windows = require("core.music.actions.windows")
    return {
      status = windows.status_command,
      control = windows.control_command,
      cover = windows.cover_command,
    }
  end
  return nil
end

--- Reads the image extension at the end of a cover URL.
---@param url string
---@return string jpg when the URL does not say
function M.url_extension(url)
  local extension = url:match("%.(%a+)$")
  return extension and extension:lower() or "jpg"
end

--- Turns the format a player reports for a cover into a file extension.
---@param format string|nil like "«class PNG »", "JPEG picture" or "image/png"
---@return string|nil
function M.cover_extension(format)
  format = (format or ""):upper()
  if format:find("PNG", 1, true) then
    return "png"
  end
  if format:find("JPEG", 1, true) or format:find("JPG", 1, true) then
    return "jpg"
  end
  return nil
end

--- Names the cached cover of a track, shared by every song of the same album.
---@param track { artist: string, album: string, title: string }
---@return string
function M.cover_name(track)
  local album = track.album ~= "" and track.album or track.title
  return "cover_" .. require("core.utils").hash(track.artist .. "|" .. album)
end

--- Builds the statusline text for a track, cut to fit.
---@param track { title: string, artist: string, playing: boolean }|nil
---@param max_width integer
---@return string empty when nothing is playing
function M.label(track, max_width)
  if not track then
    return ""
  end
  local icon = track.playing and "󰎈" or "󰏤"
  local text = track.artist ~= "" and ("%s · %s"):format(track.artist, track.title) or track.title
  return icon .. " " .. require("core.music.actions.panel").fit(text, max_width)
end

return M
