-- Hands Claude what you are looking at with one key: the function under the cursor, or the
-- buffer's diagnostics as a ready ask you can still edit before sending.
local actions = require("core.claude_context.actions")

local M = {}

local function claudecode()
  local ok, claude = pcall(require, "claudecode")
  if ok and claude.is_claude_connected and claude.is_claude_connected() then
    return claude
  end
  vim.notify("Claude is not connected, open it with <leader>ac first", vim.log.levels.WARN)
  return nil
end

local function relative_path(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
end

local function node_at_cursor()
  local ok, node = pcall(vim.treesitter.get_node)
  return ok and node or nil
end

--- Sends the function around the cursor as an at mention, or the current line outside any function.
function M.send_function()
  local claude = claudecode()
  if not claude then
    return
  end
  local first, last = actions.enclosing_function(node_at_cursor())
  if not first then
    local line = vim.api.nvim_win_get_cursor(0)[1]
    first, last = line, line
  end
  -- claudecode counts lines from zero
  claude.send_at_mention(vim.api.nvim_buf_get_name(0), first - 1, last - 1, "ClaudeContextFunction")
end

--- Types an ask to fix the buffer's diagnostics into Claude's prompt, without submitting it.
function M.send_diagnostics()
  local claude = claudecode()
  if not claude then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local prompt = actions.diagnostics_prompt(vim.diagnostic.get(buf), relative_path(buf))
  if not prompt then
    vim.notify("No diagnostics in this buffer", vim.log.levels.INFO)
    return
  end
  require("claudecode.terminal").send_to_terminal(prompt, { submit = false })
end

return M
