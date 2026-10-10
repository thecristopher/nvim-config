-- Eldentree colorscheme — catppuccin-mocha base with Elden Ring palette
-- Dark warm stone backgrounds, parchment text, golden accents

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      background = { dark = "mocha" },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = true,
        shade = "dark",
        percentage = 0.08,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments     = { "italic" },
        conditionals = {},
        loops        = {},
        functions    = {},
        keywords     = { "bold" },
        strings      = {},
        variables    = {},
        numbers      = {},
        booleans     = {},
        properties   = {},
        types        = {},
        operators    = {},
      },
      -- ── Elden Ring Palette ─────────────────────────────────────────
      -- Backgrounds: dark warm stone (caves, ruins, fog)
      -- Text: aged parchment, gold leaf, graceful green, arcane purple
      color_overrides = {
        mocha = {
          -- Backgrounds — ash & stone
          base    = "#0D0B09",  -- main editor bg
          mantle  = "#090705",  -- darker (sidebars, floats)
          crust   = "#060403",  -- darkest (borders)
          -- Surfaces — layered stone
          surface0 = "#1C1815",  -- float bg, inactive
          surface1 = "#252019",  -- selected rows
          surface2 = "#312B22",  -- line highlights
          -- Overlays — fog and mist
          overlay0 = "#4A4340",  -- comments
          overlay1 = "#6B5E54",  -- dim ui text
          overlay2 = "#8C7A6E",  -- very dim
          -- Subtext — aged parchment tones
          subtext0 = "#A89278",
          subtext1 = "#C4AE96",
          -- Text — primary parchment
          text     = "#E0CDA8",
          -- Elden Ring Gold — keywords, UI accents
          yellow   = "#C9A84C",
          -- Peach — warnings, attributes
          peach    = "#CC8A40",
          -- Grace Green — strings (Sites of Grace)
          green    = "#7DAE68",
          teal     = "#6BA888",
          -- Arcane Purple — types, constructors
          lavender = "#9B8EC4",
          mauve    = "#A888C8",
          -- Crimson — errors (Crimson Tears)
          red      = "#B83838",
          maroon   = "#CC4848",
          -- Function gold (brighter than keyword gold)
          rosewater = "#DCC0A0",
          flamingo  = "#CC8870",
          -- Cool accents
          blue     = "#6898B8",
          sapphire = "#5888A8",
          sky      = "#68B8C8",
          pink     = "#C488A8",
        },
      },
      -- ── Custom highlights on top of palette ────────────────────────
      custom_highlights = function(c)
        return {
          -- Keywords: full Elden Ring gold, bold
          ["@keyword"]              = { fg = c.yellow, style = { "bold" } },
          ["@keyword.function"]     = { fg = c.yellow, style = { "bold" } },
          ["@keyword.operator"]     = { fg = c.yellow, style = {} },
          ["@keyword.return"]       = { fg = c.yellow, style = { "bold" } },
          ["@keyword.import"]       = { fg = c.yellow, style = {} },
          ["@conditional"]          = { fg = c.yellow, style = { "bold" } },
          ["@repeat"]               = { fg = c.yellow, style = { "bold" } },
          -- Functions: warm rosewater-gold
          ["@function"]             = { fg = c.rosewater, style = {} },
          ["@function.builtin"]     = { fg = c.rosewater, style = { "italic" } },
          ["@function.call"]        = { fg = c.rosewater, style = {} },
          ["@method"]               = { fg = c.rosewater, style = {} },
          ["@method.call"]          = { fg = c.rosewater, style = {} },
          -- Types: arcane purple
          ["@type"]                 = { fg = c.lavender, style = {} },
          ["@type.builtin"]         = { fg = c.lavender, style = { "italic" } },
          ["@constructor"]          = { fg = c.mauve, style = {} },
          -- Strings: Sites of Grace green
          ["@string"]               = { fg = c.green, style = {} },
          ["@string.special"]       = { fg = c.teal, style = {} },
          ["@character"]            = { fg = c.green, style = {} },
          -- Comments: mist and fog, italic
          ["@comment"]              = { fg = c.overlay0, style = { "italic" } },
          Comment                   = { fg = c.overlay0, style = { "italic" } },
          -- Numbers & booleans: steel blue
          ["@number"]               = { fg = c.blue, style = {} },
          ["@boolean"]              = { fg = c.sky, style = { "bold" } },
          ["@float"]                = { fg = c.blue, style = {} },
          -- Operators: warm text
          ["@operator"]             = { fg = c.subtext1, style = {} },
          -- Variables: parchment (no special color)
          ["@variable"]             = { fg = c.text, style = {} },
          ["@variable.builtin"]     = { fg = c.peach, style = { "italic" } },
          -- Parameters: dim parchment
          ["@parameter"]            = { fg = c.subtext0, style = {} },
          ["@variable.parameter"]   = { fg = c.subtext0, style = {} },
          -- Properties/fields: slightly dimmer gold
          ["@property"]             = { fg = c.rosewater, style = {} },
          ["@variable.member"]      = { fg = c.rosewater, style = {} },
          -- Punctuation: dim, unobtrusive
          ["@punctuation.bracket"]  = { fg = c.overlay2, style = {} },
          ["@punctuation.delimiter"] = { fg = c.overlay1, style = {} },
          -- ── Editor chrome ─────────────────────────────────────────
          -- Cursor line: very subtle gold tint (brightened in insert mode, see autocmds.lua)
          CursorLine   = { bg = "#1A1714" },
          CursorLineNr = { fg = c.yellow, style = { "bold" } },
          -- Cursor: bright gold block/bar for terminals that honor OSC-12 cursor color
          Cursor       = { fg = c.base, bg = c.yellow, style = { "bold" } },
          lCursor      = { fg = c.base, bg = c.yellow, style = { "bold" } },
          CursorIM     = { fg = c.base, bg = c.yellow, style = { "bold" } },
          TermCursor   = { fg = c.base, bg = c.yellow, style = { "bold" } },
          -- Line numbers
          LineNr       = { fg = c.overlay0 },
          -- Visual selection: warm dark gold
          Visual       = { bg = "#2E2720" },
          VisualNOS    = { bg = "#2E2720" },
          -- Search: gold highlight
          Search       = { fg = c.base, bg = c.yellow, style = { "bold" } },
          IncSearch    = { fg = c.base, bg = c.rosewater, style = { "bold" } },
          CurSearch    = { fg = c.base, bg = c.peach, style = { "bold" } },
          -- Matching brackets: gold
          MatchParen   = { fg = c.yellow, style = { "bold", "underline" } },
          -- Floating windows: dark mantle with gold border
          FloatBorder  = { fg = c.yellow, bg = c.mantle },
          NormalFloat  = { fg = c.text, bg = c.mantle },
          -- Popup menu
          Pmenu        = { fg = c.text, bg = c.surface0 },
          PmenuSel     = { fg = c.base, bg = c.yellow },
          PmenuSbar    = { bg = c.surface1 },
          PmenuThumb   = { bg = c.yellow },
          -- Fold
          Folded       = { fg = c.overlay1, bg = c.surface0, style = { "italic" } },
          FoldColumn   = { fg = c.overlay0, bg = c.base },
          -- Diagnostics: styled with game colors
          DiagnosticVirtualTextError = { fg = c.red,   bg = "#1F0E0E", style = { "italic" } },
          DiagnosticVirtualTextWarn  = { fg = c.peach, bg = "#1F1308", style = { "italic" } },
          DiagnosticVirtualTextHint  = { fg = c.teal,  bg = "#0E1915", style = { "italic" } },
          DiagnosticVirtualTextInfo  = { fg = c.blue,  bg = "#0E1420", style = { "italic" } },
          -- Diff
          DiffAdd      = { bg = "#142010" },
          DiffChange   = { bg = "#1A1608" },
          DiffDelete   = { fg = c.red, bg = "#1F0A0A" },
          DiffText     = { bg = "#2A2210", style = { "bold" } },
          -- Indent scope line: very subtle
          IblIndent    = { fg = "#1C1A16" },
          IblScope     = { fg = "#3A3428" },
          -- Snacks: dashboard gold title
          SnacksDashboardHeader = { fg = c.yellow, style = { "bold" } },
          SnacksDashboardKey    = { fg = c.rosewater, style = { "bold" } },
          SnacksDashboardDesc   = { fg = c.subtext0 },
          SnacksDashboardIcon   = { fg = c.yellow },
          SnacksDashboardFooter = { fg = c.overlay0, style = { "italic" } },
          SnacksDashboardTitle  = { fg = c.rosewater, style = { "bold" } },
          SnacksPickerGitBranch = { fg = c.green, style = { "italic" } },
          -- Glance: the peek window reads like an old tome left open on the desk
          GlanceBorderTop          = { fg = c.yellow, bg = c.mantle },
          GlancePreviewBorderBottom = { fg = c.yellow, bg = c.mantle },
          GlanceListBorderBottom   = { fg = c.yellow, bg = c.mantle },
          GlancePreviewNormal      = { bg = "#120F0C" },
          GlancePreviewCursorLine  = { bg = "#1F1A14" },
          GlancePreviewMatch       = { fg = c.base, bg = c.yellow, style = { "bold" } },
          GlanceListNormal         = { fg = c.subtext1, bg = c.mantle },
          GlanceListCursorLine     = { fg = c.text, bg = c.surface1, style = { "bold" } },
          GlanceListFilename       = { fg = c.rosewater },
          GlanceListFilepath       = { fg = c.overlay1, style = { "italic" } },
          GlanceListCount          = { fg = c.base, bg = c.yellow },
          GlanceListMatch          = { fg = c.yellow, style = { "bold" } },
          GlanceFoldIcon           = { fg = c.yellow },
          GlanceWinBarFilename     = { fg = c.yellow, bg = c.surface0, style = { "bold" } },
          GlanceWinBarFilepath     = { fg = c.overlay1, bg = c.surface0, style = { "italic" } },
          GlanceWinBarTitle        = { fg = c.base, bg = c.yellow, style = { "bold" } },
          -- Dropbar breadcrumbs
          WinBar                   = { fg = c.subtext0, bg = c.base },
          WinBarNC                 = { fg = c.overlay0, bg = c.base },
          DropBarIconUISeparator   = { fg = c.yellow },
          DropBarMenuHoverEntry    = { bg = c.surface1 },
          DropBarMenuCurrentContext = { bg = c.surface0 },
          -- Telescope
          TelescopeBorder        = { fg = c.yellow, bg = c.mantle },
          TelescopeNormal        = { fg = c.text,   bg = c.mantle },
          TelescopePromptBorder  = { fg = c.peach,  bg = c.surface0 },
          TelescopePromptNormal  = { fg = c.text,   bg = c.surface0 },
          TelescopePromptPrefix  = { fg = c.yellow, bg = c.surface0 },
          TelescopeResultsBorder = { fg = c.yellow, bg = c.mantle },
          TelescopePreviewBorder = { fg = c.teal,   bg = c.mantle },
          TelescopeSelectionCaret = { fg = c.yellow },
          TelescopeSelection      = { fg = c.text, bg = c.surface1 },
          -- Which-key
          WhichKey          = { fg = c.yellow },
          WhichKeyBorder    = { fg = c.yellow, bg = c.mantle },
          WhichKeyGroup     = { fg = c.rosewater, style = { "bold" } },
          WhichKeyDesc      = { fg = c.subtext0 },
          WhichKeyNormal    = { fg = c.text, bg = c.mantle },
          -- Trouble
          TroubleNormal     = { bg = c.mantle },
          TroubleBorder     = { fg = c.yellow, bg = c.mantle },
          -- Notify
          NotifyERRORBorder = { fg = c.red },
          NotifyWARNBorder  = { fg = c.peach },
          NotifyINFOBorder  = { fg = c.teal },
          NotifyDEBUGBorder = { fg = c.overlay1 },
          NotifyTRACEBorder = { fg = c.mauve },
          -- Noice
          NoiceCmdlinePopupBorder      = { fg = c.yellow },
          NoiceCmdlinePopupTitle       = { fg = c.yellow, style = { "bold" } },
          NoiceConfirmBorder           = { fg = c.peach },
          NoiceLspProgressSpinner      = { fg = c.yellow },
          NoiceLspProgressTitle        = { fg = c.rosewater },
          -- Flash
          FlashLabel    = { fg = c.base, bg = c.yellow, style = { "bold" } },
          FlashMatch    = { fg = c.base, bg = c.peach },
          FlashCurrent  = { fg = c.base, bg = c.rosewater },
          -- Git signs
          GitSignsAdd    = { fg = c.green },
          GitSignsChange = { fg = c.yellow },
          GitSignsDelete = { fg = c.red },
          -- Todo comments
          TodoBgTODO   = { fg = c.base, bg = c.yellow,  style = { "bold" } },
          TodoFgTODO   = { fg = c.yellow },
          TodoBgFIX    = { fg = c.base, bg = c.red,     style = { "bold" } },
          TodoFgFIX    = { fg = c.red },
          TodoBgHACK   = { fg = c.base, bg = c.peach,   style = { "bold" } },
          TodoBgNOTE   = { fg = c.base, bg = c.teal,    style = { "bold" } },
          TodoFgNOTE   = { fg = c.teal },
          -- Illuminate
          IlluminatedWordText  = { bg = "#2E2720", style = { "underline" } },
          IlluminatedWordRead  = { bg = "#2E2720" },
          IlluminatedWordWrite = { bg = "#2E2720", style = { "underline" } },
        }
      end,
      -- ── Plugin integrations ────────────────────────────────────────
      integrations = {
        blink_cmp          = true,
        bufferline         = true,
        dashboard          = true,
        dropbar            = { enabled = true, color_mode = true },
        flash              = true,
        gitsigns           = true,
        illuminate         = { enabled = false },  -- handled by snacks.words
        indent_blankline   = { enabled = true, scope_color = "yellow", colored_indent_levels = false },
        lsp_trouble        = true,
        mason              = true,
        mini               = { enabled = true, indentscope_color = "" },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors      = { "italic" },
            hints       = { "italic" },
            warnings    = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors      = { "underline" },
            hints       = { "underline" },
            warnings    = { "underline" },
            information = { "underline" },
          },
          inlay_hints = { background = true },
        },
        neotree            = true,
        noice              = true,
        notify             = true,
        snacks             = true,
        telescope          = true,
        treesitter         = true,
        treesitter_context = true,
        which_key          = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
