-- Editor quality-of-life: navigation, text manipulation, diagnostics

return {
  -- ── Flash: lightning-fast navigation ──────────────────────────────
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts  = {
      labels    = "asdfghjklqwertyuiopzxcvbnm",
      search    = { mode = "fuzzy", incremental = true },
      jump      = { pos = "start", history = true, register = true, nohlsearch = true, autojump = true },
      label     = { uppercase = false, rainbow = { enabled = false, shade = 5 } },
      highlight = { backdrop = true, matches = true, priority = 5000, groups = { match = "FlashMatch", current = "FlashCurrent", backdrop = "FlashBackdrop", label = "FlashLabel" } },
      modes = {
        char = {
          enabled       = true,
          keys          = { "f", "F", "t", "T", ";", "," },
          search        = { wrap = false },
          highlight     = { backdrop = true },
          jump          = { register = false, autojump = true },
          label         = { exclude = "hjkliardc" },
        },
        search = { enabled = false },
        treesitter = {
          labels          = "abcdefghijklmnopqrstuvwxyz",
          jump            = { pos = "range", autojump = true },
          search          = { incremental = false },
          label           = { before = true, after = true, style = "inline" },
          highlight       = { backdrop = false, matches = false },
        },
        treesitter_search = {
          jump    = { pos = "range" },
          search  = { multi_window = true, wrap = true, incremental = false },
          remote_op = { restore = true },
          label   = { before = true, after = true, style = "inline" },
        },
        remote = { remote_op = { restore = true, motion = true } },
      },
      remote_op = { restore = false, motion = false },
    },
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash jump" },
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,             desc = "Flash remote" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
      { "<C-s>", mode = { "c" },           function() require("flash").toggle() end,             desc = "Toggle flash search" },
    },
  },

  -- ── Autopairs ──────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts  = {
      check_ts     = true,
      ts_config    = { lua = { "string" }, javascript = { "template_string" } },
      disable_filetype = { "TelescopePrompt", "spectre_panel" },
      fast_wrap    = {
        map        = "<M-e>",
        chars      = { "{", "[", "(", '"', "'" },
        pattern    = [=[[%'%"%)%>%]%)%}%,]]=],
        end_key    = "$",
        keys       = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight  = "Search",
        highlight_grey = "Comment",
      },
    },
    config = function(_, opts)
      local autopairs = require("nvim-autopairs")
      autopairs.setup(opts)
      -- blink.cmp integration
      local ok, blink = pcall(require, "blink.cmp.source.autopairs")
      if not ok then return end
      blink.setup()
    end,
  },

  -- ── Surround ───────────────────────────────────────────────────────
  -- v4+ dropped keymaps from setup(); defaults: ys/ds/cs/S/gS/<C-g>s
  {
    "kylechui/nvim-surround",
    version = "*",
    event   = "VeryLazy",
    opts    = {},
  },

  -- ── Comment ────────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    opts  = {
      padding    = true,
      sticky     = true,
      ignore     = "^$",
      toggler    = { line = "gcc", block = "gbc" },
      opleader   = { line = "gc", block = "gb" },
      extra      = { above = "gcO", below = "gco", eol = "gcA" },
      mappings   = { basic = true, extra = true },
    },
  },

  -- ── Mini text objects ──────────────────────────────────────────────
  {
    "echasnovski/mini.ai",
    version = false,
    event   = "VeryLazy",
    opts    = function()
      local ai = require("mini.ai")
      return {
        n_lines   = 500,
        custom_textobjects = {
          -- Whole buffer
          g = function()
            local from = { line = 1, col = 1 }
            local to   = { line = vim.fn.line("$"), col = math.max(vim.fn.getline("$"):len(), 1) }
            return { from = from, to = to }
          end,
          -- Function with treesitter
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer",    i = "@class.inner" }, {}),
        },
      }
    end,
  },

  -- ── Mini move ─────────────────────────────────────────────────────
  {
    "echasnovski/mini.move",
    version = false,
    event   = "VeryLazy",
    opts    = {
      mappings = {
        left       = "<M-h>",
        right      = "<M-l>",
        down       = "<M-j>",
        up         = "<M-k>",
        line_left  = "<M-h>",
        line_right = "<M-l>",
        line_down  = "<M-j>",
        line_up    = "<M-k>",
      },
      options = { reindent_linewise = true },
    },
  },

  -- ── Trouble: diagnostics panel ─────────────────────────────────────
  {
    "folke/trouble.nvim",
    cmd  = { "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                          desc = "Diagnostics (trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",             desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                  desc = "Symbols" },
      { "<leader>xL", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",   desc = "LSP definitions/refs" },
      { "<leader>xl", "<cmd>Trouble loclist toggle<cr>",                              desc = "Location list" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                              desc = "Quickfix list" },
      {
        "[q", function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then vim.notify(err, vim.log.levels.ERROR) end
          end
        end, desc = "Prev trouble/qflist item",
      },
      {
        "]q", function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then vim.notify(err, vim.log.levels.ERROR) end
          end
        end, desc = "Next trouble/qflist item",
      },
    },
    opts = {
      modes = {
        lsp = { win = { position = "right" } },
      },
    },
  },

  -- ── Todo comments ─────────────────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    cmd   = { "TodoTrouble", "TodoTelescope" },
    keys  = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Prev todo" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>",                      desc = "Todo (trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>",                            desc = "Find todos" },
    },
    opts = {
      signs      = true,
      sign_priority = 8,
      keywords = {
        FIX  = { icon = " ", color = "error",   alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint",    alt = { "INFO" } },
        TEST = { icon = "⏱ ", color = "test",   alt = { "TESTING", "PASSED", "FAILED" } },
      },
      gui_style = { fg = "NONE", bg = "BOLD" },
      merge_keywords  = true,
      highlight       = {
        multiline            = true,
        multiline_pattern    = "^.",
        multiline_context    = 10,
        before               = "",
        keyword              = "wide",
        after                = "fg",
        pattern              = [[.*<(KEYWORDS)\s*:]],
        comments_only        = true,
        max_line_len         = 400,
        exclude              = {},
      },
      colors = {
        error   = { "DiagnosticError",   "ErrorMsg",   "#C03030" },
        warning = { "DiagnosticWarn",    "WarningMsg", "#CC8A40" },
        info    = { "DiagnosticInfo",    "#C9A84C" },
        hint    = { "DiagnosticHint",    "#6BA888" },
        default = { "Identifier",        "#9B8EC4" },
        test    = { "Identifier",        "#68B8C8" },
      },
      search = {
        command   = "rg",
        args      = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
        pattern   = [[\b(KEYWORDS):]],
      },
    },
  },

  -- Word reference highlighting handled by snacks.words (see snacks.lua).
  -- ]] / [[ for jumping between refs is bound globally there.

  -- ── inc-rename: live rename preview ──────────────────────────────
  {
    "smjonas/inc-rename.nvim",
    cmd  = "IncRename",
    keys = {
      { "<leader>cr", function() return ":IncRename " .. vim.fn.expand("<cword>") end,
        expr = true, desc = "Rename (live preview)" },
    },
    opts = { input_buffer_type = "dressing" },
  },
}
