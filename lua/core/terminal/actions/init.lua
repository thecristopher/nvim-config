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
