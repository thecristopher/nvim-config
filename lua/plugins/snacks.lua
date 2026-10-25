-- snacks.nvim — folke's all-in-one quality-of-life suite

-- ── Dashboard flavour (evaluated once at startup) ────────────────────────────
local hour     = tonumber(os.date("%H"))
local greeting = hour < 5 and "The night is long" or hour < 12 and "Good morning" or hour < 18 and "Good afternoon" or "Good evening"
local today    = os.date("%A, %B %d  ·  %I:%M %p")
local nvim_version = tostring(vim.version()):match("^[%d.]+")
-- the franchise of the day names the traveler, the hub and the safe havens
local function words() return require("core.franchise").current().words end
-- the hub owns the message so its quill knows which line to write in
local function message() return require("core.hub").message() end
-- portraits are pre-cropped and contrast lifted so the character survives 46 columns of half blocks
local function portrait()
  return vim.fn.stdpath("config") .. "/images/portraits/" .. require("core.themes").current().portrait
end

-- snacks caches terminal output by its command, so the file's mtime rides along and a new portrait
-- dropped in under the same name shows up at once instead of after the 30 day cache
local function portrait_cmd()
  local stat = vim.uv.fs_stat(portrait())
  local version = stat and stat.mtime.sec or 0
  return ("PORTRAIT_VERSION=%d chafa --format=symbols --symbols=half --size=46x28 --colors=full --work=9 %s")
    :format(version, vim.fn.shellescape(portrait()))
end

-- the art alone is 46x28, so only show it when there is room for both panes,
-- and a region whose portrait was not dropped into images/portraits yet simply goes without
local function room_for_art()
  return vim.o.columns >= 128 and vim.o.lines >= 42 and vim.fn.executable("chafa") == 1
    and vim.fn.filereadable(portrait()) == 1
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

-- snacks calls any folder holding a .git a repo, the repo scanner also checks it has a HEAD
local function quest_root()
  return require("core.repos").root()
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
            { icon = "󰊢 ", key = "p", desc = words().sites,     action = function() require("core.repos").pick() end },
            { icon = "󰉋 ", key = "e", desc = "Explorer",        action = ":Neotree toggle" },
            { icon = "󰝰 ", key = "o", desc = "Open Folder",     action = function() require("core.repos").open_folder() end },
            { icon = "󰝒 ", key = "n", desc = "New File",        action = ":ene | startinsert" },
            { icon = "󰆔 ", key = "s", desc = "Restore Session", action = function() require("persistence").load() end },
            { icon = "󰏘 ", key = "t", desc = words().choose_region, action = function() require("core.themes").pick() end },
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
          -- ════ LEFT PANE: the region's champion ═══════════════════
          function()
            return {
              pane    = 1,
              section = "terminal",
              enabled = room_for_art,
              cmd     = portrait_cmd(),
              height  = 28,
              width   = 46,
              ttl     = 3600 * 24 * 30,
              indent  = 7,
              padding = { 1, 0, 0, 0 },
            }
          end,
          function()
            local name = require("core.hub.actions").spaced(require("core.themes").current().character)
            return {
              pane    = 1,
              padding = { 1, 0, 0, 0 },
              align   = "center",
              text    = {
                { "◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈\n", hl = "SnacksDashboardHeader" },
                { name .. "\n",                                       hl = "SnacksDashboardHeader" },
                { "◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈",   hl = "SnacksDashboardHeader" },
              },
            }
          end,
          function()
            return {
              pane    = 1,
              padding = { 1, 0, 0, 0 },
              align   = "center",
              text    = {
                { greeting .. ", " .. words().traveler .. "\n", hl = "SnacksDashboardTitle" },
                { today .. "\n\n",                             hl = "SnacksDashboardFooter" },
                { '"' .. message() .. '"',                     hl = "SnacksDashboardDesc" },
              },
            }
          end,
          function()
            local stats = require("lazy").stats()
            local repos = #require("core.repos").list()
            return {
              pane    = 1,
              padding = { 1, 0, 0, 0 },
              align   = "center",
              text    = {
                { ("⚡ Neovim %s  ·  %d plugins  ·  %.0fms  ·  %d %s  ·  %s"):format(
                    nvim_version, stats.count, stats.startuptime, repos, words().sites_found, require("core.themes").current().title),
                  hl = "SnacksDashboardFooter" },
              },
            }
          end,

          -- the results screen of the last run, only in worlds that rank you
          function()
            local summary = require("core.results").summary()
            if not summary then return {} end
            return { pane = 1, padding = { 1, 0, 0, 0 }, align = "center", text = { { summary, hl = "SnacksDashboardHeader" } } }
          end,

          -- ════ RIGHT PANE: the Roundtable Hold or the Safe Room ════
          function()
            local title = require("core.banner.actions").spaced(words().hub)
            return {
              pane    = 2,
              padding = { 2, 0, 1, 0 },
              align   = "center",
              text    = { { "◈   " .. title .. "   ◈", hl = "SnacksDashboardHeader" } },
            }
          end,
          { pane = 2, section = "keys", indent = 2, padding = { 0, 0, 0, 0 } },

          function() return heading(words().sites, 2) end,
          function()
            local items = require("core.repos").dashboard_items(6)
            if #items == 0 then
              return { pane = 2, indent = 4, text = { { words().no_sites, hl = "SnacksDashboardFooter" } } }
            end
            for _, item in ipairs(items) do
              item.pane, item.indent = 2, 2
            end
            return items
          end,

          heading("Recent Files", 2),
          { pane = 2, section = "recent_files", cwd = false, limit = 4, indent = 2 },

          function()
            local root = quest_root()
            if not root then return {} end
            return {
              heading("Current Quest  " .. (require("core.repos").branch(root) or ""), 2),
              {
                pane    = 2,
                section = "terminal",
                -- a stderr line taller than the section would push the whole hub down
                cmd     = ("git -C %s --no-pager diff --stat -B -M -C 2>/dev/null | tail -n 6"):format(vim.fn.shellescape(root)),
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

      -- ── Images: real pixels on kitty, Ghostty and WezTerm, an info page elsewhere ──
      image = { enabled = true },

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
      { "]]",         function() Snacks.words.jump(vim.v.count1) end,   desc = "Next word ref" },
      { "[[",         function() Snacks.words.jump(-vim.v.count1) end,  desc = "Prev word ref" },
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
