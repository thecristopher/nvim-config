-- Telescope: fuzzy finder with Elden Ring styling

return {
  {
    "nvim-telescope/telescope.nvim",
    tag          = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = function() return vim.fn.executable("make") == 1 end },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    cmd  = "Telescope",
    keys = {
      -- Files
      { "<leader>ff", "<cmd>Telescope find_files<cr>",                                  desc = "Find files" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>",       desc = "Find all files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",                                    desc = "Recent files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",                                   desc = "Live grep" },
      { "<leader>fG", "<cmd>Telescope grep_string<cr>",                                 desc = "Grep word under cursor" },
      { "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",    desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",                                   desc = "Help" },
      { "<leader>fm", "<cmd>Telescope marks<cr>",                                       desc = "Marks" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>",                                     desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope command_history<cr>",                             desc = "Command history" },
      { "<leader>f/", "<cmd>Telescope search_history<cr>",                              desc = "Search history" },
      { "<leader>ft", "<cmd>Telescope todo-comments<cr>",                              desc = "Todo comments" },
      -- Neovim
      { "<leader>fn", function()
          require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
        end, desc = "Neovim config" },
      -- Git
      { "<leader>gC", "<cmd>Telescope git_commits<cr>",   desc = "Git commits" },
      { "<leader>gs", "<cmd>Telescope git_status<cr>",    desc = "Git status" },
      { "<leader>gS", "<cmd>Telescope git_stash<cr>",     desc = "Git stash" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>",  desc = "Git branches" },
    },
    config = function()
      local telescope  = require("telescope")
      local actions    = require("telescope.actions")
      local themes     = require("telescope.themes")

      telescope.setup({
        defaults = {
          prompt_prefix    = "  ",
          selection_caret  = " ❯ ",
          entry_prefix     = "   ",
          initial_mode     = "insert",
          selection_strategy = "reset",
          sorting_strategy   = "ascending",
          layout_strategy    = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width   = 0.55,
              results_width   = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width    = 0.87,
            height   = 0.80,
            preview_cutoff = 120,
          },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "--hidden",
            "--glob=!.git/",
          },
          file_sorter        = require("telescope.sorters").get_fuzzy_file,
          file_ignore_patterns = {
            "%.git/", "node_modules/", "%.DS_Store", "__pycache__/",
            "%.pyc", "%.class", "dist/", "build/", ".next/",
          },
          generic_sorter     = require("telescope.sorters").get_generic_fuzzy_sorter,
          path_display       = { "truncate" },
          winblend           = 5,
          border             = {},
          borderchars        = require("core.skin.actions").border_chars(require("core.skin").border()),
          color_devicons     = true,
          set_env            = { COLORTERM = "truecolor" },
          mappings = {
            i = {
              ["<C-j>"]  = actions.move_selection_next,
              ["<C-k>"]  = actions.move_selection_previous,
              ["<C-c>"]  = actions.close,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"]   = actions.move_selection_previous,
              ["<CR>"]   = actions.select_default,
              ["<C-x>"]  = actions.select_horizontal,
              ["<C-v>"]  = actions.select_vertical,
              ["<C-t>"]  = actions.select_tab,
              ["<C-u>"]  = actions.preview_scrolling_up,
              ["<C-d>"]  = actions.preview_scrolling_down,
              ["<PageUp>"]   = actions.results_scrolling_up,
              ["<PageDown>"] = actions.results_scrolling_down,
              ["<Tab>"]  = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
              ["<C-q>"]  = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"]  = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-l>"]  = actions.complete_tag,
              ["<C-_>"]  = actions.which_key,
              ["<Esc>"]  = actions.close,
            },
            n = {
              ["<esc>"] = actions.close,
              ["<CR>"]  = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
              ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["j"]     = actions.move_selection_next,
              ["k"]     = actions.move_selection_previous,
              ["H"]     = actions.move_to_top,
              ["M"]     = actions.move_to_middle,
              ["L"]     = actions.move_to_bottom,
              ["<Down>"] = actions.move_selection_next,
              ["<Up>"]   = actions.move_selection_previous,
              ["gg"]     = actions.move_to_top,
              ["G"]      = actions.move_to_bottom,
              ["<C-u>"]  = actions.preview_scrolling_up,
              ["<C-d>"]  = actions.preview_scrolling_down,
              ["<PageUp>"]   = actions.results_scrolling_up,
              ["<PageDown>"] = actions.results_scrolling_down,
              ["?"]      = actions.which_key,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix", "--hidden", "--exclude", ".git" },
          },
          buffers = {
            show_all_buffers  = true,
            sort_lastused     = true,
            theme             = "dropdown",
            previewer         = false,
            mappings          = {
              i = { ["<c-d>"] = actions.delete_buffer },
              n = { ["d"]     = actions.delete_buffer },
            },
          },
          live_grep = {
            additional_args  = function() return { "--hidden" } end,
          },
        },
        extensions = {
          fzf = {
            fuzzy                    = true,
            override_generic_sorter  = true,
            override_file_sorter     = true,
            case_mode                = "smart_case",
          },
          ["ui-select"] = {
            themes.get_dropdown(),
          },
        },
      })

      -- Load extensions
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
    end,
  },
}
