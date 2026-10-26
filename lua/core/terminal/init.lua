-- Restyles the terminal around nvim with the franchise: the background follows the region,
-- iTerm can switch to a profile per franchise (fonts live there), Kitty takes its opacity, and
-- Ghostty reloads a config file written from the skin. :Opacity or <leader>uo overrides the
-- skin's opacity in Kitty and Ghostty until set back to skin.
-- vim.g.eldentree_terminal_background = false leaves the terminal alone.
local actions = require("core.terminal.actions")

local M = {}

local detected

--- Names the terminal nvim runs in.
---@return string
function M.name()
  detected = detected or actions.detect(vim.env)
  return detected
end

--- Tells whether portraits can be drawn as real images instead of chafa's half blocks.
---@return boolean
function M.supports_images()
  local ok, supported = pcall(function()
    return Snacks.image.supports_terminal()
  end)
  if ok then
    return supported == true
  end
  return actions.images(M.name())
end

--- Tells whether this file can be drawn as real pixels, so anything else falls back to chafa
--- instead of leaving a blank space.
---@param file string image path
---@return boolean
function M.can_draw(file)
  if not M.supports_images() then
    return false
  end
  local has_magick = vim.fn.executable("magick") == 1 or vim.fn.executable("convert") == 1
  return actions.pixels_for(file, has_magick)
end

local function send(sequence)
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  pcall(vim.api.nvim_chan_send, vim.v.stderr, actions.passthrough(sequence, vim.env.TMUX ~= nil))
end

-- what the terminal already wears, so nothing is sent twice: a repeated iTerm profile reloads the
-- font and resizes the window, which made every region preview shake the whole editor
local worn = {}

local function skin()
  return require("core.franchise").current().skin.terminal or {}
end

local function paint_background()
  if vim.g.eldentree_terminal_background == false then
    return
  end
  local base = require("core.themes").palette().base
  if worn.background == base then
    return
  end
  worn.background = base
  send(actions.background(base))
end

-- iTerm only switches to profiles that exist, so this waits for an explicit opt in
local function apply_profile()
  if M.name() ~= "iterm" or not vim.g.eldentree_iterm_profiles then
    return
  end
  local profile = skin().iterm_profile
  if not profile or worn.profile == profile then
    return
  end
  worn.profile = profile
  send(actions.iterm_profile(profile))
end

-- the opacity picked with :Opacity, kept across restarts and franchise switches
local OPACITY_FILE = vim.fn.stdpath("state") .. "/eldentree_opacity"

local chosen_opacity

local function load_opacity()
  local ok, lines = pcall(vim.fn.readfile, OPACITY_FILE, "", 1)
  if ok and lines[1] then
    chosen_opacity = actions.parse_opacity(lines[1])
  end
end

local function apply_opacity()
  local opacity = chosen_opacity or skin().kitty_opacity
  if M.name() ~= "kitty" or not vim.g.eldentree_kitty_remote or not opacity then
    return
  end
  if worn.opacity == opacity then
    return
  end
  worn.opacity = opacity
  vim.system({ "kitty", "@", "set-background-opacity", tostring(opacity) })
end

-- Ghostty includes this file from its own config with `config-file = ?~/.config/ghostty/eldentree`
local GHOSTTY_FILE = vim.fs.joinpath(vim.env.HOME or "", ".config", "ghostty", "eldentree")

-- reloading only works on macOS, where Ghostty takes AppleScript
local function wants_ghostty()
  return M.name() == "ghostty" and vim.g.eldentree_ghostty_config and vim.fn.has("mac") == 1
end

local function write_ghostty(settings)
  vim.fn.mkdir(vim.fs.dirname(GHOSTTY_FILE), "p")
  vim.fn.writefile(actions.ghostty_config(settings), GHOSTTY_FILE)
  return vim.system({ "osascript", "-e", actions.ghostty_reload_script() })
end

local function apply_ghostty()
  if not wants_ghostty() then
    return
  end
  local settings = actions.with_opacity(skin().ghostty, chosen_opacity)
  if not settings then
    return
  end
  -- compared by content, a chosen opacity builds a fresh table on every apply
  local written = table.concat(actions.ghostty_config(settings), "\n")
  if worn.ghostty == written then
    return
  end
  worn.ghostty = written
  write_ghostty(settings)
end

--- Dresses the terminal for the franchise in use.
function M.apply()
  paint_background()
  apply_profile()
  apply_opacity()
  apply_ghostty()
end

--- Tells whether this terminal can take an opacity from nvim.
---@return boolean
function M.takes_opacity()
  if M.name() == "kitty" then
    return vim.g.eldentree_kitty_remote == true
  end
  return wants_ghostty() == true
end

local function see_through()
  return chosen_opacity ~= nil and chosen_opacity < 1
end

-- the terminal's own background already wears the region base, so the body looks the same,
-- only now the terminal's opacity reaches it
local function clear_body_backgrounds()
  if not see_through() then
    return
  end
  for _, name in ipairs(actions.body_groups(vim.api.nvim_get_hl(0, {}))) do
    local attrs = vim.api.nvim_get_hl(0, { name = name })
    attrs.bg = nil
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

--- Sets the terminal's opacity and remembers it, nil goes back to the franchise skin's.
---@param opacity number|nil between 0.1 and 1
function M.set_opacity(opacity)
  local was_see_through = see_through()
  chosen_opacity = opacity
  if opacity then
    pcall(vim.fn.writefile, { tostring(opacity) }, OPACITY_FILE)
  else
    pcall(vim.fn.delete, OPACITY_FILE)
  end
  apply_opacity()
  apply_ghostty()
  if was_see_through and not see_through() and vim.g.colors_name then
    -- reloading paints the body backgrounds back
    vim.cmd.colorscheme(vim.g.colors_name)
    return
  end
  clear_body_backgrounds()
end

--- Opens a picker with the opacity steps plus going back to the skin's.
function M.pick_opacity()
  if not M.takes_opacity() then
    vim.notify(
      "Opacity needs Kitty with eldentree_kitty_remote or Ghostty with eldentree_ghostty_config",
      vim.log.levels.WARN
    )
    return
  end
  local choices = vim.list_extend({ "skin" }, actions.OPACITY_STEPS)
  vim.ui.select(choices, {
    prompt = "Terminal opacity",
    format_item = function(choice)
      if choice == "skin" then
        return "Follow the franchise skin"
      end
      local mark = choice == chosen_opacity and "  (current)" or ""
      return actions.opacity_label(choice) .. mark
    end,
  }, function(choice)
    if choice == nil then
      return
    end
    M.set_opacity(choice ~= "skin" and choice or nil)
  end)
end

local function opacity_command(cmd)
  if cmd.args == "" then
    return M.pick_opacity()
  end
  if cmd.args == "skin" then
    return M.set_opacity(nil)
  end
  local opacity = actions.parse_opacity(cmd.args)
  if not opacity then
    vim.notify("Opacity takes 0.9, 90, 90% or skin", vim.log.levels.ERROR)
    return
  end
  M.set_opacity(opacity)
end

local function restore()
  send(actions.reset_background())
  if M.name() == "iterm" and vim.g.eldentree_iterm_profiles then
    send(actions.iterm_profile(vim.g.eldentree_iterm_default_profile or "Default"))
  end
  -- waits so the reload is not cut off when nvim exits right after
  if wants_ghostty() and worn.ghostty then
    write_ghostty(nil):wait(2000)
  end
  -- the terminal is back to its own look, so the next apply has to send everything again
  worn = {}
end

function M.setup()
  load_opacity()
  vim.api.nvim_create_user_command("Opacity", opacity_command, {
    nargs = "?",
    complete = function()
      local steps = vim.tbl_map(function(opacity)
        return tostring(math.floor(opacity * 100 + 0.5))
      end, actions.OPACITY_STEPS)
      return vim.list_extend({ "skin" }, steps)
    end,
    desc = "Set the terminal opacity",
  })
  local group = vim.api.nvim_create_augroup("eldentree_terminal", { clear = true })
  -- regions only recolor, the profile and its font belong to the franchise
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = paint_background })
  -- runs before the region crossfade reads the new colors, so the fade keeps the body clear
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = clear_body_backgrounds })
  vim.api.nvim_create_autocmd(
    "User",
    { group = group, pattern = "EldentreeRegionSettled", callback = paint_background }
  )
  vim.api.nvim_create_autocmd(
    "User",
    { group = group, pattern = "EldentreeFranchise", callback = M.apply }
  )
  vim.api.nvim_create_autocmd({ "UIEnter", "VimResume" }, { group = group, callback = M.apply })
  vim.api.nvim_create_autocmd(
    { "VimLeavePre", "VimSuspend" },
    { group = group, callback = restore }
  )
end

return M
