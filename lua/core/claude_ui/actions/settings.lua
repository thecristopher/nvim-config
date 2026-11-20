-- Merges the Eldentree pieces into Claude Code's settings.json without touching anything else:
-- the statusline, the sound hooks next to whatever hooks are already there, the spinner verbs
-- and the theme. Pure logic only, the caller reads and writes the file.
local M = {}

-- UserPromptSubmit plays nothing, it stamps when a turn began so Stop knows whether it was long
M.HOOK_EVENTS = { "UserPromptSubmit", "Stop", "StopFailure", "PermissionRequest" }
-- the usage limits move on their own, so the statusline also refreshes on a timer
M.REFRESH_SECONDS = 10

-- every Eldentree hook runs this script, wherever the repo or nvim live
M.HOOK_SCRIPT = "claude/hook.lua"

-- the list without its repeats, in its order
local function unique(list)
  local kept, seen = {}, {}
  for _, item in ipairs(list) do
    if not seen[item] then
      seen[item] = true
      table.insert(kept, item)
    end
  end
  return kept
end

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

--- Puts the role's verbs in the spinner, taking back every verb Eldentree wrote before and
--- keeping the ones that came from somewhere else.
---@param settings table decoded settings.json, changed in place
---@param verbs string[] the verbs of the role in use
---@param known string[] every verb any franchise or role brings
---@return boolean changed
function M.set_verbs(settings, verbs, known)
  local current = type(settings.spinnerVerbs) == "table" and settings.spinnerVerbs.verbs or {}
  local ours = {}
  for _, verb in ipairs(known) do
    ours[verb] = true
  end
  local kept = vim.tbl_filter(function(verb)
    return not ours[verb]
  end, current)
  local merged = unique(vim.list_extend(kept, verbs))
  settings.spinnerVerbs = { mode = "append", verbs = merged }
  return not vim.deep_equal(current, merged)
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
---@param plan { statusline: string, hook: string, verbs: string[], known?: string[], theme: string }
---@return string[] changes what was added or replaced, empty when it was all there already
function M.merge(settings, plan)
  local changes = {}
  set(settings, "statusLine", {
    type = "command",
    command = plan.statusline,
    refreshInterval = M.REFRESH_SECONDS,
  }, "statusline", changes)
  merge_hooks(settings, plan.hook, changes)
  if M.set_verbs(settings, plan.verbs, plan.known or {}) then
    table.insert(changes, "spinner verbs")
  end
  set(settings, "theme", "custom:" .. plan.theme, "theme", changes)
  return changes
end

--- The spinner verbs of the role in use: the franchise's shared ones, then the region's own.
---@param lore table
---@param region table|nil
---@return string[]
function M.verbs_for(lore, region)
  local shared = vim.deepcopy((lore.claude or {}).verbs or {})
  return unique(vim.list_extend(shared, ((region or {}).claude or {}).verbs or {}))
end

--- Every verb the franchises and their regions bring, so a new role takes the last one's back.
---@param lores table[]
---@return string[]
function M.known_verbs(lores)
  local verbs = {}
  for _, lore in ipairs(lores) do
    vim.list_extend(verbs, (lore.claude or {}).verbs or {})
    for _, region in ipairs(lore.regions or {}) do
      vim.list_extend(verbs, (region.claude or {}).verbs or {})
    end
  end
  return unique(verbs)
end

return M
