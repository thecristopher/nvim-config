-- UI layer: statusline, bufferline, command UI, keybinding hints

local function palette() return require("core.themes").palette() end

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
          theme                = "eldentree",
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
                added    = "GitSignsAdd",
                modified = "GitSignsChange",
                removed  = "GitSignsDelete",
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
            { function() return require("core.runes").grace() end, color = "EldenGraceGlow" },
            { lsp_info, color = function() return { fg = palette().yellow } end },
            {
              "diagnostics",
              sources = { "nvim_lsp" },
              symbols = { error = "󰅚 ", warn = "󰊌 ", hint = "󰌶 ", info = "󰋽 " },
            },
            { "filetype", icon_only = false },
          },
          lualine_y = {
            { function() return require("core.runes").gain() end, color = function() return { fg = palette().yellow, gui = "bold" } end },
            { function() return require("core.runes").held() end },
            "progress",
          },
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
        -- a function so bufferline rebuilds it on every ColorScheme
        highlights = function()
          return require("core.themes.actions").bufferline_highlights(palette())
        end,
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
        { "<leader>gj", icon = { icon = "󰁅", color = "blue" } },
        { "<leader>gk", icon = { icon = "󰁝", color = "green" } },
        { "<leader>gN", icon = { icon = "󰘬", color = "orange" } },
        { "<leader>gz", icon = { icon = "󰆓", color = "yellow" } },
        { "<leader>gZ", icon = { icon = "󰆓", color = "yellow" } },
        { "<leader>gu", icon = { icon = "󰕌", color = "red" } },
        { "<leader>m",  group = "messages", icon = { icon = "✎", color = "orange" } },
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

  -- ── mini.animate: window open/close and resize ────────────────────
  {
    "echasnovski/mini.animate",
    version = false,
    event   = "VeryLazy",
    config  = function()
      local animate = require("mini.animate")
      local timing  = animate.gen_timing.linear({ duration = 90, unit = "total" })
      animate.setup({
        cursor = { enable = false },  -- smear-cursor draws a trail without delaying the real cursor
        scroll = { enable = false },  -- snacks.scroll handles this
        resize = { enable = true,  timing = timing },
        open   = { enable = true,  timing = timing },
        close  = { enable = true,  timing = timing },
      })
    end,
  },

  -- ── smear-cursor: an accent colored trail on every jump ───────────
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts  = {
      -- read from the Cursor highlight so the trail follows the region
      cursor_color             = "Cursor",
      stiffness                = 0.8,
      trailing_stiffness       = 0.55,
      distance_stop_animating  = 0.5,
      -- typing already moves one cell at a time, a trail there is just noise
      smear_insert_mode        = false,
      smear_between_buffers    = true,
      smear_between_neighbor_lines = false,
      scroll_buffer_space      = true,
      filetypes_disabled       = { "bigfile", "snacks_dashboard", "lazy", "mason" },
    },
  },

  -- ── indent-blankline: rainbow indent guides in region colors ───────
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
          "lazy", "mason", "notify", "toggleterm", "snacks_dashboard", "bigfile",
        },
      },
    },
    config = function(_, opts)
      local hooks = require("ibl.hooks")
      local names = {}
      for level = 1, 6 do table.insert(names, "IBLRainbow" .. level) end
      -- ibl reruns this on every ColorScheme, which keeps the rainbow on the current region
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        local p = palette()
        for level, color in ipairs(require("core.themes.actions").rainbow(p)) do
          vim.api.nvim_set_hl(0, names[level], { fg = color })
        end
        vim.api.nvim_set_hl(0, "IBLScope", { fg = p.yellow, bold = true })
      end)
      opts.indent.highlight = names
      opts.scope.highlight  = { "IBLScope" }
      require("ibl").setup(opts)
    end,
  },

  -- ── rainbow-delimiters: nested brackets in the region's rainbow ────
  {
    "HiPhish/rainbow-delimiters.nvim",
    submodules = false,  -- the only submodule is its own test harness
    event = { "BufReadPost", "BufNewFile" },
    main  = "rainbow-delimiters.setup",
    opts  = {
      -- groups live in the colorscheme so they repaint with every region
      highlight = { "EldenRainbow1", "EldenRainbow2", "EldenRainbow3", "EldenRainbow4", "EldenRainbow5", "EldenRainbow6" },
      blacklist = { "bigfile" },
    },
  },

  -- ── satellite: a slim scrollbar with git, search and diagnostic marks ──
  {
    "lewis6991/satellite.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts  = {
      current_only = true,
      winblend     = 20,
      excluded_filetypes = { "neo-tree", "snacks_dashboard", "lazy", "mason", "Trouble", "trouble", "toggleterm", "bigfile" },
      handlers = {
        cursor      = { enable = true, symbols = { "⎺", "⎻", "⎼", "⎽" } },
        search      = { enable = true },
        diagnostic  = { enable = true, min_severity = vim.diagnostic.severity.WARN },
        gitsigns    = { enable = true, signs = { add = "│", change = "│", delete = "-" } },
        marks       = { enable = true, show_builtins = false },
        quickfix    = { enable = false },
      },
    },
  },

  -- ── tiny-inline-diagnostic: diagnostics as soft bubbles after the code ──
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event    = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern",
      options = {
        show_source = { enabled = true, if_many = true },
        multilines  = { enabled = true },
        use_icons_from_diagnostic = true,
      },
    },
  },

  -- ── mini.hipatterns: hex colors painted with their own color ──────
  {
    "echasnovski/mini.hipatterns",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local hipatterns = require("mini.hipatterns")
      return { highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() } }
    end,
  },

  -- ── Icons ─────────────────────────────────────────────────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
