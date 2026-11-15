-- The Claude Code side panel and its fullscreen: it can take the whole editor while you only work
-- with Claude, and the same toggle puts the layout back to its defaults.
local actions = require("core.claude_panel.actions")

local M = {}

-- the window options fullscreen bends, to give back when it ends, nil while not fullscreen
local saved = nil

---The buffer claudecode runs Claude in, nil when it is not running.
---@return integer|nil
local function panel_buf()
  local ok, terminal = pcall(require, "claudecode.terminal")
  if not ok then
    return nil
  end
  local buf = terminal.get_active_terminal_bufnr()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end
  return nil
end

--- The split showing the panel in this tab, nil when it is hidden.
---@return integer|nil
function M.window()
  local buf = panel_buf()
  if not buf then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf and vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  return nil
end

--- Whether the panel has the whole editor right now.
---@return boolean
function M.is_fullscreen()
  return saved ~= nil
end

--- Columns the panel opens with in the editor as it is now.
---@return integer
function M.default_width()
  return actions.default_width(vim.o.columns)
end

local function enter_panel(win)
  vim.api.nvim_set_current_win(win)
  if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
    vim.cmd.startinsert()
  end
end

local function fill(win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_width(win, vim.o.columns)
  end
end

local function end_fullscreen()
  if not saved then
    return
  end
  vim.o.winminwidth, vim.o.winwidth = saved.winminwidth, saved.winwidth
  saved = nil
  require("core.hud").hide_portrait(false)
end

local function start_fullscreen(win)
  saved = { winminwidth = vim.o.winminwidth, winwidth = vim.o.winwidth }
  require("core.hud").hide_portrait(true)
  enter_panel(win)
  -- the other windows fold down to their border instead of keeping a column each, and one that
  -- gets focus by accident grows a single column instead of twenty
  vim.o.winminwidth = 0
  vim.o.winwidth = 1
  fill(win)
end

local function focus_target(win, opened)
  if win == M.window() then
    return "panel"
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return "float"
  end
  return opened and "new" or "collapsed"
end

---Keeps fullscreen whole when focus lands elsewhere: anything that closes a float or looks for a
---main window can drop focus on a collapsed window, which would grow and squeeze Claude.
---@param win integer window that got focus
---@param opened boolean whether it was just created
local function guard(win, opened)
  local panel = M.window()
  if not saved or not panel or not vim.api.nvim_win_is_valid(win) then
    return
  end
  local action = actions.on_focus(focus_target(win, opened))
  if action == "release" then
    end_fullscreen()
    return require("core.resize").reset()
  end
  if action == "back" then
    vim.api.nvim_set_current_win(panel)
  end
  fill(panel)
end

--- Lets the panel take the whole editor, or puts every window back to its default size.
function M.toggle_fullscreen()
  local win = M.window()
  if not win then
    -- not open yet, open it and go fullscreen once it is drawn
    vim.cmd("ClaudeCodeFocus")
    return vim.schedule(function()
      local opened = M.window()
      if opened then
        start_fullscreen(opened)
      end
    end)
  end
  if not saved then
    return start_fullscreen(win)
  end
  end_fullscreen()
  require("core.resize").reset()
end

-- snacks and the split equalizer put the default width back, fullscreen goes on after them
local function keep_fullscreen()
  local win = M.window()
  if saved and win then
    vim.schedule(function()
      fill(win)
    end)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_claude_panel", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = keep_fullscreen })
  vim.api.nvim_create_autocmd({ "WinEnter", "WinNew" }, {
    group = group,
    callback = function(args)
      if not saved then
        return
      end
      local win = vim.api.nvim_get_current_win()
      local opened = args.event == "WinNew"
      -- floats get their config after WinNew, so look once the layout settles
      vim.schedule(function()
        guard(win, opened)
      end)
    end,
  })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    callback = function(args)
      if args.buf == panel_buf() then
        end_fullscreen()
      end
    end,
  })
  vim.api.nvim_create_user_command("ClaudeFullscreen", M.toggle_fullscreen, {
    desc = "Let the Claude panel take the whole editor, or put the layout back",
  })
end

return M
