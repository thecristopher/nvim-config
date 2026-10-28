-- Apple Music (and iTunes) on Windows, reached through the system media controls the way the
-- media flyout does. Windows PowerShell 5.1 runs the scripts because pwsh 7 dropped the WinRT
-- projection they need. The status script answers in the same shape as the macOS one, so
-- `parse_music` reads both. Pure building only.
local M = {}

-- the system names each player by its app id, Apple Music's carries AppleMusic in it
M.APPS = "AppleMusic|iTunes"

local CONTROL_METHODS = {
  playpause = "TryTogglePlayPauseAsync",
  next = "TrySkipNextAsync",
  previous = "TrySkipPreviousAsync",
}

-- finds the player's session and leaves it in $session, answering "closed" when it is not open
local PREAMBLE = [[
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
function Await($operation, [type]$type) {
  $task = $asTask.MakeGenericMethod($type).Invoke($null, @($operation))
  $task.Wait(-1) | Out-Null
  $task.Result
}
$managerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
$propertiesType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media.Control, ContentType = WindowsRuntime]
$manager = Await ($managerType::RequestAsync()) $managerType
$session = $manager.GetSessions() | Where-Object { $_.SourceAppUserModelId -match 'APPS' } | Select-Object -First 1
if (-not $session) { 'closed'; exit }
]]

local STATUS = [[
$state = $session.GetPlaybackInfo().PlaybackStatus.ToString().ToLower()
if ($state -ne 'playing' -and $state -ne 'paused') { 'stopped'; exit }
$media = Await ($session.TryGetMediaPropertiesAsync()) $propertiesType
$time = $session.GetTimelineProperties()
$invariant = [Globalization.CultureInfo]::InvariantCulture
@($state, $time.Position.TotalSeconds.ToString($invariant), $time.EndTime.TotalSeconds.ToString($invariant), $media.Title, $media.Artist, $media.AlbumTitle) -join "`t"
]]

local CONTROL = [[
Await ($session.METHOD()) ([bool]) | Out-Null
]]

-- writes the cover's bytes to the path and answers with its content type, empty without one
local COVER = [[
$media = Await ($session.TryGetMediaPropertiesAsync()) $propertiesType
if (-not $media.Thumbnail) { ''; exit }
$streamType = [Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType = WindowsRuntime]
$stream = Await ($media.Thumbnail.OpenReadAsync()) $streamType
$source = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream)
$file = [System.IO.File]::Create('PATH')
$source.CopyTo($file)
$file.Close()
$source.Close()
$stream.ContentType
]]

-- plain find and replace, so a % or a quote in the value never reads as a pattern
local function fill(script, placeholder, value)
  local first, last = script:find(placeholder, 1, true)
  return script:sub(1, first - 1) .. value .. script:sub(last + 1)
end

--- Builds the powershell call for a script, encoded the way -EncodedCommand expects (UTF-16LE in
--- base64), so quotes and newlines never fight the command line.
---@param script string the body that runs once $session holds the player
---@return string[]
function M.powershell(script)
  local full = fill(PREAMBLE, "APPS", M.APPS) .. script
  return {
    "powershell.exe",
    "-NoProfile",
    "-NonInteractive",
    "-ExecutionPolicy",
    "Bypass",
    "-EncodedCommand",
    vim.base64.encode(vim.iconv(full, "utf-8", "utf-16le")),
  }
end

--- Builds the call that asks Apple Music what is playing.
---@return string[]
function M.status_command()
  return M.powershell(STATUS)
end

--- Builds the call for one control, ignored when Apple Music is closed.
---@param control string one of the music actions' CONTROLS
---@return string[]|nil
function M.control_command(control)
  local method = CONTROL_METHODS[control]
  if not method then
    return nil
  end
  return M.powershell(fill(CONTROL, "METHOD", method))
end

--- Builds the call that saves Apple Music's current cover to a file.
---@param path string where the cover lands
---@return string[]
function M.cover_command(path)
  -- PowerShell single quotes keep everything literal except a quote, which doubles
  return M.powershell(fill(COVER, "PATH", (path:gsub("'", "''"))))
end

return M
