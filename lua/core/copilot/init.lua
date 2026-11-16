-- Copilot's sign in, said once. Without a GitHub sign in the server quietly answers nothing, so once
-- Copilot loads in a session it asks the server once and, when nobody is signed in, leaves one hint
-- naming :Copilot auth. No retries, no repeats.
-- In back-to-basics exercises Copilot is leashed to the line it starts on: the drill is writing the
-- function by hand, so it may finish a line but never hand over a whole block.
local actions = require("core.copilot.actions")

local M = {}

-- the server takes a moment to start after the plugin loads
local ASK_AFTER_MS = 4000
local asked = false

local function hint()
  vim.notify(
    "Copilot is not signed in, run :Copilot auth to turn its suggestions on",
    vim.log.levels.INFO,
    { title = "Copilot", id = "eldentree_copilot_sign_in" }
  )
end

--- Asks the Copilot server once whether someone is signed in, and hints at :Copilot auth if not.
function M.check()
  if asked then
    return
  end
  local client = vim.lsp.get_clients({ name = "copilot" })[1]
  if not client then
    return
  end
  asked = true
  client:request("checkStatus", { localChecksOnly = false }, function(err, status)
    if actions.needs_sign_in(err, status) then
      vim.schedule(hint)
    end
  end)
end

local function in_exercise(buf)
  return buf and vim.api.nvim_buf_is_valid(buf) and vim.b[buf].btb_exercise ~= nil
end

-- wraps a completion request so its answer reaches copilot.lua one line long inside an exercise
local function leashed_request(request)
  return function(client, params, callback)
    local buf = vim.uri_to_bufnr(params.textDocument.uri)
    return request(client, params, function(err, data, ...)
      if data and in_exercise(buf) then
        data.completions = actions.one_line(data.completions)
      end
      return callback(err, data, ...)
    end)
  end
end

--- Keeps Copilot's ghost text and next edit suggestions to one line inside btb exercises.
--- Both plugins read these functions from their module on every answer, so wrapping them is enough.
function M.leash()
  local api = require("copilot.api")
  api.get_completions = leashed_request(api.get_completions)
  api.get_completions_cycling = leashed_request(api.get_completions_cycling)
  local ok, nes_ui = pcall(require, "copilot-lsp.nes.ui")
  if not ok then
    return
  end
  local display = nes_ui._display_next_suggestion
  nes_ui._display_next_suggestion = function(buf, ns, edits)
    return display(buf, ns, in_exercise(buf) and actions.one_line_edits(edits) or edits)
  end
end

--- Runs once Copilot loads (on the first InsertEnter or :Copilot), giving its server time to start.
function M.setup()
  M.leash()
  vim.defer_fn(M.check, ASK_AFTER_MS)
end

return M
