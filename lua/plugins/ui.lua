-- UI layer: statusline, bufferline, command UI, keybinding hints

local function palette()
  return require("core.themes").palette()
end

return {
  -- ── Statusline ─────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      -- the filetype icon with the language servers, so the filetype never shows twice
      local chrome = require("core.chrome.actions")
      -- read on every setup, so a franchise switch redraws the bar in its own glyphs
      local skin = require("core.skin")
      -- a piece that leaves the bar first when the editor gets narrow
      local function wide(piece)
        return function()
          return chrome.shows(piece, vim.o.columns)
        end
      end

      local function language()
        if not chrome.names_itself(vim.bo.buftype) then
          return ""
        end
        local names = vim.tbl_map(function(client)
          return client.name
        end, vim.lsp.get_clients({ bufnr = 0 }))
        local ok, devicons = pcall(require, "nvim-web-devicons")
        local icon = ok and devicons.get_icon_by_filetype(vim.bo.filetype, { default = false })
          or ""
        return chrome.language_label(icon or "", vim.bo.filetype, names)
      end

      return {
        options = {
          theme = "eldentree",
          component_separators = require("core.skin").current().statusline.component,
          section_separators = require("core.skin").current().statusline.section,
          globalstatus = true,
        },
        sections = {
          lualine_a = {
            {
              "mode",
              -- the franchise names the mode, ROAM in the Lands Between, SURVIVE in Raccoon City
              fmt = function()
                return require("core.chrome").label()
              end,
            },
          },
          lualine_b = {
            { "branch", icon = "󰘬 " },
            {
              cond = wide("diff"),
              "diff",
              symbols = { added = "󰐖 ", modified = "󰏫 ", removed = "󰍴 " },
              diff_color = {
                added = "GitSignsAdd",
                modified = "GitSignsChange",
                removed = "GitSignsDelete",
              },
            },
          },
          lualine_c = {
            {
              "filename",
              path = 1,
              symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
              -- a terminal says which shell it runs, not its term:// address
              fmt = function(name)
                if vim.bo.buftype == "terminal" then
                  return "\u{F120} " .. chrome.terminal_title(vim.api.nvim_buf_get_name(0))
                end
                -- the HUD and other scratch screens have no file to name
                if
                  not chrome.names_itself(vim.bo.buftype) and vim.api.nvim_buf_get_name(0) == ""
                then
                  return ""
                end
                return name
              end,
            },
          },
          lualine_x = {
            -- the focus block counting down while the world stays quiet
            {
              function()
                return require("core.expedition").statusline()
              end,
              color = function()
                return { fg = palette().lavender }
              end,
            },
            -- the branch's CI run, each state carries its own highlight group
            {
              cond = wide("ci"),
              function()
                return require("core.ci").statusline()
              end,
              on_click = function()
                require("core.ci").open()
              end,
            },
            -- the next back-to-basics exercise getting ready, small enough to not cover the statement
            {
              cond = wide("btb"),
              function()
                local ok, btb = pcall(require, "core.btb")
                return ok and btb.statusline() or ""
              end,
              color = function()
                return { fg = palette().peach }
              end,
            },
            {
              cond = wide("music"),
              function()
                return require("core.music").statusline()
              end,
              color = function()
                return { fg = palette().mauve }
              end,
              on_click = function()
                require("core.music").open()
              end,
            },
            -- the breathing grace, the health ECG or the heartbeat, each with its own highlight group
            {
              cond = wide("status"),
              function()
                local status = require("core.franchise").mechanic("status")
                if status == "ecg" then
                  return require("core.ecg").statusline()
                end
                if status == "heartbeat" then
                  return require("core.heartbeat").statusline()
                end
                return require("core.runes").grace()
              end,
            },
            {
              "diagnostics",
              sources = { "nvim_diagnostic" },
              symbols = {
                error = skin.icon("error") .. " ",
                warn = skin.icon("warn") .. " ",
                hint = skin.icon("hint") .. " ",
                info = skin.icon("info") .. " ",
              },
            },
            {
              cond = wide("language"),
              language,
              color = function()
                return { fg = palette().yellow }
              end,
            },
          },
          lualine_y = {
            {
              cond = wide("runes"),
              function()
                return require("core.runes").gain()
              end,
              color = function()
                return { fg = palette().yellow, gui = "bold" }
              end,
            },
            {
              cond = wide("runes"),
              function()
                return require("core.runes").held()
              end,
            },
          },
          lualine_z = {
            {
              "location",
              fmt = function(s)
                return "󰍎 " .. s
              end,
            },
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        -- no toggleterm extension: with one global statusline it replaced the whole bar with the
        -- terminal's name, and the mode badge already says the franchise's word for terminal mode
        extensions = { "neo-tree", "lazy", "trouble" },
      }
    end,
  },

  -- ── Buffer tabs ────────────────────────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
    opts = function()
      return {
        options = {
          mode = "buffers",
          numbers = "none",
          close_command = function(n)
            Snacks.bufdelete(n)
          end,
          right_mouse_command = function(n)
            Snacks.bufdelete(n)
          end,
          indicator = { icon = "▎", style = "icon" },
          buffer_close_icon = "󰅖",
          modified_icon = "●",
          close_icon = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local skin = require("core.skin")
            local icons = { error = skin.icon("error") .. " ", warning = skin.icon("warn") .. " " }
            local s = {}
            for k, n in pairs(diag) do
              if icons[k] then
                table.insert(s, icons[k] .. n)
              end
            end
            return table.concat(s, " ")
          end,
          offsets = {
            {
              filetype = "neo-tree",
              text = "  Explorer",
              highlight = "Directory",
              text_align = "left",
            },
          },
          color_icons = true,
          show_buffer_icons = true,
          show_buffer_close_icons = true,
          show_tab_indicators = true,
          separator_style = require("core.skin").current().tabs,
          always_show_bufferline = false,
          -- tabs as wide as their names need, so more of them fit before the list is cut short
          tab_size = 12,
          -- a file you open lands beside the one you were reading, not at the far end
          sort_by = "insert_after_current",
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
        view = "cmdline_popup",
        -- the command line and search are titled and marked by the franchise, see core/chrome
        format = vim.tbl_extend("force", {
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua = {
            pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
            icon = "",
            lang = "lua",
          },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
          input = { view = "cmdline_input", icon = "󰥻 " },
        }, require("core.chrome.cmdline").formats()),
      },
      messages = { enabled = true, view = "notify", view_error = "notify", view_warn = "notify" },
      popupmenu = { enabled = true, backend = "nui" },
      notify = { enabled = false }, -- use snacks.notifier instead
      lsp = {
        progress = { enabled = true, view = "mini" },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        hover = { enabled = false }, -- use native LSP hover
        signature = { enabled = false }, -- use native LSP signature
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } },
          },
          view = "mini",
        },
        { filter = { event = "msg_show", find = "^/" }, skip = true },
        { filter = { event = "msg_show", kind = "search_count" }, skip = true },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          position = { row = "40%", col = "50%" },
          size = { min_width = 60, width = "auto" },
          border = { style = require("core.skin").border(), padding = { 0, 1 } },
          win_options = {
            winhighlight = "NormalFloat:NoiceCmdlinePopup,FloatBorder:NoiceCmdlinePopupBorder",
          },
        },
        mini = {
          win_options = { winblend = 0 },
          position = { row = -1, col = "100%" },
          size = { width = "auto", height = "auto" },
        },
      },
    },
    config = function(_, opts)
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
      -- nvim 0.12 sends a "restart" ui event with no group_type shape, and noice errors on it,
      -- which leaves the UI detached after :restart, so events noice cannot parse are skipped
      local noice_ui = require("noice.ui")
      local get_handler = noice_ui.get_handler
      noice_ui.get_handler = function(event, ...)
        if not event:find("_", 1, true) then
          return nil
        end
        return get_handler(event, ...)
      end
    end,
  },

  -- ── Keybinding hints ──────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      plugins = { marks = true, registers = true, spelling = { enabled = true, suggestions = 20 } },
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },
      win = {
        border = require("core.skin").border(),
        padding = { 1, 2 },
        -- opaque: with blend the code behind ghosted through every label and made them hard to read
        wo = { winblend = 0 },
      },
      layout = { align = "center" },
      show_help = true,
      show_keys = true,
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      -- groups and icons come from the leader map, so which-key never drifts from the keys
      wk.add(require("core.leader.actions").which_key_spec({
        gj = { icon = "󰁅", color = "blue" },
        gk = { icon = "󰁝", color = "green" },
        gN = { icon = "󰘬", color = "orange" },
        gz = { icon = "󰆓", color = "yellow" },
        gZ = { icon = "󰆓", color = "yellow" },
        gu = { icon = "󰕌", color = "red" },
        gg = { icon = "󰊢", color = "orange" },
      }))
      wk.add({
        -- the four harpoon jumps would fill the first page, the harpoon group names them instead
        { "<leader>1", hidden = true },
        { "<leader>2", hidden = true },
        { "<leader>3", hidden = true },
        { "<leader>4", hidden = true },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
      })
    end,
  },

  -- ── mini.animate: window open/close and resize ────────────────────
  {
    "echasnovski/mini.animate",
    version = false,
    event = "VeryLazy",
    config = function()
      local animate = require("mini.animate")
      local timing = animate.gen_timing.linear({ duration = 90, unit = "total" })
      animate.setup({
        cursor = { enable = false }, -- smear-cursor draws a trail without delaying the real cursor
        scroll = { enable = false }, -- snacks.scroll handles this
        resize = { enable = true, timing = timing },
        open = { enable = true, timing = timing },
        close = { enable = true, timing = timing },
      })
    end,
  },

  -- ── smear-cursor: an accent colored trail on every jump ───────────
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- read from the cursor highlight of the current mode so the trail follows mode and region
      cursor_color = "Cursor",
      stiffness = 0.8,
      trailing_stiffness = 0.55,
      distance_stop_animating = 0.5,
      -- typing already moves one cell at a time, a trail there is just noise
      smear_insert_mode = false,
      smear_between_buffers = true,
      smear_between_neighbor_lines = false,
      scroll_buffer_space = true,
      filetypes_disabled = { "bigfile", "snacks_dashboard", "eldentree_hud", "lazy", "mason" },
    },
    config = function(_, opts)
      local smear = require("smear_cursor")
      smear.setup(opts)
      -- assigning the color also flushes smear's color cache, so the trail repaints
      local function follow(mode)
        smear.cursor_color = require("core.themes.actions").cursor_group(mode)
      end
      local group = vim.api.nvim_create_augroup("eldentree_smear", { clear = true })
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = group,
        callback = function()
          follow(vim.v.event.new_mode)
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "EldentreeRegionSettled",
        callback = function()
          follow(vim.api.nvim_get_mode().mode)
        end,
      })
    end,
  },

  -- ── rainbow-delimiters: nested brackets in the region's rainbow ────
  {
    "HiPhish/rainbow-delimiters.nvim",
    submodules = false, -- the only submodule is its own test harness
    event = { "BufReadPost", "BufNewFile" },
    main = "rainbow-delimiters.setup",
    opts = {
      -- groups live in the colorscheme so they repaint with every region
      highlight = {
        "EldenRainbow1",
        "EldenRainbow2",
        "EldenRainbow3",
        "EldenRainbow4",
        "EldenRainbow5",
        "EldenRainbow6",
      },
      blacklist = { "bigfile" },
    },
  },

  -- ── satellite: a slim scrollbar with git, search and diagnostic marks ──
  {
    "lewis6991/satellite.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_only = true,
      winblend = 20,
      excluded_filetypes = {
        "neo-tree",
        "snacks_dashboard",
        "eldentree_hud",
        "lazy",
        "mason",
        "Trouble",
        "trouble",
        "toggleterm",
        "bigfile",
      },
      handlers = {
        cursor = { enable = true, symbols = { "⎺", "⎻", "⎼", "⎽" } },
        search = { enable = true },
        diagnostic = { enable = true, min_severity = vim.diagnostic.severity.WARN },
        gitsigns = { enable = true, signs = { add = "│", change = "│", delete = "-" } },
        marks = { enable = true, show_builtins = false },
        quickfix = { enable = false },
      },
    },
  },

  -- ── tiny-inline-diagnostic: diagnostics as soft bubbles after the code ──
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    opts = {
      preset = "modern",
      options = {
        show_source = { enabled = true, if_many = true },
        multilines = { enabled = true },
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
