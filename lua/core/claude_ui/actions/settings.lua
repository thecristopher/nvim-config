-- Merges the Eldentree pieces into Claude Code's settings.json without touching anything else:
-- the statusline, the sound hooks next to whatever hooks are already there, the spinner verbs
-- and the theme. Pure logic only, the caller reads and writes the file.
local M = {}

M.HOOK_EVENTS = { "Stop", "StopFailure", "PermissionRequest" }
-- the usage limits move on their own, so the statusline also refreshes on a timer
M.REFRESH_SECONDS = 10

-- every Eldentree hook runs this script, wherever the repo or nvim live
M.HOOK_SCRIPT = "claude/hook.lua"

local function is_ours(hook)
  return type(hook.command) == "string" and hook.command:find(M.HOOK_SCRIPT, 1, true) ~= nil
end

-- drops earlier Eldentree hooks so a moved repo or nvim replaces them instead of piling up
local function without_ours(groups)
  local kept = {}
  for _, group in ipairs(groups or {}) do
    local hooks = vim.tbl_filter(function(hook)
      return not is_ours(hook)
    end, group.hooks or {})
    if #hooks > 0 then
      table.insert(kept, vim.tbl_extend("force", group, { hooks = hooks }))
    end
  end
  return kept
end

local function merge_hooks(settings, hook_command, changes)
  settings.hooks = settings.hooks or vim.empty_dict()
  for _, event in ipairs(M.HOOK_EVENTS) do
    local before = settings.hooks[event] or {}
    local groups = without_ours(before)
    table.insert(
      groups,
      { hooks = { { type = "command", command = hook_command .. " " .. event } } }
    )
    if not vim.deep_equal(before, groups) then
      table.insert(changes, "hook " .. event)
    end
    settings.hooks[event] = groups
  end
end

local function merge_verbs(settings, verbs, changes)
  local current = type(settings.spinnerVerbs) == "table" and settings.spinnerVerbs.verbs or {}
  local merged, seen = {}, {}
  for _, verb in ipairs(vim.list_extend(vim.deepcopy(current), verbs)) do
    if not seen[verb] then
      seen[verb] = true
      table.insert(merged, verb)
    end
  end
  if #merged ~= #current then
    table.insert(changes, ("spinner verbs (+%d)"):format(#merged - #current))
  end
  settings.spinnerVerbs = { mode = "append", verbs = merged }
end

local function set(settings, key, value, label, changes)
  if vim.deep_equal(settings[key], value) then
    return
  end
  settings[key] = value
  table.insert(changes, label)
end

--- Adds the Eldentree statusline, hooks, verbs and theme to a settings table.
---@param settings table decoded settings.json, changed in place
---@param plan { statusline: string, hook: string, verbs: string[], theme: string }
---@return string[] changes what was added or replaced, empty when it was all there already
function M.merge(settings, plan)
  local changes = {}
  set(settings, "statusLine", {
    type = "command",
    command = plan.statusline,
    refreshInterval = M.REFRESH_SECONDS,
  }, "statusline", changes)
  merge_hooks(settings, plan.hook, changes)
  merge_verbs(settings, plan.verbs, changes)
  set(settings, "theme", "custom:" .. plan.theme, "theme", changes)
  return changes
end

--- Collects the spinner verbs of every franchise, in franchise order without repeats.
---@param lores table[]
---@return string[]
function M.verbs(lores)
  local verbs, seen = {}, {}
  for _, lore in ipairs(lores) do
    for _, verb in ipairs((lore.claude or {}).verbs or {}) do
      if not seen[verb] then
        seen[verb] = true
        table.insert(verbs, verb)
      end
    end
  end
  return verbs
end

return M
