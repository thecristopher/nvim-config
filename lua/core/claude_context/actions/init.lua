-- Pure helpers behind core.claude_context: which lines to hand Claude and how to word a diagnostics ask.
local M = {}

-- tree-sitter node types that wrap a function across the languages this config edits
M.FUNCTION_TYPES = {
  arrow_function = true,
  function_declaration = true,
  function_definition = true,
  function_expression = true,
  function_item = true,
  local_function = true,
  method_declaration = true,
  method_definition = true,
}

--- Finds the closest function around a node.
---@param node TSNode|nil node under the cursor
---@return integer|nil first one based first line of the function
---@return integer|nil last one based last line of the function
function M.enclosing_function(node)
  while node do
    if M.FUNCTION_TYPES[node:type()] then
      local first, _, last = node:range()
      return first + 1, last + 1
    end
    node = node:parent()
  end
  return nil, nil
end

local function one_line(message)
  return (message:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

--- Words one diagnostic as `L12 error: message`.
---@param diagnostic vim.Diagnostic
---@return string
function M.describe(diagnostic)
  local severity = vim.diagnostic.severity[diagnostic.severity] or "INFO"
  return ("L%d %s: %s"):format(diagnostic.lnum + 1, severity:lower(), one_line(diagnostic.message))
end

--- Builds the single line ask that goes into Claude's prompt, worst first, nil with nothing to fix.
--- It stays on one line because a newline in Claude's input submits it.
---@param diagnostics vim.Diagnostic[]
---@param path string file the diagnostics belong to, relative to the project
---@return string|nil
function M.diagnostics_prompt(diagnostics, path)
  if #diagnostics == 0 then
    return nil
  end
  local sorted = vim.deepcopy(diagnostics)
  table.sort(sorted, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    return a.lnum < b.lnum
  end)
  local parts = {}
  for _, diagnostic in ipairs(sorted) do
    parts[#parts + 1] = M.describe(diagnostic)
  end
  return ("Fix these diagnostics in %s: %s"):format(path, table.concat(parts, "; "))
end

return M
