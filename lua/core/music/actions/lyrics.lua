-- Lyrics: asking LRCLIB, reading LRC timing and following the song through it. Pure logic only.
local M = {}

M.LRCLIB_URL = "https://lrclib.net/api/get"

-- a line with a long silence after it would sweep for ages, nobody holds a verse that long
local MAX_LINE_SECONDS = 7

--- Builds the curl call that asks LRCLIB for a song's lyrics.
---@param track { title: string, artist: string }
---@return string[]
function M.command(track)
  -- the album and duration Apple reports rarely match LRCLIB's, artist and title find more songs
  return {
    "curl",
    "-s",
    "-f",
    "--max-time",
    "5",
    "-A",
    "Eldentree (nvim)",
    "-G",
    "--data-urlencode",
    "artist_name=" .. track.artist,
    "--data-urlencode",
    "track_name=" .. track.title,
    M.LRCLIB_URL,
  }
end

-- peels every [mm:ss.xx] off the front of a line, one line can be sung more than once
local function stamped_line(raw)
  local times, rest = {}, raw
  while true do
    local minutes, seconds, after = rest:match("^%[(%d+):(%d+[%.:]?%d*)%](.*)$")
    if not minutes then
      break
    end
    table.insert(times, tonumber(minutes) * 60 + tonumber((seconds:gsub(":", "."))))
    rest = after
  end
  return times, vim.trim(rest)
end

--- Reads LRC text into lines sorted by the second they are sung, skipping tags like [ar:Name].
---@param text string|nil
---@return { time: number, text: string }[]
function M.parse_lrc(text)
  local lines = {}
  for raw in (text or ""):gmatch("[^\r\n]+") do
    local times, words = stamped_line(vim.trim(raw))
    for _, time in ipairs(times) do
      table.insert(lines, { time = time, text = words })
    end
  end
  table.sort(lines, function(a, b)
    return a.time < b.time
  end)
  return lines
end

local function plain_lines(text)
  local lines = {}
  for _, line in ipairs(vim.split(text, "\r?\n")) do
    table.insert(lines, { text = vim.trim(line) })
  end
  return lines
end

--- Reads LRCLIB's answer, preferring synced lyrics over plain ones.
---@param body string|nil
---@return { kind: "synced"|"plain"|"instrumental", lines: { time: number|nil, text: string }[] }|nil lyrics, nil when the song has none
function M.parse(body)
  local ok, data = pcall(vim.json.decode, body or "")
  if not ok or type(data) ~= "table" then
    return nil
  end
  if data.instrumental == true then
    return { kind = "instrumental", lines = {} }
  end
  local synced = type(data.syncedLyrics) == "string" and M.parse_lrc(data.syncedLyrics) or {}
  if #synced > 0 then
    return { kind = "synced", lines = synced }
  end
  if type(data.plainLyrics) == "string" and vim.trim(data.plainLyrics) ~= "" then
    return { kind = "plain", lines = plain_lines(data.plainLyrics) }
  end
  return nil
end

--- Names the cached lyrics of a track.
---@param track { artist: string, title: string }
---@return string
function M.name(track)
  return "lyrics_" .. require("core.utils").hash(track.artist .. "|" .. track.title)
end

--- Finds the synced line being sung at a moment of the song.
---@param lines { time: number }[] sorted by time
---@param elapsed number seconds into the song
---@return integer index, 0 before the first line
function M.line_at(lines, elapsed)
  local index = 0
  for i, line in ipairs(lines) do
    if line.time > elapsed then
      break
    end
    index = i
  end
  return index
end

--- Tells how much of a synced line has been sung, for the karaoke sweep.
---@param lines { time: number }[] sorted by time
---@param index integer the line being sung
---@param elapsed number seconds into the song
---@param duration number|nil seconds the song lasts, closes the last line
---@return number from 0 to 1
function M.sung(lines, index, elapsed, duration)
  local line = lines[index]
  if not line then
    return 0
  end
  local next_line = lines[index + 1]
  local ends = next_line and next_line.time or duration or math.huge
  ends = math.min(ends, line.time + MAX_LINE_SECONDS)
  if ends <= line.time then
    return 1
  end
  return math.min(math.max((elapsed - line.time) / (ends - line.time), 0), 1)
end

return M
