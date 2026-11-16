-- blink.cmp: fast completion with built-in snippet engine for the LSP, paths and snippets.
-- Copilot writes ahead as ghost text (Tab takes it) and guesses the next edit in normal mode.

---Accepts Copilot's ghost text when it shows one, so Tab can fall through to blink otherwise.
---@return boolean|nil true when Copilot took the key
local function accept_copilot()
  local ok, suggestion = pcall(require, "copilot.suggestion")
  if ok and suggestion.is_visible() then
    suggestion.accept()
    return true
  end
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    dependencies = {
      {
        "copilotlsp-nvim/copilot-lsp",
        init = function()
          -- a guess that lands while you are still typing gets in the way more than it helps
          vim.g.copilot_nes_debounce = 500
        end,
      },
    },
    opts = {
      -- whole lines and blocks read better inline than squeezed into a menu row
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          -- Tab is handled by blink so it can share the key with the menu and snippets
          accept = false,
          accept_word = "<M-w>",
          accept_line = "<M-a>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      -- next edit suggestions: after a change, Copilot points at the next spot that needs it
      nes = {
        enabled = true,
        keymap = {
          accept_and_goto = "<Tab>",
          accept = false,
          dismiss = "<Esc>",
        },
      },
      panel = { enabled = false },
      filetypes = { markdown = true, help = true },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      -- unsigned, Copilot answers nothing at all, so the session says once how to sign in
      require("core.copilot").setup()
    end,
  },
  {
    "saghen/blink.cmp",
    -- v0 called client.request, deprecated since nvim 0.11, and nvim warned on every completion
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      -- ── Keymap ──────────────────────────────────────────────────────
      keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { accept_copilot, "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      -- ── Appearance ──────────────────────────────────────────────────
      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
        kind_icons = {
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "󰒓",
          Field = "󰜢",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "󰐱",
          Module = "󰏖",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "󰉻",
          Keyword = "󰌋",
          Snippet = "󰅩",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "󰬠",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "󱐋",
          Operator = "󰆕",
          TypeParameter = "󰬁",
        },
      },
      -- ── Sources ─────────────────────────────────────────────────────
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      -- ── Completion menu ─────────────────────────────────────────────
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = require("core.skin").border(),
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection",
          draw = {
            treesitter = { "lsp" },
            columns = function(context)
              return require("core.chrome.actions").completion_columns(context.mode)
            end,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 250,
          window = {
            border = require("core.skin").border(),
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
          },
        },
        -- Copilot owns the ghost text, two previews on the same line would fight
        ghost_text = { enabled = false },
      },
      -- ── Signature help ───────────────────────────────────────────────
      signature = {
        enabled = true,
        window = { border = require("core.skin").border() },
      },
      -- ── Snippets ────────────────────────────────────────────────────
      snippets = { preset = "default" },
      -- ── Fuzzy matching ───────────────────────────────────────────────
      fuzzy = {
        implementation = "prefer_rust_with_warning",
        max_typos = function(keyword)
          return math.floor(#keyword / 4)
        end,
        frecency = { enabled = true },
        use_proximity = true,
        sorts = { "score", "sort_text" },
        prebuilt_binaries = { download = true },
      },
    },
  },
}
