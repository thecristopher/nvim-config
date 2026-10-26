-- What the terminal around nvim is and the escape sequences that restyle it. Pure logic only.
local M = {}

-- terminals that speak the kitty graphics protocol, so snacks can draw real images
M.IMAGE_TERMINALS = { kitty = true, ghostty = true, wezterm = true }

--- Names the terminal from its environment variables.
---@param env table<string, string> like vim.env
---@return string name one of kitty, ghostty, wezterm, iterm or unknown
function M.detect(env)
  if env.KITTY_WINDOW_ID or env.TERM == "xterm-kitty" then
    return "kitty"
  end
  if env.GHOSTTY_RESOURCES_DIR or env.TERM_PROGRAM == "ghostty" then
    return "ghostty"
  end
  if env.TERM_PROGRAM == "WezTerm" then
    return "wezterm"
  end
  if env.TERM_PROGRAM == "iTerm.app" then
    return "iterm"
  end
  return "unknown"
end

--- Tells whether a terminal can show the portraits as real images.
---@param name string from M.detect
---@return boolean
function M.images(name)
  return M.IMAGE_TERMINALS[name] == true
end

--- Tells whether snacks can draw a file as pixels: PNG as it is, anything else only through ImageMagick.
---@param file string image path
---@param has_magick boolean whether magick or convert is installed
---@return boolean
function M.pixels_for(file, has_magick)
  return has_magick or file:lower():match("%.png$") ~= nil
end

--- Sequence that paints the terminal's own background, the margin around nvim included.
---@param hex string like "#0E0908"
---@return string
function M.background(hex)
  return "\27]11;" .. hex .. "\7"
end

--- Sequence that gives the terminal its own background back.
---@return string
function M.reset_background()
  return "\27]111\7"
end

--- Sequence that switches iTerm to a profile, which is how iTerm changes font and transparency.
---@param profile string profile name as it appears in iTerm's settings
---@return string
function M.iterm_profile(profile)
  return "\27]1337;SetProfile=" .. profile .. "\7"
end

--- Lines of the Ghostty config the franchise wears, keys sorted so the file only changes with the skin.
---@param settings table<string, string|number|boolean>|nil Ghostty config keys and values
---@return string[]
function M.ghostty_config(settings)
  local lines = { "# written by Eldentree from the franchise skin, edits here are overwritten" }
  local keys = vim.tbl_keys(settings or {})
  table.sort(keys)
  for _, key in ipairs(keys) do
    lines[#lines + 1] = key .. " = " .. tostring(settings[key])
  end
  return lines
end

-- steps the opacity picker offers, from solid to the most see through that stays readable
M.OPACITY_STEPS = { 1, 0.97, 0.94, 0.9, 0.85, 0.8, 0.75, 0.7 }

--- Reads an opacity typed as 0.9, 90 or 90%.
---@param text string
---@return number|nil opacity between 0.1 and 1, nil when it is not one
function M.parse_opacity(text)
  local digits, percent = vim.trim(text or ""):match("^([%d%.]+)(%%?)$")
  local value = tonumber(digits)
  if not value then
    return nil
  end
  if percent == "%" or value > 1 then
    value = value / 100
  end
  if value < 0.1 or value > 1 then
    return nil
  end
  return value
end

--- Shows an opacity as a percentage.
---@param opacity number between 0 and 1
---@return string like "94%"
function M.opacity_label(opacity)
  return string.format("%d%%", math.floor(opacity * 100 + 0.5))
end

--- Ghostty settings with the chosen opacity laid over the skin's, leaving the skin's table untouched.
---@param settings table<string, string|number|boolean>|nil the skin's Ghostty keys
---@param opacity number|nil chosen opacity, nil keeps the skin's
---@return table<string, string|number|boolean>|nil
function M.with_opacity(settings, opacity)
  if not opacity then
    return settings
  end
  local merged = vim.deepcopy(settings or {})
  merged["background-opacity"] = opacity
  return merged
end

--- Names the groups that paint the editor body, so clearing their background lets a see through
--- terminal show behind the text. Floats and side panels keep their own shade and stay solid.
---@param highlights table<string, vim.api.keyset.get_hl_info> like nvim_get_hl(0, {})
---@return string[] names sorted
function M.body_groups(highlights)
  local body = highlights.Normal and highlights.Normal.bg
  local names = {}
  for name, attrs in pairs(highlights) do
    local is_body = name == "Normal" or name == "NormalNC" or (body ~= nil and attrs.bg == body)
    if is_body and attrs.bg and not attrs.link then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

--- AppleScript that makes Ghostty read its config again. Any terminal works as the target,
--- reload_config applies to the whole app.
---@return string
function M.ghostty_reload_script()
  return 'tell application "Ghostty" to perform action "reload_config" on terminal 1'
end

--- Wraps a sequence so it passes through tmux to the real terminal.
---@param sequence string
---@param inside_tmux boolean
---@return string
function M.passthrough(sequence, inside_tmux)
  if not inside_tmux then
    return sequence
  end
  return "\27Ptmux;" .. sequence:gsub("\27", "\27\27") .. "\27\\"
end

return M
