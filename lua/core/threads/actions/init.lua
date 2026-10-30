-- Review threads of the branch's PR, left on the lines they talk about: the GraphQL query, what an
-- open thread looks like once read and how it is said at the end of its line. Pure logic only.
local M = {}

M.QUERY = [[
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 50) { nodes { author { login } body } }
        }
      }
    }
  }
}
]]

M.RESOLVE = [[
mutation($thread: ID!) {
  resolveReviewThread(input: { threadId: $thread }) { thread { id isResolved } }
}
]]

-- the end of a line only fits so much, the picker shows the rest
M.PREVIEW_WIDTH = 72

local function first_line(body)
  for line in (body or ""):gmatch("[^\r\n]+") do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      return trimmed
    end
  end
  return ""
end

local function to_thread(node)
  local comments = (node.comments or {}).nodes or {}
  local first = comments[1] or {}
  return {
    id = node.id,
    path = node.path,
    line = node.line ~= vim.NIL and node.line or node.originalLine,
    outdated = node.isOutdated == true,
    author = ((first.author ~= vim.NIL and first.author) or {}).login or "ghost",
    body = first.body or "",
    replies = math.max(0, #comments - 1),
    comments = vim.tbl_map(function(comment)
      local author = comment.author ~= vim.NIL and comment.author or {}
      return { author = author.login or "ghost", body = comment.body or "" }
    end, comments),
  }
end

--- Reads the open threads from the GraphQL answer, by file then line.
---@param stdout string|nil
---@return table[] threads as { id, path, line, outdated, author, body, replies, comments }
function M.parse(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout or "")
  local pr = ok
    and type(decoded) == "table"
    and vim.tbl_get(decoded, "data", "repository", "pullRequest")
  local nodes = pr and pr ~= vim.NIL and vim.tbl_get(pr, "reviewThreads", "nodes") or {}
  local threads = {}
  for _, node in ipairs(nodes) do
    if not node.isResolved and type(node.path) == "string" then
      table.insert(threads, to_thread(node))
    end
  end
  table.sort(threads, function(a, b)
    if a.path ~= b.path then
      return a.path < b.path
    end
    return (a.line or 0) < (b.line or 0)
  end)
  return threads
end

--- The open threads on one file of the repo.
---@param threads table[]
---@param path string relative to the repo root
---@return table[]
function M.for_file(threads, path)
  return vim.tbl_filter(function(thread)
    return thread.path == path
  end, threads)
end

--- What sits at the end of the thread's line: who wrote it, the first line and the replies.
---@param thread { author: string, body: string, replies: integer }
---@return string
function M.preview(thread)
  local text = ("%s: %s"):format(thread.author, first_line(thread.body))
  if thread.replies > 0 then
    text = text .. (" (+%d)"):format(thread.replies)
  end
  if vim.api.nvim_strwidth(text) > M.PREVIEW_WIDTH then
    text = vim.fn.strcharpart(text, 0, M.PREVIEW_WIDTH - 1) .. "…"
  end
  return text
end

--- The whole conversation of a thread, for the float that opens on it.
---@param thread { comments: { author: string, body: string }[] }
---@return string[]
function M.conversation(thread)
  local lines = {}
  for index, comment in ipairs(thread.comments) do
    if index > 1 then
      table.insert(lines, "")
    end
    table.insert(lines, "**" .. comment.author .. "**")
    vim.list_extend(lines, vim.split(comment.body, "\r?\n"))
  end
  return lines
end

--- Finds the thread that sits on a line of a file, nil when none does.
---@param threads table[]
---@param path string
---@param line integer 1 based
---@return table|nil
function M.at(threads, path, line)
  for _, thread in ipairs(threads) do
    if thread.path == path and thread.line == line then
      return thread
    end
  end
  return nil
end

--- Splits "owner/name" the way `gh repo view --json nameWithOwner` prints it.
---@param name_with_owner string|nil
---@return string|nil owner
---@return string|nil name
function M.split_repo(name_with_owner)
  local owner, name = (name_with_owner or ""):match("^%s*([^/%s]+)/([^/%s]+)%s*$")
  return owner, name
end

return M
