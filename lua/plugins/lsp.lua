-- LSP: mason installs servers, native vim.lsp.config wires them up

local function setup_diagnostics()
  local severity = vim.diagnostic.severity
  vim.diagnostic.config({
    virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
    signs = {
      text = {
        [severity.ERROR] = " ",
        [severity.WARN]  = " ",
        [severity.HINT]  = " ",
        [severity.INFO]  = " ",
      },
    },
    update_in_insert = false,
    underline        = true,
    severity_sort    = true,
    float = { border = "rounded", source = true, header = "", prefix = "" },
  })
end

local function get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then capabilities = blink.get_lsp_capabilities(capabilities) end
  -- lets servers watch files without nvim polling (big win in large repos)
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }
  return capabilities
end

local ts_inlay_hints = {
  parameterNames         = { enabled = "literals" },
  parameterTypes         = { enabled = true },
  variableTypes          = { enabled = false },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes  = { enabled = true },
  enumMemberValues       = { enabled = true },
}

local ts_settings = {
  updateImportsOnFileMove = { enabled = "always" },
  suggest     = { completeFunctionCalls = true },
  inlayHints  = ts_inlay_hints,
  -- Next.js monorepos blow past the default 3GB tsserver heap
  tsserver    = { maxTsServerMemory = 8192 },
  preferences = { importModuleSpecifier = "non-relative" },
}

-- Servers installed through mason. Anything listed here is auto enabled.
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        workspace   = { checkThirdParty = false },
        completion  = { callSnippet = "Replace" },
        diagnostics = { globals = { "vim", "Snacks", "describe", "it", "before_each", "after_each" }, disable = { "missing-fields" } },
        hint        = { enable = true, setType = false, paramType = true, paramName = "Disable", semicolon = "Disable", arrayIndex = "Disable" },
      },
    },
  },

  -- TypeScript, JavaScript, React and Next.js
  vtsls = {
    settings = {
      complete_function_calls = true,
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk       = true,
        experimental = {
          maxInlayHintLength = 30,
          completion = { enableServerSideFuzzyMatch = true },
        },
      },
      typescript = ts_settings,
      javascript = ts_settings,
    },
  },
  eslint = { settings = { workingDirectories = { mode = "auto" } } },
  tailwindcss = {},
  emmet_language_server = {
    filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "php", "blade" },
  },
  cssls = {},
  html  = {},

  -- Python: pyright for types, ruff for lint, imports and formatting
  pyright = {
    settings = {
      pyright = { disableOrganizeImports = true },
      python  = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = "openFilesOnly", typeCheckingMode = "basic" } },
    },
  },
  ruff = {},

  -- PHP
  intelephense = {
    settings = { intelephense = { files = { maxSize = 5000000 } } },
  },

  rust_analyzer = {},
  bashls   = {},
  jsonls   = { settings = { json = { validate = { enable = true } } } },
  yamlls   = { settings = { yaml = { schemaStore = { enable = false, url = "" }, validate = true } } },
  marksman = {},
  dockerls = {},
  docker_compose_language_service = {},
  taplo    = {},
}

-- gopls needs a Go toolchain to build, so only ask for it when one exists
if vim.fn.executable("go") == 1 then servers.gopls = {} end

-- Not on mason: these ship with their toolchains
local system_servers = {
  -- Xcode bundles sourcekit-lsp; scoped to Swift so it leaves clangd alone
  sourcekit = {
    executable = "sourcekit-lsp",
    config = { filetypes = { "swift", "objc", "objcpp" } },
  },
}

local function attach_schemas()
  local ok, schemastore = pcall(require, "schemastore")
  if not ok then return end
  servers.jsonls.settings.json.schemas = schemastore.json.schemas()
  servers.yamlls.settings.yaml.schemas = schemastore.yaml.schemas()
end

local function configure_servers()
  vim.lsp.config("*", { capabilities = get_capabilities() })
  attach_schemas()

  for name, config in pairs(servers) do
    vim.lsp.config(name, config)
  end

  for name, server in pairs(system_servers) do
    if vim.fn.executable(server.executable) == 1 then
      vim.lsp.config(name, server.config)
      vim.lsp.enable(name)
    end
  end
end

local function setup_attach()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("eldentree_lsp_attach", { clear = true }),
    callback = function(ev)
      require("core.dive").attach(ev.buf)
    end,
  })
end

local mason_tools = { "stylua", "shfmt", "prettierd", "shellcheck", "selene" }
if vim.fn.executable("php") == 1 then table.insert(mason_tools, "php-cs-fixer") end

return {
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

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "mason-org/mason.nvim",
    cmd   = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    keys  = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts  = {
      ui = {
        border = "rounded",
        icons  = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local registry = require("mason-registry")
      registry.refresh(function()
        for _, tool in ipairs(mason_tools) do
          local found, package = pcall(registry.get_package, tool)
          if found and not package:is_installed() then package:install() end
        end
      end)
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    -- a function so it runs after mason has put its bin folder on PATH
    opts = function()
      local exclude = { "stylua" } -- conform already runs it on save
      -- ts_ls stays as a fallback until vtsls installs, both at once would double every diagnostic
      if vim.fn.executable("vtsls") == 1 then table.insert(exclude, "ts_ls") end
      return {
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = { exclude = exclude },
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "folke/lazydev.nvim",
      "b0o/SchemaStore.nvim",
    },
    config = function()
      setup_diagnostics()
      setup_attach()
      configure_servers()
      -- mason-lspconfig enables servers, so it must load after vim.lsp.config ran
      require("lazy").load({ plugins = { "mason-lspconfig.nvim" } })
    end,
  },
}
