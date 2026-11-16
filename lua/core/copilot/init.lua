-- Copilot's sign in, said once. Without a GitHub sign in the server quietly answers nothing, so once
-- Copilot loads in a session it asks the server once and, when nobody is signed in, leaves one hint
-- naming :Copilot auth. No retries, no repeats.
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

--- Runs once Copilot loads (on the first InsertEnter or :Copilot), giving its server time to start.
function M.setup()
  vim.defer_fn(M.check, ASK_AFTER_MS)
end

return M
