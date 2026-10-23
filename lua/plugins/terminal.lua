-- toggleterm: persistent floating and split terminals

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd     = { "ToggleTerm", "TermExec" },
    keys    = {
      { "<leader>tt",  "<cmd>ToggleTerm direction=float<cr>",      desc = "Float terminal" },
      { "<leader>th",  "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Horizontal terminal" },
      { "<leader>tv",  "<cmd>ToggleTerm direction=vertical<cr>",   desc = "Vertical terminal" },
      { "<C-\\>",      "<cmd>ToggleTerm<cr>",                      desc = "Toggle terminal" },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 16
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      open_mapping          = [[<C-\>]],
      hide_numbers          = true,
      shade_filetypes       = {},
      shade_terminals       = true,
      shading_factor        = 2,
      start_in_insert       = true,
      insert_mappings       = true,
      -- <C-\> in terminal mode would swallow <C-\><C-n>, the only way out of every terminal
      terminal_mappings     = false,
      persist_size          = true,
      persist_mode          = true,
      direction             = "float",
      close_on_exit         = true,
      shell                 = vim.o.shell,
      auto_scroll           = true,
      float_opts = {
        border        = "curved",
        winblend      = 8,
        width         = function() return math.floor(vim.o.columns * 0.85) end,
        height        = function() return math.floor(vim.o.lines * 0.80) end,
        title_pos     = "center",
      },
      highlights = {
        FloatBorder   = { link = "FloatBorder" },
        NormalFloat   = { link = "NormalFloat" },
      },
      winbar = {
        enabled    = false,
        name_formatter = function(term) return term.name end,
      },
    },
    config = function(_, opts)
      local function set_terminal_keymaps(term)
        local map = vim.keymap.set
        local buf = term.bufnr
        map("t", "<Esc>",   [[<C-\><C-n>]],    { buffer = buf, desc = "Exit terminal mode" })
        map("t", "jk",      [[<C-\><C-n>]],    { buffer = buf, desc = "Exit terminal mode" })
        map("t", "<C-h>",   [[<C-\><C-n><C-W>h]], { buffer = buf, desc = "Window left" })
        map("t", "<C-j>",   [[<C-\><C-n><C-W>j]], { buffer = buf, desc = "Window down" })
        map("t", "<C-k>",   [[<C-\><C-n><C-W>k]], { buffer = buf, desc = "Window up" })
        map("t", "<C-l>",   [[<C-\><C-n><C-W>l]], { buffer = buf, desc = "Window right" })
        local git_actions = require("core.git.actions")
        vim.wo[term.window].winbar = git_actions.terminal_hint(git_actions.QUICK_KEYS)
      end

      -- a TermOpen name pattern misses on Windows, where the buffer is named cmd.exe&::toggleterm::1
      opts.on_open = set_terminal_keymaps
      require("toggleterm").setup(opts)

      -- Named terminal instances
      local Terminal = require("toggleterm.terminal").Terminal

      local lazygit = Terminal:new({
        cmd           = "lazygit",
        dir           = "git_dir",
        direction     = "float",
        float_opts    = { border = "curved" },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.keymap.set("n", "q", "<cmd>close<CR>", { noremap = true, silent = true, buffer = term.bufnr })
        end,
      })

      vim.keymap.set("n", "<leader>tg", function() lazygit:toggle() end, { desc = "Lazygit (toggleterm)" })
    end,
  },
}
