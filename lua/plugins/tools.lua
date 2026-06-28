-- Formatting (conform) + Linting (nvim-lint)

return {
  -- ── conform: auto-formatting ─────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd   = { "ConformInfo" },
    keys  = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
    },
    opts = {
      formatters_by_ft = {
        lua         = { "stylua" },
        python      = { "isort", "black" },
        javascript  = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
        typescript  = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        vue         = { "prettierd", "prettier" },
        svelte      = { "prettierd", "prettier" },
        css         = { "prettierd", "prettier" },
        scss        = { "prettierd", "prettier" },
        less        = { "prettierd", "prettier" },
        html        = { "prettierd", "prettier" },
        json        = { "prettierd", "prettier" },
        jsonc        = { "prettierd", "prettier" },
        yaml        = { "prettierd", "prettier" },
        markdown    = { "prettierd", "prettier" },
        ["markdown.mdx"] = { "prettierd", "prettier" },
        graphql     = { "prettierd", "prettier" },
        sh          = { "shfmt" },
        bash        = { "shfmt" },
        zsh         = { "shfmt" },
        toml        = { "taplo" },
        rust        = { "rustfmt" },
        go          = { "goimports", "gofumpt" },
        fish        = { "fish_indent" },
        terraform   = { "terraform_fmt" },
        ["_"]       = { "trim_whitespace" },
      },
      format_on_save = function(bufnr)
        -- Disable format-on-save for large files and certain paths
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return {
          timeout_ms   = 3000,
          lsp_fallback = true,
        }
      end,
      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        black = {
          prepend_args = { "--line-length", "100" },
        },
        prettierd = {
          env = { PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath("config") .. "/.prettierrc.json" },
        },
      },
    },
  },

  -- ── nvim-lint: async linting ──────────────────────────────────────
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python      = { "ruff" },
        javascript  = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript  = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue         = { "eslint_d" },
        svelte      = { "eslint_d" },
        sh          = { "shellcheck" },
        bash        = { "shellcheck" },
        lua         = { "selene" },
        dockerfile  = { "hadolint" },
        markdown    = { "markdownlint" },
        go          = { "golangcilint" },
        yaml        = { "yamllint" },
      }

      -- Run lint on save and buffer enter
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          -- Only lint files (skip special buffers)
          if vim.opt_local.modifiable:get() then
            lint.try_lint(nil, { ignore_errors = true })
          end
        end,
      })

      -- Keymap to trigger lint manually
      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Trigger linting" })
    end,
  },
}
