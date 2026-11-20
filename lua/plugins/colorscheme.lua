-- Eldentree colorscheme: catppuccin mocha recolored per Elden Ring region (<leader>jr)

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
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      -- palettes live in core.themes, one per region, swapped in at setup
      -- ── Custom highlights on top of palette ────────────────────────
      custom_highlights = function(c)
        local t = require("core.themes.actions").derive(c)
        local rainbow = require("core.themes.actions").rainbow(c)
        local guides = require("core.themes.actions").indent_guides(c)
        -- the franchise's syntax signature: which color and style each role of the code wears
        local syntax =
          require("core.themes.actions").syntax(c, require("core.skin").current().syntax)
        local function role(name)
          return { fg = syntax[name].fg, style = syntax[name].style }
        end
        local function mode_color(mode)
          return require("core.themes.actions").mode_look(c, t, mode).number
        end
        return {
          -- Base vim groups first: treesitter captures and LSP semantic tokens link back to these,
          -- so painting them here keeps every language and every highlighter on the same colors.
          -- Colors and styles come from the franchise's syntax signature (skin.syntax)
          Keyword = role("keyword"),
          Statement = role("keyword"),
          Conditional = role("keyword"),
          Repeat = role("keyword"),
          Exception = role("keyword"),
          Include = role("keyword"),
          Function = role("function"),
          Type = role("type"),
          StorageClass = role("type"),
          Structure = role("type"),
          Number = role("constant"),
          Float = role("constant"),
          Boolean = role("constant"),
          Constant = role("constant"),
          Operator = { fg = c.subtext1, style = {} },
          Delimiter = { fg = c.overlay1, style = {} },
          -- Keywords catppuccin paints directly instead of linking to the base groups above
          ["@keyword"] = role("keyword"),
          ["@keyword.function"] = role("keyword"),
          ["@keyword.operator"] = role("keyword"),
          ["@keyword.return"] = role("keyword"),
          ["@keyword.export"] = role("keyword"),
          ["@keyword.conditional"] = role("keyword"),
          ["@keyword.repeat"] = role("keyword"),
          ["@function"] = role("function"),
          ["@function.call"] = role("function"),
          ["@function.method"] = role("function"),
          ["@function.method.call"] = role("function"),
          ["@function.builtin"] = role("function"),
          ["@type"] = role("type"),
          ["@type.builtin"] = role("type"),
          ["@constructor"] = role("type"),
          ["@string"] = role("string"),
          ["@string.special"] = { fg = c.teal, style = {} },
          ["@character"] = role("string"),
          ["@number"] = role("constant"),
          ["@boolean"] = role("constant"),
          ["@constant"] = role("constant"),
          ["@constant.builtin"] = role("constant"),
          ["@comment"] = role("comment"),
          Comment = role("comment"),
          -- Variables: plain text, the brightest thing on screen
          ["@variable"] = { fg = c.text, style = {} },
          ["@variable.builtin"] = { fg = c.peach, style = {} },
          ["@variable.parameter"] = { fg = c.subtext0, style = {} },
          ["@property"] = role("property"),
          ["@variable.member"] = role("property"),
          -- Punctuation: dim, unobtrusive
          ["@punctuation.bracket"] = { fg = c.overlay2, style = {} },
          -- ── Editor chrome ─────────────────────────────────────────
          -- Cursor line: very subtle accent tint (brightened in insert mode, see autocmds.lua)
          CursorLine = { bg = t.cursorline },
          CursorLineNr = { fg = c.yellow, style = { "bold" } },
          -- Cursor: bright gold block/bar for terminals that honor OSC-12 cursor color
          Cursor = { fg = c.base, bg = c.yellow, style = { "bold" } },
          lCursor = { fg = c.base, bg = c.yellow, style = { "bold" } },
          CursorIM = { fg = c.base, bg = c.yellow, style = { "bold" } },
          TermCursor = { fg = c.base, bg = c.yellow, style = { "bold" } },
          -- each mode tints the cursor like its line number, see guicursor in options.lua
          EldenCursorInsert = { fg = c.base, bg = mode_color("i") },
          EldenCursorVisual = { fg = c.base, bg = mode_color("v") },
          EldenCursorReplace = { fg = c.base, bg = mode_color("R") },
          EldenCursorCommand = { fg = c.base, bg = mode_color("c") },
          -- Line numbers
          LineNr = { fg = c.overlay0 },
          -- Visual selection: warm dark gold
          Visual = { bg = t.visual },
          VisualNOS = { bg = t.visual },
          -- Search: the accent, or a neighbor of it when the accent sits too close to the error color
          Search = { fg = c.base, bg = t.search, style = { "bold" } },
          IncSearch = { fg = c.base, bg = c.rosewater, style = { "bold" } },
          CurSearch = { fg = c.base, bg = c.peach, style = { "bold" } },
          -- Matching brackets: gold
          MatchParen = { fg = c.yellow, style = { "bold", "underline" } },
          -- Floating windows: dark mantle, the frame a softened accent so the accent itself marks focus
          FloatBorder = { fg = t.border, bg = c.mantle },
          -- the scope header sits on the panel color, a thin line under it instead of a whole row
          TreesitterContext = { bg = t.panel },
          TreesitterContextLineNumber = { fg = c.overlay1, bg = t.panel },
          TreesitterContextBottom = { underline = true, sp = c.surface2 },
          TreesitterContextLineNumberBottom = { underline = true, sp = c.surface2 },
          NormalFloat = { fg = c.text, bg = c.mantle },
          -- Popup menu
          Pmenu = { fg = c.text, bg = c.surface0 },
          -- the completion menu wears the same frame as every other float, so it and its
          -- documentation beside it read as one piece
          BlinkCmpMenu = { fg = c.text, bg = c.mantle },
          BlinkCmpMenuBorder = { fg = t.border, bg = c.mantle },
          PmenuSel = { fg = c.base, bg = c.yellow },
          PmenuSbar = { bg = c.surface1 },
          PmenuThumb = { bg = c.yellow },
          -- Panels: side windows get their own floor and a region tinted wall, so each zone reads apart
          WinSeparator = { fg = t.separator, bg = c.base },
          EldenPanel = { fg = c.text, bg = t.panel },
          NeoTreeNormal = { fg = c.text, bg = t.panel },
          NeoTreeNormalNC = { fg = c.text, bg = t.panel },
          NeoTreeEndOfBuffer = { fg = t.panel, bg = t.panel },
          NeoTreeWinSeparator = { fg = t.separator, bg = c.base },
          SnacksWinSeparator = { fg = t.separator, bg = c.base },
          -- Fold
          Folded = { fg = c.overlay1, bg = c.surface0, style = { "italic" } },
          -- the hidden line tally is a quiet note on the fold, not a bright pill on every closed one
          UfoFoldedEllipsis = { fg = c.overlay2, bg = c.surface0, style = { "italic" } },
          FoldColumn = { fg = c.overlay0, bg = c.base },
          -- Diagnostics: styled with game colors
          DiagnosticVirtualTextError = { fg = c.red, bg = t.diag_error_bg, style = { "italic" } },
          DiagnosticVirtualTextWarn = { fg = c.peach, bg = t.diag_warn_bg, style = { "italic" } },
          DiagnosticVirtualTextHint = { fg = c.teal, bg = t.diag_hint_bg, style = { "italic" } },
          DiagnosticVirtualTextInfo = { fg = c.blue, bg = t.diag_info_bg, style = { "italic" } },
          -- inlay hints and code lenses are read like a comment, so they take the brighter gray
          LspInlayHint = { fg = c.overlay1, bg = t.inlay },
          LspCodeLens = { fg = c.overlay1 },
          -- Diff
          DiffAdd = { bg = t.diff_add },
          DiffChange = { bg = t.diff_change },
          DiffDelete = { fg = c.red, bg = t.diff_delete },
          DiffText = { bg = t.diff_text, style = { "bold" } },
          -- Indent scope line: very subtle
          IblIndent = { fg = t.indent },
          IblScope = { fg = t.indent_scope },
          -- snacks.indent guides: the rainbow faded toward the background, the scope in full gold
          EldenIndent1 = { fg = guides[1] },
          EldenIndent2 = { fg = guides[2] },
          EldenIndent3 = { fg = guides[3] },
          EldenIndent4 = { fg = guides[4] },
          EldenIndent5 = { fg = guides[5] },
          EldenIndent6 = { fg = guides[6] },
          EldenIndentScope = { fg = c.yellow, style = { "bold" } },
          -- Rainbow delimiters share the indent rainbow so nesting reads the same everywhere
          EldenRainbow1 = { fg = rainbow[1] },
          EldenRainbow2 = { fg = rainbow[2] },
          EldenRainbow3 = { fg = rainbow[3] },
          EldenRainbow4 = { fg = rainbow[4] },
          EldenRainbow5 = { fg = rainbow[5] },
          EldenRainbow6 = { fg = rainbow[6] },
          -- Satellite scrollbar
          SatelliteBar = { bg = c.surface1 },
          SatelliteCursor = { fg = c.yellow },
          SatelliteSearch = { fg = c.peach },
          SatelliteSearchCurrent = { fg = c.rosewater },
          SatelliteMark = { fg = c.lavender },
          SatelliteDiagnosticError = { fg = c.red },
          SatelliteDiagnosticWarn = { fg = c.peach },
          SatelliteGitSignsAdd = { fg = c.green },
          SatelliteGitSignsChange = { fg = c.yellow },
          SatelliteGitSignsDelete = { fg = c.red },
          -- Snacks: dashboard gold title
          SnacksDashboardHeader = { fg = c.yellow, style = { "bold" } },
          SnacksDashboardKey = { fg = c.rosewater, style = { "bold" } },
          SnacksDashboardDesc = { fg = c.subtext0 },
          SnacksDashboardIcon = { fg = c.yellow },
          SnacksDashboardFooter = { fg = c.overlay0, style = { "italic" } },
          SnacksDashboardTitle = { fg = c.rosewater, style = { "bold" } },
          SnacksPickerGitBranch = { fg = c.green, style = { "italic" } },
          -- Snacks pickers and notifications wear the region's accent, see core/chrome
          SnacksPickerBorder = { fg = t.border, bg = c.mantle },
          SnacksPickerTitle = { fg = c.yellow, bg = c.mantle, style = { "bold" } },
          SnacksPickerListTitle = { fg = c.yellow, bg = c.mantle, style = { "bold" } },
          SnacksPickerInputTitle = { fg = c.yellow, bg = c.mantle, style = { "bold" } },
          SnacksPickerPreviewTitle = { fg = c.peach, bg = c.mantle, style = { "bold" } },
          SnacksPickerPreviewBorder = { fg = c.surface2, bg = c.mantle },
          SnacksPickerPrompt = { fg = c.yellow, style = { "bold" } },
          SnacksPickerMatch = { fg = c.yellow, style = { "bold" } },
          SnacksPickerListCursorLine = { bg = c.surface1 },
          SnacksPickerDir = { fg = c.overlay1 },
          SnacksNotifierTitleInfo = { fg = c.yellow, style = { "bold" } },
          SnacksNotifierBorderInfo = { fg = c.surface2 },
          SnacksNotifierIconInfo = { fg = c.yellow },
          SnacksNotifierFooterInfo = { fg = c.overlay0, style = { "italic" } },
          SnacksNotifierTitleWarn = { fg = c.peach, style = { "bold" } },
          SnacksNotifierBorderWarn = { fg = c.peach },
          SnacksNotifierFooterWarn = { fg = c.overlay0, style = { "italic" } },
          SnacksNotifierTitleError = { fg = c.red, style = { "bold" } },
          SnacksNotifierBorderError = { fg = c.red },
          SnacksNotifierFooterError = { fg = c.overlay0, style = { "italic" } },
          -- Glance: the peek window reads like an old tome left open on the desk
          GlanceBorderTop = { fg = t.border, bg = c.mantle },
          GlancePreviewBorderBottom = { fg = t.border, bg = c.mantle },
          GlanceListBorderBottom = { fg = t.border, bg = c.mantle },
          GlancePreviewNormal = { bg = t.glance_preview },
          GlancePreviewCursorLine = { bg = t.glance_cursorline },
          GlancePreviewMatch = { fg = c.base, bg = c.yellow, style = { "bold" } },
          GlanceListNormal = { fg = c.subtext1, bg = c.mantle },
          GlanceListCursorLine = { fg = c.text, bg = c.surface1, style = { "bold" } },
          GlanceListFilename = { fg = c.rosewater },
          GlanceListFilepath = { fg = c.overlay1, style = { "italic" } },
          GlanceListCount = { fg = c.base, bg = c.yellow },
          GlanceListMatch = { fg = c.yellow, style = { "bold" } },
          GlanceFoldIcon = { fg = c.yellow },
          GlanceWinBarFilename = { fg = c.yellow, bg = c.surface0, style = { "bold" } },
          GlanceWinBarFilepath = { fg = c.overlay1, bg = c.surface0, style = { "italic" } },
          GlanceWinBarTitle = { fg = c.base, bg = c.yellow, style = { "bold" } },
          -- Dropbar breadcrumbs
          WinBar = { fg = c.subtext0, bg = c.base },
          WinBarNC = { fg = c.overlay0, bg = c.base },
          DropBarIconUISeparator = { fg = c.yellow },
          DropBarMenuHoverEntry = { bg = c.surface1 },
          DropBarMenuCurrentContext = { bg = c.surface0 },
          -- Which-key
          WhichKey = { fg = c.yellow },
          WhichKeyBorder = { fg = t.border, bg = c.mantle },
          WhichKeyGroup = { fg = c.rosewater, style = { "bold" } },
          WhichKeyDesc = { fg = c.subtext0 },
          WhichKeyNormal = { fg = c.text, bg = c.mantle },
          -- Trouble
          TroubleNormal = { bg = c.mantle },
          TroubleBorder = { fg = t.border, bg = c.mantle },
          -- Notify
          NotifyERRORBorder = { fg = c.red },
          NotifyWARNBorder = { fg = c.peach },
          NotifyINFOBorder = { fg = c.teal },
          NotifyDEBUGBorder = { fg = c.overlay1 },
          NotifyTRACEBorder = { fg = c.mauve },
          -- Noice
          NoiceCmdlinePopupBorder = { fg = t.border },
          NoiceCmdlinePopupTitle = { fg = c.yellow, style = { "bold" } },
          NoiceConfirmBorder = { fg = c.peach },
          NoiceLspProgressSpinner = { fg = c.yellow },
          NoiceLspProgressTitle = { fg = c.rosewater },
          -- Flash
          FlashLabel = { fg = c.base, bg = c.yellow, style = { "bold" } },
          FlashMatch = { fg = c.base, bg = c.peach },
          FlashCurrent = { fg = c.base, bg = c.rosewater },
          -- Git signs
          GitSignsAdd = { fg = c.green },
          GitSignsChange = { fg = c.yellow },
          GitSignsDelete = { fg = c.red },
          -- Todo comments
          TodoBgTODO = { fg = c.base, bg = c.yellow, style = { "bold" } },
          TodoFgTODO = { fg = c.yellow },
          TodoBgFIX = { fg = c.base, bg = c.red, style = { "bold" } },
          TodoFgFIX = { fg = c.red },
          TodoBgHACK = { fg = c.base, bg = c.peach, style = { "bold" } },
          TodoBgNOTE = { fg = c.base, bg = c.teal, style = { "bold" } },
          TodoFgNOTE = { fg = c.teal },
          -- Debugger: breakpoints in blood, the line you stopped on lit like a grace
          DapBreakpoint = { fg = c.red },
          DapBreakpointCondition = { fg = c.peach },
          DapLogPoint = { fg = c.teal },
          DapBreakpointRejected = { fg = c.overlay1 },
          DapStopped = { fg = c.yellow, style = { "bold" } },
          DapStoppedLine = { bg = t.stopped_line },
          -- Neotest: the region accent marks what is running, folders follow the explorer
          NeotestRunning = { fg = c.yellow },
          NeotestNamespace = { fg = c.lavender },
          NeotestFile = { fg = c.rosewater },
          NeotestDir = { fg = c.subtext0 },
          NeotestAdapterName = { fg = c.yellow, style = { "bold" } },
          NeotestWinSelect = { fg = c.yellow, style = { "bold" } },
          -- Multicursor: extra cursors wear the accent like the main one
          MultiCursorCursor = { fg = c.base, bg = c.yellow },
          MultiCursorVisual = { bg = t.visual },
          MultiCursorSign = { fg = c.yellow },
          MultiCursorMatchPreview = { bg = t.visual, style = { "underline" } },
          MultiCursorDisabledCursor = { fg = c.base, bg = c.overlay1 },
          MultiCursorDisabledVisual = { bg = c.surface1 },
          MultiCursorDisabledSign = { fg = c.overlay1 },
          -- Hover: the docs read like an item description, name in gold and the category below
          EldenTome = { fg = c.text, bg = c.mantle },
          EldenTomeBorder = { fg = t.border, bg = c.mantle },
          EldenTomeTitle = { fg = c.yellow, bg = c.mantle, style = { "bold" } },
          EldenTomeFooter = { fg = c.overlay2, bg = c.mantle, style = { "italic" } },
          -- Illuminate
          IlluminatedWordText = { bg = t.visual, style = { "underline" } },
          IlluminatedWordRead = { bg = t.visual },
          IlluminatedWordWrite = { bg = t.visual, style = { "underline" } },
        }
      end,
      -- ── Plugin integrations ────────────────────────────────────────
      -- listed by hand, detecting them scans every plugin on each start and costs ~6 ms
      auto_integrations = false,
      integrations = {
        blink_cmp = true,
        bufferline = true,
        dashboard = true,
        dap = true,
        diffview = true,
        dropbar = { enabled = true, color_mode = true },
        flash = true,
        gitsigns = true,
        grug_far = true,
        harpoon = true,
        illuminate = { enabled = false }, -- handled by snacks.words
        lsp_trouble = true,
        mason = true,
        mini = { enabled = true, indentscope_color = "" },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
          inlay_hints = { background = true },
        },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        nvim_surround = true,
        rainbow_delimiters = true,
        render_markdown = true,
        snacks = true,
        treesitter = true,
        treesitter_context = true,
        ufo = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("core.themes").setup(opts)
    end,
  },
}
