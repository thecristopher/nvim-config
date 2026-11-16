-- Diving through code: inline peek windows and clickable breadcrumbs.
-- The F12 family of keys lives in core/dive and binds when an LSP attaches.

return {
  -- VS Code style peek: edit the target right inside the popup, dive again from there
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    opts = function()
      local glance = require("glance")
      return {
        height = 22,
        zindex = 45,
        border = { enable = true, top_char = "━", bottom_char = "━" },
        list = { position = "right", width = 0.3 },
        theme = { enable = false },
        -- narrow splits get a floating window instead of a cramped inline one
        detached = function(winid)
          return vim.api.nvim_win_get_width(winid) < 100
        end,
        preview_win_opts = { cursorline = true, number = true, wrap = false },
        folds = { fold_closed = "󰅂", fold_open = "󰅀", folded = false },
        indent_lines = { enable = true, icon = "│" },
        winbar = { enable = true },
        use_trouble_qf = true,
        mappings = {
          list = {
            ["<C-v>"] = glance.actions.jump_vsplit,
            ["<C-x>"] = glance.actions.jump_split,
            ["<Esc>"] = glance.actions.close,
          },
          preview = {
            ["<Esc>"] = glance.actions.close,
          },
        },
      }
    end,
  },

  -- Clickable breadcrumbs: the file and the two scopes around the cursor, each one opens a symbol
  -- menu. The statusline already shows the folders, so they stay out of the winbar
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick breadcrumb",
      },
      {
        "[;",
        function()
          require("dropbar.api").goto_context_start()
        end,
        desc = "Start of current scope",
      },
      {
        "];",
        function()
          require("dropbar.api").select_next_context()
        end,
        desc = "Next scope",
      },
    },
    config = function()
      local default_enable = require("dropbar.configs").opts.bar.enable
      local sources = require("dropbar.sources")
      local innermost = require("core.dive.actions").innermost
      -- the scopes around the cursor, from the LSP or treesitter, cut to the two innermost
      local fallback = require("dropbar.utils").source.fallback({ sources.lsp, sources.treesitter })
      local scopes = {
        get_symbols = function(buf, win, cursor)
          return innermost(fallback.get_symbols(buf, win, cursor), 2)
        end,
      }
      require("dropbar").setup({
        sources = { path = { max_depth = 1 } },
        bar = {
          sources = function(buf)
            if vim.bo[buf].filetype == "markdown" then
              return { sources.path, sources.markdown }
            end
            if vim.bo[buf].buftype == "terminal" then
              return { sources.terminal }
            end
            return { sources.path, scopes }
          end,
          enable = function(buf, win, info)
            -- a back-to-basics solution wears its own winbar with the clock and the tests
            if vim.bo[buf].filetype == "bigfile" or vim.b[buf].btb_exercise then
              return false
            end
            return default_enable(buf, win, info)
          end,
        },
        menu = {
          win_configs = { border = require("core.skin").border() },
          preview = true,
        },
        icons = {
          ui = { bar = { separator = "  ", extends = "…" } },
        },
      })
    end,
  },
}
