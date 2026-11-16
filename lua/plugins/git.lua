-- Git integration: diffview (diffs and history) and gitsigns (inline). lazygit is snacks' (<leader>gg)

return {
  -- ── Diffview: beautiful side-by-side diffs + file history ─────────
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal", winbar_info = true },
        merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
        file_history = { layout = "diff2_horizontal" },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { position = "left", width = 35 },
      },
      hooks = {
        diff_buf_read = function(_bufnr)
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.colorcolumn = ""
        end,
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      -- Blame virtual text: readable but clearly secondary, tinted to the region
      local function set_blame_hl()
        local tints = require("core.themes.actions").derive(require("core.themes").palette())
        vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = tints.blame, italic = true })
      end
      set_blame_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_blame_hl })
    end,
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        -- a removed line leaves a thin line where it was: under the line above it, or over the first
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
      },
      signs_staged_enable = true,
      signcolumn = true,
      numhl = false,
      linehl = false,
      word_diff = false,
      watch_gitdir = { follow_files = true },
      auto_attach = true,
      attach_to_untracked = false,
      current_line_blame = true,
      -- the blame waits until you stop to read and sits at the window's edge, so it never crowds the
      -- code or the inline diagnostics at the end of the line, and never flashes while moving
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "right_align",
        delay = 1500,
        ignore_whitespace = true,
        virt_text_priority = 100,
      },
      current_line_blame_formatter = " <author>, <author_time:%R> · <summary>",
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = require("core.skin").border(),
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
      on_attach = function(buf)
        local gs = package.loaded.gitsigns
        local map = function(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = buf
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation between hunks
        map("n", "]h", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Next hunk" })

        map("n", "[h", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Prev hunk" })

        -- Actions
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", { desc = "Stage hunk" })
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", { desc = "Reset hunk" })
        map("n", "<leader>ghS", gs.stage_buffer, { desc = "Stage buffer" })
        map("n", "<leader>ghu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
        map("n", "<leader>ghR", gs.reset_buffer, { desc = "Reset buffer" })
        map("n", "<leader>ghp", gs.preview_hunk, { desc = "Preview hunk" })
        map("n", "<leader>ghP", gs.preview_hunk_inline, { desc = "Preview hunk inline" })
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, { desc = "Blame line" })
        map("n", "<leader>ghB", gs.toggle_current_line_blame, { desc = "Toggle blame (line)" })
        map("n", "<leader>ghd", gs.diffthis, { desc = "Diff this" })
        map("n", "<leader>ghD", function()
          gs.diffthis("~")
        end, { desc = "Diff this (~)" })
        map("n", "<leader>ghx", gs.toggle_deleted, { desc = "Toggle deleted" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
      end,
    },
  },
}
