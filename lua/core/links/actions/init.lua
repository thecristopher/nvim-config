-- Finds the links printed in a terminal, like the localhost a dev server announces or the
-- file:line references Claude Code prints. Pure logic only.
local M = {}

local URL = "https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+"

-- a path with an extension, like lua/core/links/init.lua, ~/notes.md or /tmp/a.lua
local FILE = "[%w%._%-/~]*[%w_%-]%.%a[%w]*"

-- punctuation that ends a sentence around a link, never part of it
local TRAILING = "[%.,;:!%?'%]]+$"

-- a closing parenthesis belongs to the url only when the url opened it, like a wiki page
-- named Malenia_(Elden_Ring); the one closing "(see http://localhost:3000)" does not
local function trim(url)
  while true do
    local trimmed = url:gsub(TRAILING, "")
    local _, opened = trimmed:gsub("%(", "")
    local _, closed = trimmed:gsub("%)", "")
    if trimmed:sub(-1) == ")" and closed > opened then
      trimmed = trimmed:sub(1, -2)
    end
    if trimmed == url then
      return url
    end
    url = trimmed
  end
end

local function urls_in(line)
  local links = {}
  local from = 1
  while true do
    local first, last = line:find(URL, from)
    if not first then
      return links
    end
    local url = trim(line:sub(first, last))
    links[#links + 1] = { url = url, first = first, last = first + #url - 1 }
    from = last + 1
  end
end

local function inside(links, column)
  for _, link in ipairs(links) do
    if column >= link.first and column <= link.last then
      return true
    end
  end
  return false
end

-- the :line and :line:col that may follow a path, as numbers and the bytes they take
local function position_after(line, last)
  local row = line:match("^:(%d+)", last + 1)
  if not row then
    return nil, nil, last
  end
  last = last + 1 + #row
  local col = line:match("^:(%d+)", last + 1)
  if col then
    last = last + 1 + #col
  end
  return tonumber(row), tonumber(col), last
end

local function files_in(line, urls)
  local files = {}
  local from = 1
  while true do
    local first, last = line:find(FILE, from)
    if not first then
      return files
    end
    -- a word glued to the path on the left makes it something else, like an email
    local glued = first > 1 and line:sub(first - 1, first - 1):match("[%w@]")
    if not glued and not inside(urls, first) then
      local row, col, ends = position_after(line, last)
      local path = line:sub(first, last)
      files[#files + 1] = { path = path, row = row, col = col, first = first, last = ends }
    end
    from = last + 1
  end
end

--- Lists every link in a line with where it starts and ends: urls, and file references that may
--- point to a file on disk (the caller checks it is there).
---@param line string
---@return { url?: string, path?: string, row?: integer, col?: integer, first: integer, last: integer }[] byte columns, 1 based and inclusive
function M.links_in(line)
  line = line or ""
  local urls = urls_in(line)
  local links = vim.list_extend(vim.list_slice(urls), files_in(line, urls))
  table.sort(links, function(a, b)
    return a.first < b.first
  end)
  return links
end

--- Returns the link under a byte column, nil when the column sits outside every link.
---@param line string
---@param column integer 1 based byte column, like getmousepos().column
---@return { url?: string, path?: string, row?: integer, col?: integer, first: integer, last: integer }|nil
function M.link_at(line, column)
  for _, link in ipairs(M.links_in(line)) do
    if column >= link.first and column <= link.last then
      return link
    end
  end
  return nil
end

--- Returns the url under a byte column, nil when the column sits outside every url.
---@param line string
---@param column integer 1 based byte column
---@return string|nil
function M.url_at(line, column)
  local link = M.link_at(line, column)
  return link and link.url
end

-- a terminal line that fills its whole width runs on in the next one
local function wraps(line, width)
  return width ~= nil and vim.fn.strdisplaywidth(line or "") >= width
end

--- Joins the terminal lines a long line was wrapped over, the way it was printed.
---@param lines string[]
---@param row integer 1 based, any line of the wrapped run
---@param width integer|nil the terminal's width, nil to take the line alone
---@return string text, integer offset bytes before the row's own line in the text
function M.logical_line(lines, row, width)
  local first, last = row, row
  while first > 1 and wraps(lines[first - 1], width) do
    first = first - 1
  end
  while last < #lines and wraps(lines[last], width) do
    last = last + 1
  end
  local text, offset = "", 0
  for index = first, last do
    if index == row then
      offset = #text
    end
    text = text .. lines[index]
  end
  return text, offset
end

--- The url under a column even when the terminal wrapped it over several lines.
---@param lines string[]
---@param row integer 1 based
---@param column integer 1 based byte column in that row
---@param width integer|nil the terminal's width
---@return string|nil
function M.url_across_lines(lines, row, column, width)
  local text, offset = M.logical_line(lines, row, width)
  return M.url_at(text, offset + column)
end

--- Returns the last url printed in the lines, nil when there is none. With the terminal's width,
--- a url wrapped over several lines comes back whole.
---@param lines string[] oldest first, like a terminal buffer
---@param width? integer
---@return string|nil
function M.last_url(lines, width)
  local index = #lines
  while index >= 1 do
    local text = M.logical_line(lines, index, width)
    local links = urls_in(text)
    if #links > 0 then
      return links[#links].url
    end
    -- step over the whole wrapped run, not line by line inside it
    repeat
      index = index - 1
    until index < 1 or not wraps(lines[index], width)
  end
  return nil
end

--- The absolute path a file reference points to, relative ones from the terminal's folder.
---@param path string as printed, like lua/core/links/init.lua or ~/notes.md
---@param cwd string
---@return string
function M.resolve(path, cwd)
  if path:sub(1, 1) == "/" then
    return path
  end
  if path:sub(1, 2) == "~/" then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(cwd .. "/" .. path)
end

return M
