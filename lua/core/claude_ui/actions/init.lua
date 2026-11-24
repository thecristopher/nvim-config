-- Claude Code dressed as the region: the custom theme built from the palette, and which franchise
-- sound each Claude Code hook event plays. Pure logic only.
local blend = require("core.themes.actions").blend

local M = {}

M.THEME_SLUG = "eldentree"

--- Builds the Claude Code theme file for a region, every token taken from its palette.
---@param region { title: string, palette: table }
---@param franchise_title string
---@return { name: string, base: string, overrides: table<string, string> }
function M.theme(region, franchise_title)
  local p = region.palette
  local accent = p.yellow
  return {
    name = ("Eldentree · %s · %s"):format(franchise_title, region.title),
    base = "dark",
    overrides = {
      claude = accent,
      claudeShimmer = blend(p.text, accent, 0.4),
      text = p.text,
      inactive = p.overlay1,
      inactiveShimmer = p.overlay2,
      subtle = p.surface2,
      suggestion = p.lavender or accent,
      permission = accent,
      permissionShimmer = blend(p.text, accent, 0.4),
      remember = p.mauve or accent,
      success = p.green,
      error = p.red,
      warning = p.peach,
      warningShimmer = blend(p.text, p.peach, 0.4),
      promptBorder = p.overlay0,
      promptBorderShimmer = p.overlay2,
      planMode = p.blue or accent,
      autoAccept = p.green,
      bashBorder = p.pink or p.peach,
      diffAdded = blend(p.green, p.base, 0.22),
      diffRemoved = blend(p.red, p.base, 0.22),
      diffAddedDimmed = blend(p.green, p.base, 0.1),
      diffRemovedDimmed = blend(p.red, p.base, 0.1),
      diffAddedWord = blend(p.green, p.base, 0.45),
      diffRemovedWord = blend(p.red, p.base, 0.45),
      userMessageBackground = p.surface0,
      userMessageBackgroundHover = p.surface1,
      bashMessageBackgroundColor = p.mantle,
      selectionBg = p.surface2,
      composerSidebarBackground = p.mantle,
      rate_limit_fill = accent,
      rate_limit_empty = p.surface1,
      briefLabelClaude = accent,
      briefLabelYou = p.lavender or p.text,
    },
  }
end

-- a turn shorter than this ended while you were still watching, so it needs no call back
M.LONG_TURN_S = 20
-- permission prompts that come in a burst ring once
M.PERMISSION_QUIET_S = 30

--- Decides whether a hook's sound plays: never during an expedition, the end of a turn only when
--- the turn was long enough to look away (or nobody knows when it began), and a permission
--- prompt only when the last one rang a while ago.
---@param event string hook event name
---@param ctx { now: number, turn_started?: number, last_permission?: number, expedition_until?: number } seconds since the epoch
---@return boolean
function M.should_play(event, ctx)
  if ctx.expedition_until and ctx.now < ctx.expedition_until then
    return false
  end
  if event == "Stop" then
    return not ctx.turn_started or ctx.now - ctx.turn_started >= M.LONG_TURN_S
  end
  if event == "PermissionRequest" then
    return not ctx.last_permission or ctx.now - ctx.last_permission >= M.PERMISSION_QUIET_S
  end
  return true
end

--- Reads a number of seconds kept in a state file line, nil when there is none.
---@param line string|nil
---@return number|nil
function M.stamp(line)
  return tonumber(vim.trim(line or ""))
end

--- Whether a session is one of the desk's background work sessions, which
--- nobody is watching, so their turns never ring.
---@param id string|nil the hook's session id
---@param background string[] short ids of the desk's sessions, each the start of a full id
---@return boolean
function M.background(id, background)
  if not id then
    return false
  end
  for _, short in ipairs(background) do
    if short ~= "" and vim.startswith(id, short) then
      return true
    end
  end
  return false
end

--- Makes a session id safe to use as a file name.
---@param id string|nil
---@return string
function M.session_file(id)
  local safe = tostring(id or "default"):gsub("[^%w%-_]", "")
  return safe ~= "" and safe or "default"
end

--- Picks the franchise sound for a Claude Code hook event.
---@param event string hook event name, like "Stop"
---@param travel string the franchise's travel mechanic, "fog" or "door"
---@return string|nil sound event, nil when the hook stays quiet
function M.hook_sound(event, travel)
  if event == "Stop" then
    return "grace"
  end
  if event == "StopFailure" then
    return "died"
  end
  -- something stands in the way until you answer, like a fog wall or a locked door
  if event == "PermissionRequest" then
    return travel
  end
  return nil
end

return M
