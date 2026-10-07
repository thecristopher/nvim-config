-- AI: claudecode.nvim — Claude Code CLI integrated natively into Neovim
-- No API key needed. Uses your existing Claude.ai login (same as VS Code).
-- How it works: Neovim starts a WebSocket server; `claude` CLI auto-connects to it.

local is_windows = vim.fn.has("win32") == 1

-- claudecode splits this string itself (no shell), so single quotes keep each piece literal
local function quote_arg(arg)
  return "'" .. arg:gsub("\\", "/") .. "'"
end

-- nvim on Windows often misses the installer's PATH entry, so check the usual homes directly
local function find_windows_claude()
  local on_path = vim.fn.exepath("claude")
  if on_path ~= "" then return on_path end

  local home = vim.env.USERPROFILE or vim.env.HOME or ""
  local appdata = vim.env.APPDATA or ""
  local candidates = {
    home .. "/.local/bin/claude.exe",
    home .. "/.claude/local/claude.exe",
    appdata .. "/npm/claude.cmd",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.filereadable(path) == 1 then return path end
  end
  return ""
end

local function claude_launcher()
  if not is_windows then return "claude" end

  local exe = find_windows_claude()
  if exe == "" then
    vim.notify("claude not found on PATH or in the usual install folders", vim.log.levels.WARN)
    return "claude"
  end

  -- npm installs claude as a .cmd shim, which jobstart can only run through cmd.exe
  if exe:lower():match("%.cmd$") or exe:lower():match("%.bat$") then
    return "cmd.exe /c " .. quote_arg(exe)
  end
  return quote_arg(exe)
end

local function claude_terminal_cmd()
  local settings_file = vim.fn.stdpath("config") .. "/claude-settings.json"
  return claude_launcher() .. " --settings " .. quote_arg(settings_file)
end

return {
  {
    "coder/claudecode.nvim",
    event        = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start      = true,
      track_selection = true,   -- sends your cursor/visual selection as context

      -- default tui keeps nvim scrollback, and a file dodges cmd.exe mangling inline JSON quotes
      terminal_cmd    = claude_terminal_cmd(),

      terminal = {
        provider    = "snacks",
        auto_insert = true,   -- toggling in drops you straight into Insert mode, ready to type
        snacks_win_opts = {
          position = "right",
          width    = 0.38,
          border   = "rounded",
        },
      },

      diff_opts = {
        layout              = "vertical",
        open_in_new_tab     = false,
        keep_terminal_focus = false,
      },
    },

    keys = {
      -- Toggle / navigation
      { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude",          mode = { "n", "t" } },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      -- Context
      { "<leader>ab", "<cmd>ClaudeCodeAdd<cr>",         desc = "Add buffer to context" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        desc = "Send selection",         mode = "v" },
      { "<leader>at", "<cmd>ClaudeCodeTreeAdd<cr>",     desc = "Add file from tree" },
      -- Diffs
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
      { "<leader>ax", "<cmd>ClaudeCodeCloseAllDiffs<cr>", desc = "Close all diffs" },
    },

    config = function(_, opts)
      require("claudecode").setup(opts)

      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>a", group = "claude", icon = "󱜸" } })
      end

      -- Window navigation out of the Claude terminal (deliberately no <Esc>/jk
      -- remap here: Esc interrupts Claude generation, and "jk" is something
      -- you'll type mid-sentence when chatting with it).
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_terminal",
        callback = function(args)
          local map = vim.keymap.set
          map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = args.buf, desc = "Window left" })
          map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { buffer = args.buf, desc = "Window down" })
          map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { buffer = args.buf, desc = "Window up" })
          map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { buffer = args.buf, desc = "Window right" })
        end,
      })
    end,
  },
}
