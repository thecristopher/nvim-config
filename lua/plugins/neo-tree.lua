-- Neo-tree: file system explorer with Elden Ring aesthetic

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd  = "Neotree",
    keys = {
      { "<leader>fe", "<cmd>Neotree toggle<cr>",                        desc = "Explorer (root)" },
      { "<leader>fE", "<cmd>Neotree toggle dir=%:p:h<cr>",             desc = "Explorer (cwd)" },
      { "<leader>e",  "<cmd>Neotree reveal<cr>",                        desc = "Reveal in explorer" },
      { "<leader>ge", "<cmd>Neotree git_status<cr>",                    desc = "Git status tree" },
    },
    deactivate = function()
      vim.cmd([[Neotree close]])
    end,
    init = function()
      -- Open tree on directory argument
      if vim.fn.argc(-1) == 1 then
        local stat = vim.loop.fs_stat(vim.fn.argv(0))
        if stat and stat.type == "directory" then
          require("neo-tree")
        end
      end
    end,
    opts = {
      sources = { "filesystem", "buffers", "git_status", "document_symbols" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        bind_to_cwd      = false,
        follow_current_file = { enabled = true, leave_dirs_open = false },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible         = false,
          hide_dotfiles   = false,
          hide_gitignored = true,
          hide_by_name    = { "node_modules", ".git", "__pycache__" },
          never_show      = { ".DS_Store", "thumbs.db" },
        },
      },
      default_component_configs = {
        indent = {
          indent_size            = 2,
          padding                = 1,
          with_markers           = true,
          indent_marker          = "│",
          last_indent_marker     = "└",
          highlight              = "NeoTreeIndentMarker",
          with_expanders         = nil,
          expander_collapsed     = "",
          expander_expanded      = "",
          expander_highlight     = "NeoTreeExpander",
        },
        icon = {
          folder_closed = "",
          folder_open   = "",
          folder_empty  = "󰜌",
          default       = "*",
          highlight     = "NeoTreeFileIcon",
        },
        modified = { symbol = "●", highlight = "NeoTreeModified" },
        name     = { trailing_slash = false, use_git_status_colors = true, highlight = "NeoTreeFileName" },
        git_status = {
          symbols = {
            added     = "", unstaged = "󰄱",
            staged    = "", unmerged = "",
            renamed   = "󰁕", deleted  = "",
            ignored   = "", conflict = "",
          },
        },
        file_size  = { enabled = true, required_width = 64 },
        type       = { enabled = true, required_width = 122 },
        last_modified = { enabled = true, required_width = 88 },
        created    = { enabled = true, required_width = 110 },
        symlink_target = { enabled = false },
      },
      window = {
        position     = "left",
        width        = 34,
        mapping_options = { noremap = true, nowait = true },
        mappings = {
          ["<space>"] = { "toggle_node", nowait = false },
          ["<2-LeftMouse>"] = "open",
          ["<cr>"]   = "open",
          ["<esc>"]  = "cancel",
          ["P"]      = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
          ["l"]      = "focus_preview",
          ["S"]      = "open_split",
          ["s"]      = "open_vsplit",
          ["t"]      = "open_tabnew",
          ["w"]      = "open_with_window_picker",
          ["C"]      = "close_node",
          ["z"]      = "close_all_nodes",
          ["a"]      = { "add", config = { show_path = "none" } },
          ["A"]      = "add_directory",
          ["d"]      = "delete",
          ["r"]      = "rename",
          ["y"]      = "copy_to_clipboard",
          ["x"]      = "cut_to_clipboard",
          ["p"]      = "paste_from_clipboard",
          ["c"]      = "copy",
          ["m"]      = "move",
          ["q"]      = "close_window",
          ["R"]      = "refresh",
          ["?"]      = "show_help",
          ["<"]      = "prev_source",
          [">"]      = "next_source",
          ["i"]      = "show_file_details",
          ["H"]      = "toggle_hidden",
          ["/"]      = "fuzzy_finder",
          ["D"]      = "fuzzy_finder_directory",
          ["#"]      = "fuzzy_sorter",
          ["f"]      = "filter_on_submit",
          ["<c-x>"]  = "clear_filter",
          ["[g"]     = "prev_git_modified",
          ["]g"]     = "next_git_modified",
          ["o"]      = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
          ["oc"]     = { "order_by_created",  nowait = false },
          ["od"]     = { "order_by_diagnostics", nowait = false },
          ["og"]     = { "order_by_git_status", nowait = false },
          ["om"]     = { "order_by_modified", nowait = false },
          ["on"]     = { "order_by_name",     nowait = false },
          ["os"]     = { "order_by_size",     nowait = false },
          ["ot"]     = { "order_by_type",     nowait = false },
        },
      },
      popups = {
        position = { col = "50%", row = "30%" },
        size     = { width = 60, height = 15 },
        border   = { style = "rounded" },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.cmd("setlocal number relativenumber")
          end,
        },
      },
    },
  },
}
