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
        folds = { fold_closed = "", fold_open = "", folded = false },
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

  -- Clickable breadcrumbs: file › class › method, each one opens a symbol menu
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
      require("dropbar").setup({
        bar = {
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
