-- blink.cmp: fast completion with built-in snippet engine

return {
  {
    "saghen/blink.cmp",
    version      = "v0.*",
    event        = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      -- ── Keymap ──────────────────────────────────────────────────────
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"]     = { "hide", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<Tab>"]     = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"]   = { "snippet_backward", "select_prev", "fallback" },
        ["<C-p>"]     = { "select_prev", "fallback" },
        ["<C-n>"]     = { "select_next", "fallback" },
        ["<C-b>"]     = { "scroll_documentation_up", "fallback" },
        ["<C-f>"]     = { "scroll_documentation_down", "fallback" },
      },
      -- ── Appearance ──────────────────────────────────────────────────
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant       = "mono",
        kind_icons = {
          Text          = "󰉿",
          Method        = "󰆧",
          Function      = "󰊕",
          Constructor   = "",
          Field         = "󰜢",
          Variable      = "󰀫",
          Class         = "󰠱",
          Interface     = "",
          Module        = "",
          Property      = "󰜢",
          Unit          = "󰑭",
          Value         = "󰎠",
          Enum          = "",
          Keyword       = "󰌋",
          Snippet       = "",
          Color         = "󰏘",
          File          = "󰈙",
          Reference     = "󰈇",
          Folder        = "󰉋",
          EnumMember    = "",
          Constant      = "󰏿",
          Struct        = "󰙅",
          Event         = "",
          Operator      = "󰆕",
          TypeParameter = "",
        },
      },
      -- ── Sources ─────────────────────────────────────────────────────
      sources = {
        default  = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name         = "LazyDev",
            module       = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      -- ── Completion menu ─────────────────────────────────────────────
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border   = "rounded",
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection",
          draw = {
            treesitter = { "lsp" },
            columns    = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind", gap = 1 } },
          },
        },
        documentation = {
          auto_show          = true,
          auto_show_delay_ms = 250,
          window = {
            border     = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
          },
        },
        ghost_text = { enabled = false },
      },
      -- ── Signature help ───────────────────────────────────────────────
      signature = {
        enabled = true,
        window  = { border = "rounded" },
      },
      -- ── Snippets ────────────────────────────────────────────────────
      snippets = { preset = "default" },
      -- ── Fuzzy matching ───────────────────────────────────────────────
      fuzzy = {
        implementation    = "prefer_rust_with_warning",
        max_typos         = function(keyword) return math.floor(#keyword / 4) end,
        use_frecency      = true,
        use_proximity     = true,
        sorts             = { "score", "sort_text" },
        prebuilt_binaries = { download = true },
      },
    },
  },
}
