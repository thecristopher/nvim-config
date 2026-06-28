-- snacks.nvim — folke's all-in-one quality-of-life suite

-- ── Dashboard greeting data (evaluated once at startup) ──────────────────────
local _hour    = tonumber(os.date("%H"))
local _greet   = _hour < 12 and "Good morning" or _hour < 18 and "Good afternoon" or "Good evening"
local _date    = os.date("  %A, %B %d  •  %I:%M %p")
local _nvim_v  = (function() local v = vim.version(); return ("v%d.%d.%d"):format(v.major, v.minor, v.patch) end)()
local _er_quotes = {
  "Guidance of grace shall lead the way.",
  "Rise, and let grace light your path.",
  "The strength to overcome is within thee.",
  "May the Erdtree illuminate your work.",
  "Thou art yet to lose thy grace.",
  "Be not consumed by doubt. Press onward.",
  "Every line of code — a step toward the Elden Ring.",
}
math.randomseed(os.time())
local _quote  = _er_quotes[math.random(#_er_quotes)]
local _img    = vim.fn.stdpath("config") .. "/images/malenia.jpg"
local _img_fmt = (function()
  if vim.env.TERM_PROGRAM == "iTerm.app"                          then return "iterm"  end
  if (vim.env.TERM or ""):find("kitty") or vim.env.KITTY_WINDOW_ID then return "kitty"  end
  return "sixel"  -- Konsole and other modern Linux terminals
end)()


-- ── Git-aware recent project finder ──────────────────────────────────────────
local function recent_projects(limit)
  local result, seen = {}, {}
  for _, file in ipairs(vim.v.oldfiles or {}) do
    if #result >= limit then break end
    if not file:match("^/tmp")
      and not file:match("COMMIT_EDITMSG")
      and vim.fn.filereadable(file) == 1
    then
      local dir  = vim.fn.fnamemodify(file, ":h")
      -- Walk up to git root (max 8 levels)
      local proj = dir
      local is_git = false
      local d = dir
      for _ = 1, 8 do
        if vim.fn.isdirectory(d .. "/.git") == 1 then
          proj, is_git = d, true
          break
        end
        local up = vim.fn.fnamemodify(d, ":h")
        if up == d then break end
        d = up
      end
      if not seen[proj] then
        seen[proj] = true
        local home    = vim.env.HOME or ""
        local display = home ~= "" and proj:gsub("^" .. home, "~") or proj
        result[#result + 1] = {
          key    = tostring(#result + 1),
          icon   = is_git and "󰊢 " or "󰉋 ",
          desc   = display,
          action = function()
            vim.fn.chdir(proj)
            vim.cmd("Neotree dir=" .. vim.fn.fnameescape(proj) .. " toggle")
          end,
        }
      end
    end
  end
  return result
end

-- ─────────────────────────────────────────────────────────────────────────────
return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy     = false,
    opts = {
      -- ── Dashboard ───────────────────────────────────────────────────
      dashboard = {
        enabled = true,
        preset  = {
          -- Keys shown in right pane (code-oriented, folder-aware)
          keys = {
            { icon = " ", key = "f", desc = "Find File",    action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "g", desc = "Live Grep",    action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "n", desc = "New File",     action = ":ene | startinsert" },
            { icon = "󰉋 ", key = "e", desc = "Explorer",    action = ":Neotree toggle" },
            { icon = "󰉋 ", key = "o", desc = "Open Folder", action = function()
                vim.ui.input(
                  { prompt = "  Open folder: ", default = vim.fn.getcwd(), completion = "dir" },
                  function(dir)
                    if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
                      vim.fn.chdir(dir)
                      vim.cmd("Neotree dir=" .. vim.fn.fnameescape(dir) .. " toggle")
                    end
                  end
                )
              end },
            { icon = " ", key = "c", desc = "Config",       action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Lazy",         action = ":Lazy" },
            { icon = " ", key = "m", desc = "Mason",         action = ":Mason" },
            { icon = " ", key = "q", desc = "Quit",          action = ":qa" },
          },
        },

        -- ── Two-column layout ───────────────────────────────────────
        sections = {

          -- ════════════════════════════════════════
          -- LEFT PANE  (pane = 1): Art + Identity
          -- ════════════════════════════════════════

          -- Malenia artwork rendered with chafa
          {
            pane    = 1,
            section = "terminal",
            cmd     = "chafa --format=symbols --symbols=braille --size=46x28 --colors=full " .. _img,
            height  = 28,
            width   = 46,
            ttl     = 3600 * 24 * 30,
            indent  = 2,
            padding = { 1, 0, 0, 0 },
          },

          -- Horizontal rule below art
          {
            pane    = 1,
            padding = { 1, 0, 0, 0 },
            text    = {
              { "     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", hl = "SnacksDashboardDesc" },
            },
          },

          -- Greeting, date, quote
          {
            pane    = 1,
            padding = { 1, 0, 0, 0 },
            text    = {
              { "     " .. _greet .. ", Tarnished\n",      hl = "SnacksDashboardHeader" },
              { "     " .. _date  .. "\n\n",               hl = "SnacksDashboardFooter" },
              { '     "' .. _quote .. '"\n',               hl = "SnacksDashboardDesc" },
            },
          },

          -- Neovim version at the bottom-left
          {
            pane    = 1,
            padding = { 2, 0, 0, 0 },
            fn = function()
              local ok, lazy_mod = pcall(require, "lazy")
              local plug = ok and lazy_mod.stats().count or 0
              return {
                {
                  text = {
                    { ("     ⚡ Neovim %s  ·  %d plugins\n"):format(_nvim_v, plug), hl = "SnacksDashboardFooter" },
                  },
                },
              }
            end,
          },

          -- Startup time (shown in left pane below version)
          {
            pane    = 1,
            section = "startup",
            padding = { 0, 0, 0, 0 },
          },

          -- ════════════════════════════════════════
          -- RIGHT PANE (pane = 2): Workspace
          -- ════════════════════════════════════════

          -- Right-pane title
          {
            pane    = 2,
            padding = { 2, 0, 1, 0 },
            text    = {
              { "  ⚔   C O D E   W O R K S P A C E   ⚔\n",  hl = "SnacksDashboardHeader" },
              { "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n",  hl = "SnacksDashboardDesc" },
            },
          },

          -- Action keys
          {
            pane    = 2,
            section = "keys",
            gap     = 1,
            padding = { 0, 0, 1, 0 },
            indent  = 2,
          },

          -- ── Recent Files ──────────────────────────
          {
            pane    = 2,
            padding = { 1, 0, 0, 0 },
            text    = {
              { "  ─── Recent Files ────────────────────\n", hl = "SnacksDashboardDesc" },
            },
          },
          {
            pane    = 2,
            section = "recent_files",
            cwd     = false,
            limit   = 4,
            indent  = 2,
            padding = { 0, 0, 1, 0 },
          },

          -- ── Recent Projects ───────────────────────
          {
            pane    = 2,
            padding = { 1, 0, 0, 0 },
            text    = {
              { "  ─── Recent Projects ─────────────────\n", hl = "SnacksDashboardDesc" },
            },
          },
          {
            pane    = 2,
            indent  = 2,
            padding = { 0, 0, 1, 0 },
            fn = function()
              local items = recent_projects(3)
              if #items == 0 then
                return {
                  { text = { { "    No recent projects found\n", hl = "SnacksDashboardFooter" } } },
                }
              end
              return items
            end,
          },
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
        icons   = { error = " ", warn = " ", info = " ", debug = " ", trace = "✎ " },
        style   = "compact",
        top_down = true,
      },

      -- ── Indent guides ──────────────────────────────────────────────
      indent = {
        enabled    = true,
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
        setup   = function(ctx)
          vim.cmd("syntax clear")
          vim.opt_local.spell      = false
          vim.opt_local.undofile   = false
          vim.opt_local.list       = false
          vim.opt_local.foldmethod = "manual"
          Snacks.util.wo(ctx.win, { conceallevel = 0 })
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
      { "<leader>gf", function() Snacks.lazygit.log_file() end,         desc = "Git log (file)" },
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
