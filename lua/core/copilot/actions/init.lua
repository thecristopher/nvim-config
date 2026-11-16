-- What Copilot's sign in status means for the hint. Pure logic only.
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

return M
