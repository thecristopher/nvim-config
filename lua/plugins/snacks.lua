-- snacks.nvim — folke's all-in-one quality-of-life suite

return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      -- the start screen is the inventory HUD (core/hud), this stays off so the two never fight
      dashboard = { enabled = false },

      -- ── Notifications ──────────────────────────────────────────────
      notifier = {
        enabled = true,
        timeout = 4000,
        width = { min = 40, max = 0.4 },
        height = { min = 1, max = 0.6 },
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort = { "level", "added" },
        icons = { error = "󰅚 ", warn = "󰊌 ", info = "󰋽 ", debug = "󰒄 ", trace = "✎ " },
        style = "compact",
        top_down = true,
      },

      -- ── Indent guides ──────────────────────────────────────────────
      indent = {
        enabled = false, -- replaced by indent-blankline.nvim (rainbow palette)
        indent = { char = "│", hl = "IblIndent" },
        scope = { enabled = true, char = "│", hl = "IblScope", underline = false },
        chunk = { enabled = false },
        animate = { enabled = false },
        filter = function(buf)
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
        end,
      },

      -- ── Smooth scroll ──────────────────────────────────────────────
      scroll = {
        enabled = true,
        animate = { duration = { step = 12, total = 180 }, easing = "linear" },
        animate_repeat = { delay = 120, duration = { step = 5, total = 50 }, easing = "linear" },
        filter = function(buf)
          return vim.g.snacks_scroll ~= false
            and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= "terminal"
        end,
      },

      -- ── Word highlights ────────────────────────────────────────────
      words = {
        enabled = true,
        debounce = 150,
        notify_jump = false,
        modes = { "n", "i", "c" },
      },

      -- ── Status column ──────────────────────────────────────────────
      statuscolumn = {
        enabled = true,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = { open = false, git_hl = false },
        git = { patterns = { "GitSign", "MiniDiffSign" } },
        refresh = 50,
      },

      -- ── Images: real pixels on kitty, Ghostty and WezTerm, an info page elsewhere ──
      image = { enabled = true },

      -- ── Input / Picker / Lazygit ──────────────────────────────────
      input = { enabled = true },
      picker = { enabled = true },
      lazygit = { enabled = true },

      -- ── Utilities ─────────────────────────────────────────────────
      bufdelete = { enabled = true },
      quickfile = { enabled = true },
      bigfile = {
        enabled = true,
        notify = true,
        size = 1.5 * 1024 * 1024,
        -- also catches minified bundles: average line over 1000 chars
        line_length = 1000,
        setup = function(ctx)
          vim.cmd("syntax clear")
          vim.opt_local.spell = false
          vim.opt_local.undofile = false
          vim.opt_local.list = false
          vim.opt_local.foldmethod = "manual"
          vim.b[ctx.buf].minianimate_disable = true
          vim.b[ctx.buf].snacks_scroll = false
          vim.b[ctx.buf].snacks_indent = false
          vim.b[ctx.buf].completion = false
          Snacks.util.wo(ctx.win, { conceallevel = 0, cursorline = false, statuscolumn = "" })
        end,
      },
      git = { enabled = true },
      gitbrowse = { enabled = true },
      rename = { enabled = true },
      scope = { enabled = true },
      animate = { enabled = true },
      dim = { enabled = false },
      debug = { enabled = false },
      profiler = { enabled = false },
    },

    keys = {
      {
        "<leader>gl",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git browse",
      },
      {
        "<leader>gL",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Git log (root)",
      },
      {
        "]]",
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next word ref",
      },
      {
        "[[",
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev word ref",
      },
      {
        "<leader>N",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification history",
      },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          if not _G.Snacks then
            _G.Snacks = require("snacks")
          end
        end,
      })
    end,
  },
}
