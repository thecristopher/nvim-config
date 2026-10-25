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
