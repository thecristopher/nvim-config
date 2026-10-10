-- snacks.nvim — folke's all-in-one quality-of-life suite

-- ── Dashboard flavour (evaluated once at startup) ────────────────────────────
local hour     = tonumber(os.date("%H"))
local greeting = hour < 5 and "The night is long" or hour < 12 and "Good morning" or hour < 18 and "Good afternoon" or "Good evening"
local today    = os.date("%A, %B %d  ·  %I:%M %p")
local nvim_version = tostring(vim.version()):match("^[%d.]+")
local quotes = {
  "Guidance of grace shall lead the way.",
  "Rise, and let grace light your path.",
  "The strength to overcome is within thee.",
  "May the Erdtree illuminate your work.",
  "Thou art yet to lose thy grace.",
  "Be not consumed by doubt. Press onward.",
  "Every line of code is a step toward the Elden Ring.",
  "Try refactoring, but hole.",
  "Seek the lands between your functions.",
  "Fear not the stack trace, Tarnished.",
}
math.randomseed(os.time())
local quote     = quotes[math.random(#quotes)]
local art_image = vim.fn.stdpath("config") .. "/images/malenia.jpg"

-- the art alone is 46x28, so only show it when there is room for both panes
local function room_for_art()
  return vim.o.columns >= 128 and vim.o.lines >= 42 and vim.fn.executable("chafa") == 1
end

local function rule(label)
  local line = ("◈── %s "):format(label)
  return line .. ("─"):rep(math.max(4, 44 - vim.api.nvim_strwidth(line))) .. "◈"
end

local function heading(label, pane)
  return {
    pane    = pane,
    padding = { 1, 0, 0, 0 },
    indent  = 2,
    text    = { { rule(label), hl = "SnacksDashboardDesc" } },
  }
end

local function in_git_repo()
  return Snacks.git.get_root() ~= nil
end

-- ─────────────────────────────────────────────────────────────────────────────
return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy     = false,
    opts = {
      -- ── Dashboard: the Roundtable Hold ─────────────────────────────
      dashboard = {
        enabled = true,
        width   = 60,
        preset  = {
          keys = {
            { icon = "󰍉 ", key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "󰊄 ", key = "g", desc = "Live Grep",       action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "󰋚 ", key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "󰊢 ", key = "p", desc = "Sites of Grace",  action = function() require("core.repos").pick() end },
            { icon = "󰉋 ", key = "e", desc = "Explorer",        action = ":Neotree toggle" },
            { icon = "󰝒 ", key = "n", desc = "New File",        action = ":ene | startinsert" },
            { icon = "󰆔 ", key = "s", desc = "Restore Session", action = function() require("persistence").load() end },
            { icon = "󰒓 ", key = "c", desc = "Config",          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Lazy",            action = ":Lazy" },
            { icon = "󰏗 ", key = "m", desc = "Mason",           action = ":Mason" },
            { icon = "󰐥 ", key = "q", desc = "Quit",            action = ":qa" },
          },
        },

        -- Show "parentDir/filename" so Input/index.tsx and Button/index.tsx stay distinguishable
        formats = {
          file = function(item)
            local fname  = vim.fn.fnamemodify(item.file, ":t")
            local parent = vim.fn.fnamemodify(item.file, ":h:t")
            return parent ~= "" and {
              { parent .. "/", hl = "dir" },
              { fname, hl = "file" },
            } or { { fname, hl = "file" } }
          end,
          title = { "%s", hl = "SnacksDashboardTitle" },
        },

        sections = {
          -- ════ LEFT PANE: the Erdtree ═════════════════════════════
          {
            pane    = 1,
            section = "terminal",
            enabled = room_for_art,
            cmd     = "chafa --format=symbols --symbols=half --size=46x28 --colors=full " .. art_image,
            height  = 28,
            width   = 46,
            ttl     = 3600 * 24 * 30,
            indent  = 7,
            padding = { 1, 0, 0, 0 },
          },
          {
            pane    = 1,
            padding = { 1, 0, 0, 0 },
            align   = "center",
            text    = {
              { "◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈\n", hl = "SnacksDashboardHeader" },
              { "E  L  D  E  N  T  R  E  E\n",                       hl = "SnacksDashboardHeader" },
              { "◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈",   hl = "SnacksDashboardHeader" },
            },
          },
          {
            pane    = 1,
            padding = { 1, 0, 0, 0 },
            align   = "center",
            text    = {
              { greeting .. ", Tarnished\n", hl = "SnacksDashboardTitle" },
              { today .. "\n\n",             hl = "SnacksDashboardFooter" },
              { '"' .. quote .. '"',         hl = "SnacksDashboardDesc" },
            },
          },
          function()
            local stats = require("lazy").stats()
            local repos = #require("core.repos").list()
            return {
              pane    = 1,
              padding = { 1, 0, 0, 0 },
              align   = "center",
              text    = {
                { ("⚡ Neovim %s  ·  %d plugins  ·  %.0fms  ·  %d graces found"):format(
                    nvim_version, stats.count, stats.startuptime, repos),
                  hl = "SnacksDashboardFooter" },
              },
            }
          end,

          -- ════ RIGHT PANE: the Roundtable Hold ════════════════════
          {
            pane    = 2,
            padding = { 2, 0, 1, 0 },
            align   = "center",
            text    = { { "◈   R O U N D T A B L E   H O L D   ◈", hl = "SnacksDashboardHeader" } },
          },
          { pane = 2, section = "keys", indent = 2, padding = { 0, 0, 0, 0 } },

          heading("Sites of Grace", 2),
          function()
            local items = require("core.repos").dashboard_items(6)
            if #items == 0 then
              return { pane = 2, indent = 4, text = { { "No graces yet. Scanning your realms…", hl = "SnacksDashboardFooter" } } }
            end
            for _, item in ipairs(items) do
              item.pane, item.indent = 2, 2
            end
            return items
          end,

          heading("Recent Files", 2),
          { pane = 2, section = "recent_files", cwd = false, limit = 4, indent = 2 },

          function()
            if not in_git_repo() then return {} end
            return {
              heading("Current Quest  " .. (require("core.repos").branch(Snacks.git.get_root()) or ""), 2),
              {
                pane    = 2,
                section = "terminal",
                cmd     = "git --no-pager diff --stat -B -M -C | tail -n 6",
                height  = 6,
                indent  = 4,
                ttl     = 0,
              },
            }
          end,
        },
      },

      -- ── Notifications ──────────────────────────────────────────────
      notifier = {
        enabled = true,
        timeout = 4000,
        width   = { min = 40, max = 0.4 },
        height  = { min = 1,  max = 0.6 },
        margin  = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort    = { "level", "added" },
        icons   = { error = "󰅚 ", warn = "󰊌 ", info = "󰋽 ", debug = "󰒄 ", trace = "✎ " },
        style   = "compact",
        top_down = true,
      },

      -- ── Indent guides ──────────────────────────────────────────────
      indent = {
        enabled    = false,  -- replaced by indent-blankline.nvim (rainbow palette)
        indent     = { char = "│", hl = "IblIndent" },
        scope      = { enabled = true, char = "│", hl = "IblScope", underline = false },
        chunk      = { enabled = false },
        animate    = { enabled = false },
        filter     = function(buf)
          return vim.g.snacks_indent ~= false
            and vim.b[buf].snacks_indent ~= false
            and vim.bo[buf].buftype == ""
        end,
      },

      -- ── Smooth scroll ──────────────────────────────────────────────
      scroll = {
        enabled      = true,
        animate      = { duration = { step = 12, total = 180 }, easing = "linear" },
        animate_repeat = { delay = 120, duration = { step = 5, total = 50 }, easing = "linear" },
        filter       = function(buf)
          return vim.g.snacks_scroll ~= false
            and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= "terminal"
        end,
      },

      -- ── Word highlights ────────────────────────────────────────────
      words = {
        enabled     = true,
        debounce    = 150,
        notify_jump = false,
        modes       = { "n", "i", "c" },
      },

      -- ── Status column ──────────────────────────────────────────────
      statuscolumn = {
        enabled = true,
        left    = { "mark", "sign" },
        right   = { "fold", "git" },
        folds   = { open = false, git_hl = false },
        git     = { patterns = { "GitSign", "MiniDiffSign" } },
        refresh = 50,
      },

      -- ── Input / Picker / Zen / Lazygit ────────────────────────────
      input      = { enabled = true },
      picker     = { enabled = true },
      lazygit    = { enabled = true },
      zen = {
        enabled  = true,
        toggles  = { dim = true, git_signs = false, diagnostics = false, inlay_hints = false },
        show     = { statusline = false, tabline = false },
        win      = { backdrop = { transparent = true, blend = 40 }, width = 100 },
      },

      -- ── Utilities ─────────────────────────────────────────────────
      bufdelete  = { enabled = true },
      quickfile  = { enabled = true },
      bigfile    = {
        enabled = true,
        notify  = true,
        size    = 1.5 * 1024 * 1024,
        -- also catches minified bundles: average line over 1000 chars
        line_length = 1000,
        setup   = function(ctx)
          vim.cmd("syntax clear")
          vim.opt_local.spell      = false
          vim.opt_local.undofile   = false
          vim.opt_local.list       = false
          vim.opt_local.foldmethod = "manual"
          vim.b[ctx.buf].minianimate_disable = true
          vim.b[ctx.buf].snacks_scroll       = false
          vim.b[ctx.buf].snacks_indent       = false
          vim.b[ctx.buf].completion          = false
          Snacks.util.wo(ctx.win, { conceallevel = 0, cursorline = false, statuscolumn = "" })
        end,
      },
      git        = { enabled = true },
      gitbrowse  = { enabled = true },
      rename     = { enabled = true },
      scope      = { enabled = true },
      animate    = { enabled = true },
      dim        = { enabled = false },
      debug      = { enabled = false },
      profiler   = { enabled = false },
    },

    keys = {
      { "<leader>gl", function() Snacks.lazygit() end,                  desc = "Lazygit" },
      { "<leader>gB", function() Snacks.gitbrowse() end,                desc = "Git browse" },
      { "<leader>gL", function() Snacks.lazygit.log() end,              desc = "Git log (root)" },
      { "]]",         function() Snacks.words.jump(vim.v.count1) end,   desc = "Next word ref", mode = { "n", "t" } },
      { "[[",         function() Snacks.words.jump(-vim.v.count1) end,  desc = "Prev word ref", mode = { "n", "t" } },
      { "<leader>N",  function() Snacks.notifier.show_history() end,    desc = "Notification history" },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern  = "VeryLazy",
        callback = function()
          if not _G.Snacks then _G.Snacks = require("snacks") end
        end,
      })
    end,
  },
}
