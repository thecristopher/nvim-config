-- Music: what is playing in Cider (any OS, through its local REST API) or Music.app (macOS, through
-- AppleScript), and the commands that drive them. Pure building and parsing only, so it can be
-- tested headless without either player open.
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
  table.insert(cmd, M.CIDER_URL .. "/" .. route)
  return cmd
end

--- Fills the size placeholders Apple Music leaves in artwork URLs.
---@param url string
---@param size integer pixels per side
---@return string
function M.cover_url(url, size)
  return (url:gsub("{w}", tostring(size)):gsub("{h}", tostring(size)))
end

local function decode(body)
  if not body or body == "" then return nil end
  local ok, data = pcall(vim.json.decode, body)
  if not ok or type(data) ~= "table" or data.status ~= "ok" then return nil end
  return data
end

--- Reads Cider's `/is-playing` answer.
---@param body string|nil
---@return boolean|nil playing, nil when Cider did not answer
function M.parse_cider_playing(body)
  local data = decode(body)
  if not data then return nil end
  return data.is_playing == true
end

--- Reads Cider's `/now-playing` answer into a track.
---@param body string|nil
---@param playing boolean
---@return { title: string, artist: string, album: string, cover: string|nil, playing: boolean }|nil track, nil when nothing is loaded
function M.parse_cider_track(body, playing)
  local data = decode(body)
  local info = data and data.info
  if type(info) ~= "table" or not info.name then return nil end
  local artwork = type(info.artwork) == "table" and info.artwork.url or nil
  return {
    title   = info.name,
    artist  = info.artistName or "",
    album   = info.albumName or "",
    cover   = artwork and M.cover_url(artwork, COVER_PIXELS) or nil,
    playing = playing,
  }
end

-- AppleScript would launch Music.app just to answer, so every script asks first if it is running
local MUSIC_STATUS = [[
if application "Music" is running then
  tell application "Music"
    if player state is stopped then return "stopped"
    set this_track to current track
    return (player state as text) & tab & (name of this_track) & tab & (artist of this_track) & tab & (album of this_track)
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
  if not command then return nil end
  return { "osascript", "-e", ('if application "Music" is running then tell application "Music" to %s'):format(command) }
end

--- Reads the answer of the Music.app status script into a track.
---@param stdout string|nil
---@return { title: string, artist: string, album: string, playing: boolean }|nil track, nil when closed or stopped
function M.parse_music(stdout)
  -- only the newline goes, a full trim would eat the tab before an empty album
  local answer = (stdout or ""):gsub("\r?\n$", "")
  local state, title, artist, album = answer:match("^(%S+)\t(.-)\t(.-)\t(.*)$")
  if not state or title == "" then return nil end
  return { title = title, artist = artist, album = album, playing = state == "playing" }
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

--- Reads the image extension at the end of a cover URL.
---@param url string
---@return string jpg when the URL does not say
function M.url_extension(url)
  local extension = url:match("%.(%a+)$")
  return extension and extension:lower() or "jpg"
end

--- Turns the format AppleScript reports for a cover into a file extension.
---@param format string|nil like "«class PNG »" or "JPEG picture"
---@return string|nil
function M.cover_extension(format)
  format = (format or ""):upper()
  if format:find("PNG", 1, true) then return "png" end
  if format:find("JPEG", 1, true) or format:find("JPG", 1, true) then return "jpg" end
  return nil
end

--- Names the cached cover of a track, shared by every song of the same album.
---@param track { artist: string, album: string, title: string }
---@return string
function M.cover_name(track)
  local album = track.album ~= "" and track.album or track.title
  return "cover_" .. require("core.utils").hash(track.artist .. "|" .. album)
end

-- cuts text to a width in characters, marking the cut
local function fit(text, width)
  if vim.fn.strchars(text) <= width then return text end
  return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

--- Builds the statusline text for a track, cut to fit.
---@param track { title: string, artist: string, playing: boolean }|nil
---@param max_width integer
---@return string empty when nothing is playing
function M.label(track, max_width)
  if not track then return "" end
  local icon = track.playing and "󰎈" or "󰏤"
  local text = track.artist ~= "" and ("%s · %s"):format(track.artist, track.title) or track.title
  return icon .. " " .. fit(text, max_width)
end

M.PANEL_WIDTH = 46
-- terminal cells are about twice as tall as wide, so 12 by 6 reads as a square
local COVER = { row = 0, col = 1, width = 12, height = 6 }
local TEXT_COL = COVER.col + COVER.width + 2
local SOURCES = { cider = "Cider", music = "Music" }

--- Lays out the now playing panel: details beside the cover, the controls under both.
---@param track { title: string, artist: string, album: string, playing: boolean }
---@param source string|nil "cider" or "music"
---@return { lines: string[], marks: { row: integer, col: integer, group: string }[], cover: table }
function M.panel(track, source)
  local room = M.PANEL_WIDTH - TEXT_COL - 1
  local state = track.playing and "󰐊 Playing" or "󰏤 Paused"
  if SOURCES[source] then state = state .. " in " .. SOURCES[source] end
  local details = {
    { fit(track.title, room), "EldenMusicTitle" },
    { fit(track.artist, room), "EldenMusicArtist" },
    { fit(track.album, room), "EldenMusicAlbum" },
    { "", "EldenMusicAlbum" },
    { state, "EldenMusicState" },
  }

  local pad = (" "):rep(TEXT_COL)
  local lines, marks = {}, {}
  for row = 1, COVER.height do
    local detail = details[row]
    lines[row] = detail and pad .. detail[1] or ""
    if detail then table.insert(marks, { row = row - 1, col = TEXT_COL, group = detail[2] }) end
  end
  table.insert(lines, "")
  local toggle = track.playing and "󰏤 p pause" or "󰐊 p play "
  table.insert(lines, " 󰒮 b back    " .. toggle .. "   󰒭 n next    q close")
  table.insert(marks, { row = #lines - 1, col = 0, group = "EldenMusicKeys" })
  return { lines = lines, marks = marks, cover = COVER }
end

return M
