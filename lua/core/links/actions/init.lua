-- Finds the links printed in a terminal, like the localhost a dev server announces. Pure logic only.
local M = {}

local URL = "https?://[%w%-%._~:/%?#%[%]@!%$&'%*%+,;=%%]+"

-- punctuation that ends a sentence around a link, never part of it
local TRAILING = "[%.,;:!%?'%]]+$"

--- Lists every link in a line with where it starts and ends.
---@param line string
---@return { url: string, first: integer, last: integer }[] byte columns, 1 based and inclusive
function M.links_in(line)
  local links = {}
  local from = 1
  while true do
    local first, last = (line or ""):find(URL, from)
    if not first then
      return links
    end
    local url = line:sub(first, last):gsub(TRAILING, "")
    links[#links + 1] = { url = url, first = first, last = first + #url - 1 }
    from = last + 1
  end
end

--- Returns the link under a byte column, nil when the column sits outside every link.
---@param line string
---@param column integer 1 based byte column, like getmousepos().column
---@return { url: string, first: integer, last: integer }|nil
function M.link_at(line, column)
  for _, link in ipairs(M.links_in(line)) do
    if column >= link.first and column <= link.last then
      return link
    end
  end
  return nil
end

--- Returns the url under a byte column, nil when the column sits outside every link.
---@param line string
---@param column integer 1 based byte column
---@return string|nil
function M.url_at(line, column)
  local link = M.link_at(line, column)
  return link and link.url
end

--- Returns the last link printed in the lines, nil when there is none.
---@param lines string[] oldest first, like a terminal buffer
---@return string|nil
function M.last_url(lines)
  for index = #lines, 1, -1 do
    local links = M.links_in(lines[index])
    if #links > 0 then
      return links[#links].url
    end
  end
  return nil
end

return M
