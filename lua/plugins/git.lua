-- Git integration: neogit (status/commit/log), diffview (diffs/history), gitsigns (inline)

return {
  -- ── Neogit: Magit-style native Git UI ─────────────────────────────
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    cmd  = { "Neogit" },
    keys = {
      { "<leader>gn",  "<cmd>Neogit<cr>",                                          desc = "Neogit status" },
      { "<leader>gc",  "<cmd>Neogit commit<cr>",                                   desc = "Neogit commit" },
      { "<leader>gP",  "<cmd>Neogit push<cr>",                                     desc = "Neogit push" },
      { "<leader>gpl", "<cmd>Neogit pull<cr>",                                     desc = "Neogit pull" },
      { "<leader>glg", function() require("neogit").open({ "log" }) end,           desc = "Neogit log" },
      { "<leader>gbr", function() require("neogit").open({ "branch" }) end,        desc = "Neogit branches" },
    },
    opts = {
      -- Use diffview.nvim for diff/history windows
      integrations = { diffview = true, telescope = false, fzf_lua = false },
      -- Graph style: unicode box-drawing for the commit graph
      graph_style = "unicode",
      -- Disable built-in commit editor (use Neovim's buffer)
      disable_commit_confirmation = false,
      -- Auto-refresh after actions
      auto_refresh = true,
      -- Signs in the status buffer
      kind = "tab",   -- open in a new tab (feels more GitLens-like, full screen)
      signs = {
        hunk    = { "", "" },
        item    = { "▶", "▼" },
        section = { "▶", "▼" },
      },
      -- Sections shown in status buffer
      sections = {
        untracked    = { folded = false, hidden = false },
        unstaged     = { folded = false, hidden = false },
        staged       = { folded = false, hidden = false },
        stashes      = { folded = true },
        unpulled_upstream = { folded = true,  hidden = false },
        unmerged_upstream = { folded = false, hidden = false },
        unpulled_pushremote   = { folded = true,  hidden = true },
        unmerged_pushremote   = { folded = false, hidden = true },
        recent        = { folded = false },
        rebase        = { folded = false, hidden = false },
      },
    },
  },

  -- ── Diffview: beautiful side-by-side diffs + file history ─────────
  {
    "sindrets/diffview.nvim",
    cmd  = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>",           desc = "Diffview open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>",          desc = "Diffview close" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>",  desc = "File history" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>",    desc = "Branch history" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default      = { layout = "diff2_horizontal", winbar_info = true },
        merge_tool   = { layout = "diff3_horizontal", disable_diagnostics = true },
        file_history = { layout = "diff2_horizontal" },
      },
      file_panel = {
        listing_style = "tree",
        win_config    = { position = "left", width = 35 },
      },
      hooks = {
        diff_buf_read = function(_bufnr)
          vim.opt_local.wrap        = false
          vim.opt_local.list        = false
          vim.opt_local.colorcolumn = ""
        end,
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event  = { "BufReadPre", "BufNewFile" },
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
      current_line_blame    = true,
      current_line_blame_opts = {
        virt_text         = true,
        virt_text_pos     = "eol",
        delay             = 600,
        ignore_whitespace = true,
        virt_text_priority = 100,
      },
      current_line_blame_formatter = " <author>, <author_time:%R> · <summary>",
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
