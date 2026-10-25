-- Restyles the terminal around nvim with the franchise: the background follows the region,
-- iTerm can switch to a profile per franchise (fonts live there), and Kitty takes its opacity.
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
  local ok, supported = pcall(function() return Snacks.image.supports_terminal() end)
  if ok then return supported == true end
  return actions.images(M.name())
end

local function send(sequence)
  if #vim.api.nvim_list_uis() == 0 then return end
  pcall(vim.api.nvim_chan_send, vim.v.stderr, actions.passthrough(sequence, vim.env.TMUX ~= nil))
end

-- what the terminal already wears, so nothing is sent twice: a repeated iTerm profile reloads the
-- font and resizes the window, which made every region preview shake the whole editor
local worn = {}

local function skin()
  return require("core.franchise").current().skin.terminal or {}
end

local function paint_background()
  if vim.g.eldentree_terminal_background == false then return end
  local base = require("core.themes").palette().base
  if worn.background == base then return end
  worn.background = base
  send(actions.background(base))
end

-- iTerm only switches to profiles that exist, so this waits for an explicit opt in
local function apply_profile()
  if M.name() ~= "iterm" or not vim.g.eldentree_iterm_profiles then return end
  local profile = skin().iterm_profile
  if not profile or worn.profile == profile then return end
  worn.profile = profile
  send(actions.iterm_profile(profile))
end

local function apply_opacity()
  if M.name() ~= "kitty" or not vim.g.eldentree_kitty_remote or not skin().kitty_opacity then return end
  if worn.opacity == skin().kitty_opacity then return end
  worn.opacity = skin().kitty_opacity
  vim.system({ "kitty", "@", "set-background-opacity", tostring(worn.opacity) })
end

--- Dresses the terminal for the franchise in use.
function M.apply()
  paint_background()
  apply_profile()
  apply_opacity()
end

local function restore()
  send(actions.reset_background())
  if M.name() == "iterm" and vim.g.eldentree_iterm_profiles then
    send(actions.iterm_profile(vim.g.eldentree_iterm_default_profile or "Default"))
  end
  -- the terminal is back to its own look, so the next apply has to send everything again
  worn = {}
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_terminal", { clear = true })
  -- regions only recolor, the profile and its font belong to the franchise
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = paint_background })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "EldentreeRegionSettled", callback = paint_background })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "EldentreeFranchise", callback = M.apply })
  vim.api.nvim_create_autocmd({ "UIEnter", "VimResume" }, { group = group, callback = M.apply })
  vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = group, callback = restore })
end

return M
