-- Git integration: gitsigns for inline diff + blame

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts  = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      signs_staged = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
      signs_staged_enable   = true,
      signcolumn            = true,
      numhl                 = false,
      linehl                = false,
      word_diff             = false,
      watch_gitdir          = { follow_files = true },
      auto_attach           = true,
      attach_to_untracked   = false,
      current_line_blame    = false,
      current_line_blame_opts = {
        virt_text         = true,
        virt_text_pos     = "eol",
        delay             = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> • <summary>",
      sign_priority         = 6,
      update_debounce       = 100,
      status_formatter      = nil,
      max_file_length       = 40000,
      preview_config = {
        border   = "rounded",
        style    = "minimal",
        relative = "cursor",
        row      = 0,
        col      = 1,
      },
      on_attach = function(buf)
        local gs  = package.loaded.gitsigns
        local map = function(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = buf
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation between hunks
        map("n", "]h", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Next hunk" })

        map("n", "[h", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Prev hunk" })

        -- Actions
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>",  { desc = "Stage hunk" })
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>",  { desc = "Reset hunk" })
        map("n", "<leader>ghS", gs.stage_buffer,                       { desc = "Stage buffer" })
        map("n", "<leader>ghu", gs.undo_stage_hunk,                    { desc = "Undo stage hunk" })
        map("n", "<leader>ghR", gs.reset_buffer,                       { desc = "Reset buffer" })
        map("n", "<leader>ghp", gs.preview_hunk,                       { desc = "Preview hunk" })
        map("n", "<leader>ghP", gs.preview_hunk_inline,                { desc = "Preview hunk inline" })
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
        map("n", "<leader>ghB", gs.toggle_current_line_blame,          { desc = "Toggle blame (line)" })
        map("n", "<leader>ghd", gs.diffthis,                           { desc = "Diff this" })
        map("n", "<leader>ghD", function() gs.diffthis("~") end,       { desc = "Diff this (~)" })
        map("n", "<leader>ghx", gs.toggle_deleted,                     { desc = "Toggle deleted" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
      end,
    },
  },
}
