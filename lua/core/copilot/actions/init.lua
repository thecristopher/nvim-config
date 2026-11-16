-- What Copilot's sign in status means for the hint, and how far it may write ahead. Pure logic only.
local M = {}

--- Tells whether Copilot's checkStatus answer says nobody is signed in.
---@param err any error from the request, nil when it answered
---@param status { user?: string, status?: string }|nil the answer
---@return boolean true only for a clear answer without a user, never for an error
function M.needs_sign_in(err, status)
  if err or type(status) ~= "table" then
    return false
  end
  return status.user == nil or status.user == ""
end

local function first_line(text)
  return (text:match("^[^\n]*"))
end

---Copilot's ghost text cut to the line it starts on, so it finishes a line instead of writing the
---whole function. A suggestion that would replace text past its own line is dropped.
---@param completions { text: string, displayText: string, range: { start: { line: integer }, ["end"]: { line: integer } } }[]
---@return table[] the same completions, one line each
function M.one_line(completions)
  local kept = {}
  for _, completion in ipairs(completions or {}) do
    local text = first_line(completion.text)
    local display = first_line(completion.displayText)
    if completion.range.start.line == completion.range["end"].line and display ~= "" then
      table.insert(
        kept,
        vim.tbl_extend("force", completion, { text = text, displayText = display })
      )
    end
  end
  return kept
end

---Next edit suggestions that touch a single line, the ones that rewrite a block are dropped.
---@param edits { text: string, range: { start: { line: integer }, ["end"]: { line: integer } } }[]
---@return table[]
function M.one_line_edits(edits)
  return vim.tbl_filter(function(edit)
    return edit.range.start.line == edit.range["end"].line and not edit.text:find("\n")
  end, edits or {})
end

return M
