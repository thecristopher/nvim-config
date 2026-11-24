-- Databases without leaving the editor (dadbod) and splitting or joining a block (treesj), both
-- loaded on first use.

return {
  -- ── dadbod: query databases, with completion for tables and columns ─
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = { { "<leader>cd", "<cmd>DBUIToggle<cr>", desc = "Databases" } },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      -- queries and connections stay in state, out of every repo
      vim.g.db_ui_save_location = vim.fn.stdpath("state") .. "/eldentree_db"
      vim.g.db_ui_execute_on_save = 0
    end,
  },

  -- ── treesj: split a one line table, call or array into lines, or join it back ─
  {
    "Wansmer/treesj",
    opts = { use_default_keymaps = false, max_join_length = 160 },
    keys = {
      {
        "<leader>cj",
        function()
          require("treesj").toggle()
        end,
        desc = "Split or join this block",
      },
    },
  },
}
