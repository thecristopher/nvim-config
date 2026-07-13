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


-- ── Git-aware recent project finder ──────────────────────────────────────────
-- Only lists actual git repositories (via Snacks.git.get_root, which also
-- handles worktrees/submodules where `.git` is a file, not a directory).
-- Loose files opened outside a repo are skipped rather than counted as
-- "projects", so they can't crowd real repos out of the limited slots.
--
-- `v:oldfiles` alone misses a project you switched into (`cd`, dashboard's
-- "Open Folder", or `nvim .`) but never opened a specific file buffer in --
-- it only tracks files that became real buffers, and only that at all if
-- shada ever wrote them. So directory switches are tracked live to a state
-- file via DirChanged/VimEnter below, and used as the primary source; oldfiles
-- is kept as a fallback for history predating this tracker.
local project_state_file = vim.fn.stdpath("state") .. "/eldentree_recent_projects.json"

local function load_tracked_projects()
  local ok, lines = pcall(vim.fn.readfile, project_state_file)
  if not ok then return {} end
  local ok2, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (ok2 and type(decoded) == "table") and decoded or {}
end

local function record_project(dir)
  if not (_G.Snacks and Snacks.git) then return end
  local root = Snacks.git.get_root(dir)
  if not root then return end
  local list = load_tracked_projects()
  for i = #list, 1, -1 do
    if list[i] == root then table.remove(list, i) end
  end
  table.insert(list, 1, root)
  while #list > 20 do table.remove(list) end
  pcall(vim.fn.writefile, { vim.json.encode(list) }, project_state_file)
end

vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
  callback = function() record_project(vim.loop.cwd()) end,
})

local function recent_projects(limit)
  local result, seen = {}, {}

  local function add(proj)
    if not proj or seen[proj] or #result >= limit then return end
    seen[proj] = true
    local home    = vim.env.HOME or ""
    local display = home ~= "" and proj:gsub("^" .. home, "~") or proj
    result[#result + 1] = {
      key    = tostring(#result + 1),
      icon   = "󰊢 ",
      desc   = display,
      action = function()
        vim.fn.chdir(proj)
        vim.cmd("Neotree dir=" .. vim.fn.fnameescape(proj) .. " toggle")
      end,
    }
  end

  for _, proj in ipairs(load_tracked_projects()) do
    if #result >= limit then break end
    if vim.fn.isdirectory(proj) == 1 then add(proj) end
  end

  for _, file in ipairs(vim.v.oldfiles or {}) do
    if #result >= limit then break end
    if not file:match("^/tmp")
      and not file:match("COMMIT_EDITMSG")
      and vim.fn.filereadable(file) == 1
    then
      add(Snacks.git.get_root(file))
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
            { icon = "󰍉 ", key = "f", desc = "Find File",    action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "󰋚 ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "󰊄 ", key = "g", desc = "Live Grep",    action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "󰝒 ", key = "n", desc = "New File",     action = ":ene | startinsert" },
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
            { icon = "󰒓 ", key = "c", desc = "Config",       action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Lazy",         action = ":Lazy" },
            { icon = "󰏗 ", key = "m", desc = "Mason",         action = ":Mason" },
            { icon = "󰆔 ", key = "s", desc = "Restore Session", action = function() require("persistence").load() end },
            { icon = "󰐥 ", key = "q", desc = "Quit",           action = ":qa" },
          },
        },

        -- Show "parentDir/filename" instead of the default home-relative
        -- path. The stock formatter shortens long paths by truncating the
        -- tail of the filename itself, which collapses repeated names like
        -- Input/index.tsx and Button/index.tsx into indistinguishable text.
        formats = {
          file = function(item)
            local fname  = vim.fn.fnamemodify(item.file, ":t")
            local parent = vim.fn.fnamemodify(item.file, ":h:t")
            return parent ~= "" and {
              { parent .. "/", hl = "dir" },
              { fname, hl = "file" },
            } or { { fname, hl = "file" } }
          end,
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
            cmd     = "chafa --format=symbols --symbols=half --size=46x28 --colors=full " .. _img,
            height  = 28,
            width   = 46,
            ttl     = 3600 * 24 * 30,
            indent  = 2,
            padding = { 1, 0, 0, 0 },
          },

          -- Elden Ring title block below art
          {
            pane    = 1,
            padding = { 1, 0, 0, 0 },
            text    = {
              { "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈\n", hl = "SnacksDashboardHeader" },
              { "       E  L  D  E  N     R  I  N  G         \n",   hl = "SnacksDashboardHeader" },
              { "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈\n", hl = "SnacksDashboardHeader" },
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
          function()
            local ok, lazy_mod = pcall(require, "lazy")
            local plug = ok and lazy_mod.stats().count or 0
            return {
              {
                pane    = 1,
                padding = { 2, 0, 0, 0 },
                text    = {
                  { ("     ⚡ Neovim %s  ·  %d plugins\n"):format(_nvim_v, plug), hl = "SnacksDashboardFooter" },
                },
              },
            }
          end,

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
              { "  ◈   C O D E   W O R K S P A C E   ◈\n",   hl = "SnacksDashboardHeader" },
              { "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈\n",   hl = "SnacksDashboardDesc" },
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
              { "  ◈── Recent Files ─────────────────────◈\n", hl = "SnacksDashboardDesc" },
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
              { "  ◈── Recent Projects ──────────────────◈\n", hl = "SnacksDashboardDesc" },
            },
          },
          function()
            local items = recent_projects(3)
            if #items == 0 then
              return {
                {
                  pane    = 2,
                  indent  = 2,
                  padding = { 0, 0, 1, 0 },
                  text    = { { "    No recent projects found\n", hl = "SnacksDashboardFooter" } },
                },
              }
            end
            for _, item in ipairs(items) do
              item.pane    = 2
              item.indent  = 2
            end
            items[#items].padding = { 0, 0, 1, 0 }
            return items
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
