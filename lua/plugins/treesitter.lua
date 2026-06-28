-- Treesitter: syntax, folding, text objects, context

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",  -- v1 rewrite on main removed nvim-treesitter.configs
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    lazy  = vim.fn.argc(-1) == 0,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    cmd  = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts = {
      highlight = {
        enable  = true,
        disable = function(_, buf)
          -- Disable for very large files
          local max_filesize = 500 * 1024
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          return ok and stats and stats.size > max_filesize
        end,
        additional_vim_regex_highlighting = false,
      },
      indent      = { enable = true },
      incremental_selection = {
        enable  = true,
        keymaps = {
          init_selection    = "<C-space>",
          node_incremental  = "<C-space>",
          scope_incremental = "<nop>",
          node_decremental  = "<bs>",
        },
      },
      textobjects = {
        select = {
          enable    = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "outer function" },
            ["if"] = { query = "@function.inner", desc = "inner function" },
            ["ac"] = { query = "@class.outer",    desc = "outer class" },
            ["ic"] = { query = "@class.inner",    desc = "inner class" },
            ["aa"] = { query = "@parameter.outer", desc = "outer parameter" },
            ["ia"] = { query = "@parameter.inner", desc = "inner parameter" },
            ["ai"] = { query = "@conditional.outer", desc = "outer conditional" },
            ["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
            ["al"] = { query = "@loop.outer",     desc = "outer loop" },
            ["il"] = { query = "@loop.inner",     desc = "inner loop" },
            ["ab"] = { query = "@block.outer",    desc = "outer block" },
            ["ib"] = { query = "@block.inner",    desc = "inner block" },
          },
        },
        move = {
          enable              = true,
          set_jumps           = true,
          goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
        swap = {
          enable        = true,
          swap_next     = { ["<leader>a"] = "@parameter.inner" },
          swap_previous = { ["<leader>A"] = "@parameter.inner" },
        },
        lsp_interop = {
          enable         = true,
          border         = "rounded",
          peek_definition_code = {
            ["<leader>df"] = "@function.outer",
            ["<leader>dF"] = "@class.outer",
          },
        },
      },
      ensure_installed = {
        "bash", "c", "cmake", "comment", "cpp", "css", "diff",
        "dockerfile", "fish", "git_config", "git_rebase", "gitcommit",
        "gitignore", "go", "gomod", "gowork", "graphql", "html",
        "http", "java", "javascript", "jsdoc", "json", "json5",
        "lua", "luadoc", "luap", "make", "markdown",
        "markdown_inline", "python", "query", "regex", "ron", "rust",
        "scss", "sql", "svelte", "terraform", "toml", "tsx",
        "typescript", "vim", "vimdoc", "vue", "xml", "yaml",
        "zig",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Treesitter context: shows current scope at top
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts  = {
      enable            = true,
      max_lines         = 3,
      min_window_height = 20,
      line_numbers      = true,
      multiline_threshold = 1,
      trim_scope        = "outer",
      mode              = "cursor",
      zindex            = 20,
      on_attach         = nil,
    },
    keys = {
      {
        "[x",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Go to context (up)",
      },
    },
  },
}
