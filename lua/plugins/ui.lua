-- UI layer: statusline, bufferline, command UI, keybinding hints

-- Elden Ring lualine theme — mode-driven color shifts
local function eldentree_lualine_theme()
  local gold    = "#C9A84C"
  local grace   = "#7DAE68"
  local arcane  = "#9B8EC4"
  local crimson = "#B83838"
  local moon    = "#CC8A40"
  local sky     = "#68B8C8"
  local bg      = "#0D0B09"
  local bg1     = "#1C1815"
  local bg2     = "#252019"
  local fg      = "#E0CDA8"
  local fg_dim  = "#A89278"

  return {
    normal = {
      a = { fg = bg, bg = gold,   gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    insert = {
      a = { fg = bg, bg = grace,  gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    visual = {
      a = { fg = bg, bg = arcane, gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    replace = {
      a = { fg = bg, bg = crimson, gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    command = {
      a = { fg = bg, bg = moon,   gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    terminal = {
      a = { fg = bg, bg = sky,    gui = "bold" },
      b = { fg = fg, bg = bg2 },
      c = { fg = fg_dim, bg = bg1 },
    },
    inactive = {
      a = { fg = fg_dim, bg = bg },
      b = { fg = fg_dim, bg = bg },
      c = { fg = fg_dim, bg = bg },
    },
  }
end

return {
  -- ── Statusline ─────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local function lsp_info()
        local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
        if #buf_clients == 0 then return "" end
        local names = {}
        for _, client in ipairs(buf_clients) do
          if client.name ~= "null-ls" and client.name ~= "copilot" then
            table.insert(names, client.name)
          end
        end
        return #names > 0 and ("󰒋  " .. table.concat(names, ", ")) or ""
      end

      return {
        options = {
          theme                = eldentree_lualine_theme(),
          component_separators = { left = "", right = "" },
          section_separators   = { left = "", right = "" },
          globalstatus         = true,
          disabled_filetypes   = { statusline = { "dashboard", "alpha", "starter" } },
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return s:sub(1, 3) end } },
          lualine_b = {
            { "branch", icon = "󰘬 " },
            {
              "diff",
              symbols = { added = "󰐖 ", modified = "󰏫 ", removed = "󰍴 " },
              diff_color = {
                added    = { fg = "#7DAE68" },
                modified = { fg = "#C9A84C" },
                removed  = { fg = "#B83838" },
              },
            },
          },
          lualine_c = {
            {
              "filename",
              path = 1,
              symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
            },
          },
          lualine_x = {
            { lsp_info, color = { fg = "#C9A84C" } },
            {
              "diagnostics",
              sources = { "nvim_lsp" },
              symbols = { error = "󰅚 ", warn = "󰊌 ", hint = "󰌶 ", info = "󰋽 " },
            },
            { "filetype", icon_only = false },
          },
          lualine_y = { "progress" },
          lualine_z = { { "location", fmt = function(s) return "󰍎 " .. s end } },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "neo-tree", "lazy", "trouble", "toggleterm" },
      }
    end,
  },

  -- ── Buffer tabs ────────────────────────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>",            desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned" },
      { "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer" },
      { "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer" },
    },
    opts = function()
      local gold   = "#C9A84C"
      local bg     = "#0D0B09"
      local bg1    = "#1C1815"
      local fg     = "#E0CDA8"
      local fg_dim = "#6B5E54"

      return {
        options = {
          mode              = "buffers",
          numbers           = "none",
          close_command     = function(n) Snacks.bufdelete(n) end,
          right_mouse_command = function(n) Snacks.bufdelete(n) end,
          indicator         = { icon = "▎", style = "icon" },
          buffer_close_icon = "󰅖",
          modified_icon     = "●",
          close_icon        = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          diagnostics       = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local icons = { error = "󰅚 ", warning = "󰊌 " }
            local s = {}
            for k, n in pairs(diag) do
              if icons[k] then table.insert(s, icons[k] .. n) end
            end
            return table.concat(s, " ")
          end,
          offsets = {
            { filetype = "neo-tree", text = "  Explorer", highlight = "Directory", text_align = "left" },
          },
          color_icons       = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_tab_indicators = true,
          separator_style   = "slant",
          always_show_bufferline = false,
          hover = { enabled = true, delay = 150, reveal = { "close" } },
        },
        highlights = {
          fill                = { bg = bg },
          background          = { fg = fg_dim, bg = bg1 },
          buffer_visible      = { fg = fg_dim, bg = bg1 },
          buffer_selected     = { fg = fg, bg = bg, bold = true },
          indicator_selected  = { fg = gold, bg = bg },
          separator           = { fg = bg, bg = bg1 },
          separator_visible   = { fg = bg, bg = bg1 },
          separator_selected  = { fg = bg, bg = bg },
          modified            = { fg = gold, bg = bg1 },
          modified_selected   = { fg = gold, bg = bg },
          close_button        = { fg = fg_dim, bg = bg1 },
          close_button_selected = { fg = fg_dim, bg = bg },
          numbers             = { fg = fg_dim, bg = bg1 },
          numbers_selected    = { fg = gold, bg = bg, bold = true },
          diagnostic          = { fg = fg_dim, bg = bg1 },
          diagnostic_selected = { fg = fg, bg = bg },
          error               = { fg = "#B83838", bg = bg1 },
          error_selected      = { fg = "#B83838", bg = bg, bold = true },
          warning             = { fg = "#CC8A40", bg = bg1 },
          warning_selected    = { fg = "#CC8A40", bg = bg, bold = true },
          hint                = { fg = "#6BA888", bg = bg1 },
          hint_selected       = { fg = "#6BA888", bg = bg },
          tab                 = { fg = fg_dim, bg = bg1 },
          tab_selected        = { fg = gold, bg = bg, bold = true },
          tab_close           = { fg = fg_dim, bg = bg },
        },
      }
    end,
  },

  -- ── Command / message UI ──────────────────────────────────────────
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = {
        enabled = true,
        view    = "cmdline_popup",
        format  = {
          cmdline  = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = "󰍉 ", lang = "regex" },
          search_up   = { kind = "search", pattern = "^%?", icon = "󰍉 ", lang = "regex" },
          filter   = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua      = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
          help     = { pattern = "^:%s*he?l?p?%s+", icon = "" },
          input    = { view = "cmdline_input", icon = "󰥻 " },
        },
      },
      messages = { enabled = true, view = "notify", view_error = "notify", view_warn = "notify" },
      popupmenu = { enabled = true, backend = "nui" },
      notify    = { enabled = false },  -- use snacks.notifier instead
      lsp = {
        progress = { enabled = true, view = "mini" },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"]   = true,
        },
        hover     = { enabled = false },  -- use native LSP hover
        signature = { enabled = false },  -- use native LSP signature
      },
      routes = {
        { filter = { event = "msg_show", any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } } }, view = "mini" },
        { filter = { event = "msg_show", find = "^/" }, skip = true },
        { filter = { event = "msg_show", kind = "search_count" }, skip = true },
      },
      presets = {
        bottom_search         = false,
        command_palette       = true,
        long_message_to_split = true,
        inc_rename            = true,
        lsp_doc_border        = true,
      },
      views = {
        cmdline_popup = {
          position = { row = "40%", col = "50%" },
          size     = { min_width = 60, width = "auto" },
          border   = { style = "rounded", padding = { 0, 1 } },
          win_options = { winhighlight = "NormalFloat:NoiceCmdlinePopup,FloatBorder:NoiceCmdlinePopupBorder" },
        },
        mini = {
          win_options = { winblend = 0 },
          position = { row = -1, col = "100%" },
          size     = { width = "auto", height = "auto" },
        },
      },
    },
    config = function(_, opts)
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
    end,
  },

  -- ── Keybinding hints ──────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset  = "modern",
      delay   = 300,
      plugins = { marks = true, registers = true, spelling = { enabled = true, suggestions = 20 } },
      icons = {
        breadcrumb = "»",
        separator  = "➜",
        group      = "+",
      },
      win = {
        border  = "rounded",
        padding = { 1, 2 },
        wo      = { winblend = 10 },
      },
      layout = { align = "center" },
      show_help = true,
      show_keys = true,
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>b",  group = "buffer" },
        { "<leader>c",  group = "code" },
        { "<leader>f",  group = "find" },
        { "<leader>g",  group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>s",  group = "split" },
        { "<leader>t",  group = "terminal" },
        { "<leader>u",  group = "ui" },
        { "<leader>x",  group = "diagnostics" },
        { "[",          group = "prev" },
        { "]",          group = "next" },
        { "g",          group = "goto" },
      })
    end,
  },

  -- ── mini.animate: smooth cursor, window open/close, resize ────────
  {
    "echasnovski/mini.animate",
    version = false,
    event   = "VeryLazy",
    config  = function()
      local animate = require("mini.animate")
      local timing  = animate.gen_timing.linear({ duration = 90, unit = "total" })
      animate.setup({
        cursor = { enable = true,  timing = timing },
        scroll = { enable = false },  -- snacks.scroll handles this
        resize = { enable = true,  timing = timing },
        open   = { enable = true,  timing = timing },
        close  = { enable = true,  timing = timing },
      })
    end,
  },

  -- ── indent-blankline: rainbow indent guides (Eldentree palette) ────
  {
    "lukas-reineke/indent-blankline.nvim",
    main  = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts  = {
      indent = { char = "│", tab_char = "│" },
      scope  = { enabled = true, char = "│" },
      exclude = {
        filetypes = {
          "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble",
          "lazy", "mason", "notify", "toggleterm", "snacks_dashboard",
        },
      },
    },
    config = function(_, opts)
      -- Eldentree rainbow palette, one level per colour
      local palette = { "#C9A84C", "#9B8EC4", "#6BA888", "#68B8C8", "#CC8A40", "#B83838" }
      local hl_list = {}
      for i, color in ipairs(palette) do
        local name = "IBLRainbow" .. i
        vim.api.nvim_set_hl(0, name, { fg = color })
        table.insert(hl_list, name)
      end
      vim.api.nvim_set_hl(0, "IBLScope", { fg = "#C9A84C", bold = true })
      opts.indent.highlight = hl_list
      opts.scope.highlight  = { "IBLScope" }
      require("ibl").setup(opts)
    end,
  },

  -- ── Icons ─────────────────────────────────────────────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
