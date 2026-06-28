-- LSP: mason (server installer) + lspconfig + lazydev (Neovim Lua API)

-- Diagnostic signs and display configuration
local function setup_diagnostics()
  local signs = {
    { name = "DiagnosticSignError", text = " " },
    { name = "DiagnosticSignWarn",  text = " " },
    { name = "DiagnosticSignHint",  text = " " },
    { name = "DiagnosticSignInfo",  text = " " },
  }
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name, numhl = "" })
  end
  vim.diagnostic.config({
    virtual_text = {
      enabled  = true,
      spacing  = 4,
      prefix   = "●",
      severity = { min = vim.diagnostic.severity.HINT },
    },
    signs = {
      active   = signs,
      severity = { min = vim.diagnostic.severity.HINT },
    },
    update_in_insert = false,
    underline        = true,
    severity_sort    = true,
    float = {
      focused  = false,
      style    = "minimal",
      border   = "rounded",
      source   = "always",
      header   = "",
      prefix   = "",
    },
  })
end

-- Keymaps applied per-buffer when an LSP attaches
local function on_attach(_, bufnr)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
  end

  -- Telescope calls are wrapped in functions so telescope is loaded lazily
  local tb = function(method) return function() require("telescope.builtin")[method]() end end

  map("gd",  tb("lsp_definitions"),              "Go to definition")
  map("gD",  vim.lsp.buf.declaration,            "Go to declaration")
  map("gr",  tb("lsp_references"),               "References")
  map("gI",  tb("lsp_implementations"),          "Go to implementation")
  map("gy",  tb("lsp_type_definitions"),         "Go to type definition")
  map("K",   vim.lsp.buf.hover,                  "Hover docs")
  map("gK",  vim.lsp.buf.signature_help,         "Signature help")
  map("<leader>ca", vim.lsp.buf.code_action,      "Code action")
  map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
  map("<leader>ci", tb("lsp_incoming_calls"),    "Incoming calls")
  map("<leader>co", tb("lsp_outgoing_calls"),    "Outgoing calls")
  map("<leader>cs", tb("lsp_document_symbols"), "Document symbols")
  map("<leader>cS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols")

  vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help,
    { buffer = bufnr, desc = "LSP: Signature help" })

  -- Inlay hints toggle (Neovim >= 0.10)
  if vim.lsp.inlay_hint then
    map("<leader>uh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, "Toggle inlay hints")
  end
end

-- Capabilities: merged with blink.cmp completions
local function get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end
  capabilities.textDocument.completion.completionItem = {
    documentationFormat  = { "markdown", "plaintext" },
    snippetSupport       = true,
    preselectSupport     = true,
    insertReplaceSupport = true,
    labelDetailsSupport  = true,
    deprecatedSupport    = true,
    commitCharactersSupport = true,
    tagSupport = { valueSet = { 1 } },
    resolveSupport = {
      properties = { "documentation", "detail", "additionalTextEdits" },
    },
  }
  return capabilities
end

-- Server-specific settings
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        runtime   = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
        },
        completion  = { callSnippet = "Replace" },
        diagnostics = { globals = { "vim", "Snacks" }, disable = { "missing-fields" } },
        hint = {
          enable     = true,
          setType    = false,
          paramType  = true,
          paramName  = "Disable",
          semicolon  = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  },
  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths    = true,
          useLibraryCodeForTypes = true,
          diagnosticMode     = "workspace",
          typeCheckingMode   = "basic",
        },
      },
    },
  },
  ts_ls = {
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints    = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints     = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints  = true,
          includeInlayEnumMemberValueHints  = true,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints    = "all",
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints     = true,
        },
      },
    },
  },
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo         = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
        checkOnSave   = { allFeatures = true, command = "clippy", extraArgs = { "--no-deps" } },
        procMacro     = { enable = true, ignored = { ["async-trait"] = { "async_trait" }, ["napi-derive"] = { "napi" }, ["async-recursion"] = { "async_recursion" } } },
        inlayHints    = { lifetimeElisionHints = { enable = true, useParameterNames = true } },
      },
    },
  },
  gopls = {
    settings = {
      gopls = {
        gofumpt       = true,
        codelenses    = { gc_details = false, generate = true, regenerate_cgo = true, run_govulncheck = true, test = true, tidy = true, upgrade_dependency = true, vendor = true },
        hints         = { assignVariableTypes = true, compositeLiteralFields = true, compositeLiteralTypes = true, constantValues = true, functionTypeParameters = true, parameterNames = true, rangeVariableTypes = true },
        analyses      = { fieldalignment = true, nilness = true, unusedparams = true, unusedwrite = true, useany = true },
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck   = true,
        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.venv", "-node_modules" },
      },
    },
  },
  bashls   = {},
  jsonls   = {
    -- Schemas injected lazily via on_new_config so schemastore is never
    -- required at module load time (it's a lazy plugin).
    on_new_config = function(cfg)
      local ok, ss = pcall(require, "schemastore")
      if ok then
        cfg.settings.json.schemas = vim.list_extend(cfg.settings.json.schemas or {}, ss.json.schemas())
      end
    end,
    settings = {
      json = { validate = { enable = true }, schemas = {} },
    },
  },
  yamlls   = {
    on_new_config = function(cfg)
      local ok, ss = pcall(require, "schemastore")
      if ok then
        cfg.settings.yaml.schemas = vim.tbl_deep_extend("force", cfg.settings.yaml.schemas or {}, ss.yaml.schemas())
      end
    end,
    settings = {
      yaml = {
        schemaStore = { enable = false, url = "" },
        schemas     = {},
        validate    = true,
        completion  = true,
        hover       = true,
      },
    },
  },
  cssls    = {},
  html     = {},
  tailwindcss = {},
  marksman = {},
  dockerls = {},
  docker_compose_language_service = {},
  taplo    = {},
}

return {
  -- ── lazydev: Neovim Lua API completions ────────────────────────────
  {
    "folke/lazydev.nvim",
    ft   = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim",        words = { "Snacks" } },
        { path = "lazy.nvim",          words = { "LazyVim" } },
      },
    },
  },

  -- ── Schema store (JSON / YAML) ────────────────────────────────────
  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  -- ── Mason: server installer ────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    cmd  = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts  = {
      ui = {
        border = "rounded",
        icons  = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
      ensure_installed = {
        "stylua", "shfmt", "prettierd", "black", "isort",
        "eslint_d", "shellcheck", "selene",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then p:install() end
        end
      end)
    end,
  },

  -- ── mason-lspconfig: bridge mason → lspconfig ─────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = vim.tbl_keys(servers),
      automatic_installation = true,
    },
  },

  -- ── nvim-lspconfig: configure all servers ─────────────────────────
  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/lazydev.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      setup_diagnostics()

      local lspconfig   = require("lspconfig")
      local capabilities = get_capabilities()

      -- Shared handler for all servers
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          local server_opts = servers[server_name] or {}
          server_opts.on_attach    = on_attach
          server_opts.capabilities = vim.tbl_deep_extend("force", capabilities, server_opts.capabilities or {})
          lspconfig[server_name].setup(server_opts)
        end,
      })
    end,
  },
}
