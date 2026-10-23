-- Navigation: Harpoon (file marks) + Persistence (sessions)

return {
  -- ── Harpoon2: teleport between marked files instantly ──────────────
  {
    "ThePrimeagen/harpoon",
    branch       = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end,                                desc = "Add to harpoon" },
      { "<leader>hh", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon menu" },
      { "<leader>hp", function() require("harpoon"):list():prev() end,                               desc = "Harpoon prev" },
      { "<leader>hn", function() require("harpoon"):list():next() end,                               desc = "Harpoon next" },
      { "<leader>1",  function() require("harpoon"):list():select(1) end,                            desc = "Harpoon file 1" },
      { "<leader>2",  function() require("harpoon"):list():select(2) end,                            desc = "Harpoon file 2" },
      { "<leader>3",  function() require("harpoon"):list():select(3) end,                            desc = "Harpoon file 3" },
      { "<leader>4",  function() require("harpoon"):list():select(4) end,                            desc = "Harpoon file 4" },
    },
    config = function()
      require("harpoon"):setup({
        settings = {
          save_on_toggle   = true,
          sync_on_ui_close = true,
        },
      })
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>h", group = "harpoon", icon = "󱈸" } })
      end
    end,
  },

  -- ── Oil: edit a folder like a buffer, neo-tree stays the file explorer ──
  {
    "stevearc/oil.nvim",
    cmd          = "Oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-",         "<cmd>Oil<cr>",                              desc = "Open parent folder (Oil)" },
      { "<leader>-", function() require("oil").toggle_float() end, desc = "Oil float" },
    },
    opts = {
      default_file_explorer        = false,
      columns                      = { "icon" },
      skip_confirm_for_simple_edits = true,
      view_options                 = { show_hidden = true },
      float                        = { padding = 4, border = "rounded" },
    },
  },

  -- ── Persistence: session save / restore per project ─────────────────
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts  = {
      dir  = vim.fn.stdpath("state") .. "/sessions/",
      need = 1,
    },
    keys = {
      { "<leader>qs", function() require("persistence").load() end,                desc = "Restore session (cwd)" },
      { "<leader>qS", function() require("persistence").select() end,              desc = "Select session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end,               desc = "Don't save session" },
    },
    config = function(_, opts)
      require("persistence").setup(opts)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>q", group = "session", icon = "󰆔" } })
      end
    end,
  },
}
