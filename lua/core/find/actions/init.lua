-- Pure helpers for the pickers: which scope the recent files show and how it is titled.
local M = {}

M.SCOPES = { repo = "Recent in this repo", all = "Recent everywhere" }

---The other scope, so one key flips between them.
---@param scope "repo"|"all"
---@return "repo"|"all"
function M.other_scope(scope)
  return scope == "repo" and "all" or "repo"
end

---The picker title for a scope, with the key that flips it.
---@param scope "repo"|"all"
---@return string
function M.recent_title(scope)
  return ("%s  <C-a> %s"):format(M.SCOPES[scope], M.other_scope(scope))
end

return M
