-- snacks.nvim — folke's all-in-one quality-of-life suite

return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      -- the start screen is the inventory HUD (core/hud), this stays off so the two never fight
      dashboard = { enabled = false },

      -- long messages wrap inside the notification instead of running off its edge
      styles = { notification = { wo = { wrap = true } } },

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
        -- the game's messages: the franchise's word for the level and the hour, see core/chrome
        style = function(buf, notif, ctx)
          require("core.chrome.notify").style(buf, notif, ctx)
        end,
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
      picker = {
        enabled = true,
        -- each franchise lays the picker out its own way and frames its titles, see core/chrome
        layouts = {
          grace = require("core.chrome.picker").GRACE,
          inventory = require("core.chrome.picker").INVENTORY,
        },
        layout = {
          cycle = true,
          preset = function()
            return require("core.chrome.picker").preset()
          end,
          config = function(layout)
            return require("core.chrome.picker").frame(layout)
          end,
        },
      },
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
      -- ── Pickers: one look everywhere, file:line in the files picker jumps to the line ──
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fa",
        function()
          Snacks.picker.files({ hidden = true, ignored = true })
        end,
        desc = "Find all files, hidden and ignored too",
      },
      {
        "<leader>fr",
        function()
          require("core.find").recent()
        end,
        desc = "Recent files (<C-a> flips repo and everywhere)",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Live grep",
      },
      {
        "<leader>fG",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help",
      },
      {
        "<leader>fm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>fk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command history",
      },
      {
        "<leader>f/",
        function()
          Snacks.picker.search_history()
        end,
        desc = "Search history",
      },
      {
        "<leader>f.",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume the last picker",
      },
      {
        "<leader>fn",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Neovim config",
      },
      {
        "<leader>gC",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git commits",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git status",
      },
      {
        "<leader>gS",
        function()
          Snacks.picker.git_stash()
        end,
        desc = "Git stash",
      },
      {
        "<leader>gb",
        function()
          require("core.find").branches()
        end,
        desc = "Git branches (each with its session)",
      },
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
