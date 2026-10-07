-- AI: claudecode.nvim — Claude Code CLI integrated natively into Neovim
-- No API key needed. Uses your existing Claude.ai login (same as VS Code).
-- How it works: Neovim starts a WebSocket server; `claude` CLI auto-connects to it.

return {
  {
    "coder/claudecode.nvim",
    event        = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start      = true,
      track_selection = true,   -- sends your cursor/visual selection as context

      -- default tui keeps nvim scrollback, and a file dodges cmd.exe mangling inline JSON quotes
      terminal_cmd    = "claude --settings " .. vim.fn.shellescape(vim.fn.stdpath("config") .. "/claude-settings.json"),

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
