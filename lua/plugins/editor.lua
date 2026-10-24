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
    dependencies = {
      -- JSX needs {/* */} not //, this works out which one from the treesitter node
      { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
    },
    opts  = function()
      return {
        pre_hook   = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
        padding    = true,
        sticky     = true,
        ignore     = "^$",
        toggler    = { line = "gcc", block = "gbc" },
        opleader   = { line = "gc", block = "gb" },
        extra      = { above = "gcO", below = "gco", eol = "gcA" },
        mappings   = { basic = true, extra = true },
      }
    end,
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
    opts = function()
      local p = require("core.themes").palette()
      return {
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
        -- the hex at the end of each list is only a fallback, taken from the region it loaded in
        colors = {
          error   = { "DiagnosticError",   "ErrorMsg",   p.red },
          warning = { "DiagnosticWarn",    "WarningMsg", p.peach },
          info    = { "DiagnosticInfo",    p.yellow },
          hint    = { "DiagnosticHint",    p.teal },
          default = { "Identifier",        p.lavender },
          test    = { "Identifier",        p.sky },
        },
        search = {
          command   = "rg",
          args      = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
          pattern   = [[\b(KEYWORDS):]],
        },
      }
    end,
  },

  -- Word reference highlighting handled by snacks.words (see snacks.lua).
  -- ]] / [[ for jumping between refs is bound globally there.

  -- ── grug-far: search and replace across the project with a live preview ──
  {
    "MagicDuck/grug-far.nvim",
    cmd  = "GrugFar",
    keys = {
      {
        "<leader>fR",
        function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "Find and replace in project",
      },
      { "<leader>fR", function() require("grug-far").with_visual_selection() end, mode = "x", desc = "Find and replace selection" },
      {
        "<leader>fF",
        function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
        desc = "Find and replace in file",
      },
    },
    opts = { headerMaxWidth = 80, transient = true },
  },

  -- ── multicursor: real cursors, each with its own undo and registers ──
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    keys = {
      { "<C-n>",      function() require("multicursor-nvim").matchAddCursor(1) end,  mode = { "n", "x" }, desc = "Cursor on next match" },
      { "<A-Down>",   function() require("multicursor-nvim").lineAddCursor(1) end,   mode = { "n", "x" }, desc = "Cursor below" },
      { "<A-Up>",     function() require("multicursor-nvim").lineAddCursor(-1) end,  mode = { "n", "x" }, desc = "Cursor above" },
      { "<leader>Ma", function() require("multicursor-nvim").matchAllAddCursors() end, mode = { "n", "x" }, desc = "Cursor on every match" },
      { "<leader>Mt", function() require("multicursor-nvim").toggleCursor() end,     mode = { "n", "x" }, desc = "Pause cursors here" },
      { "<leader>Mr", function() require("multicursor-nvim").restoreCursors() end,   desc = "Bring back cleared cursors" },
      { "<leader>Ml", function() require("multicursor-nvim").alignCursors() end,     desc = "Align cursors" },
      { "<leader>Md", function() require("multicursor-nvim").diagnosticMatchCursors() end, mode = { "n", "x" }, desc = "Cursor on each diagnostic" },
    },
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      -- these keys only exist while there is more than one cursor, so they never shadow the usual ones
      mc.addKeymapLayer(function(layer)
        layer({ "n", "x" }, "n", function() mc.matchAddCursor(1) end)
        layer({ "n", "x" }, "N", function() mc.matchAddCursor(-1) end)
        layer({ "n", "x" }, "q", function() mc.matchSkipCursor(1) end)
        layer({ "n", "x" }, "Q", function() mc.matchSkipCursor(-1) end)
        layer({ "n", "x" }, "<Left>", mc.prevCursor)
        layer({ "n", "x" }, "<Right>", mc.nextCursor)
        layer({ "n", "x" }, "<leader>Mx", mc.deleteCursor)
        layer("n", "<Esc>", function()
          if not mc.cursorsEnabled() then return mc.enableCursors() end
          mc.clearCursors()
        end)
      end)
    end,
  },

  -- ── inc-rename: live rename preview ──────────────────────────────
  {
    "smjonas/inc-rename.nvim",
    -- F2 and <leader>cr are bound per buffer in core/dive once an LSP attaches
    cmd  = "IncRename",
    opts = {},
  },
}
