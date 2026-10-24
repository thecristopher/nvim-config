-- Debugging: nvim-dap with dap-view, F keys like VS Code next to the F12 family in core/dive.
-- Terminals send shifted F keys as F13 and up, so each shifted key is bound under both names.

local function dap() return require("dap") end

-- js-debug speaks for node, and launch.json files written for VS Code say "node"
local function setup_js(adapters, configurations)
  local js_debug = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = { command = "js-debug-adapter", args = { "${port}" } },
  }
  adapters["pwa-node"] = js_debug
  adapters.node = js_debug

  local launches = {
    { type = "pwa-node", request = "launch", name = "Launch this file", program = "${file}", cwd = "${workspaceFolder}" },
    {
      type = "pwa-node", request = "attach", name = "Attach to a node process",
      processId = function() return require("dap.utils").pick_process() end, cwd = "${workspaceFolder}",
    },
  }
  for _, filetype in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
    configurations[filetype] = configurations[filetype] or launches
  end
end

local function define_signs()
  local signs = {
    DapBreakpoint          = { text = "●", texthl = "DapBreakpoint" },
    DapBreakpointCondition = { text = "◆", texthl = "DapBreakpointCondition" },
    DapLogPoint            = { text = "◈", texthl = "DapLogPoint" },
    DapBreakpointRejected  = { text = "○", texthl = "DapBreakpointRejected" },
    DapStopped             = { text = "󰁕", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "DapStopped" },
  }
  for name, sign in pairs(signs) do vim.fn.sign_define(name, sign) end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "igorlfs/nvim-dap-view",
      "jay-babu/mason-nvim-dap.nvim",
    },
    keys = {
      { "<F5>",       function() dap().continue() end,           desc = "Debug: start or continue" },
      { "<S-F5>",     function() dap().terminate() end,          desc = "Debug: stop" },
      { "<F17>",      function() dap().terminate() end,          desc = "Debug: stop" },
      { "<F9>",       function() dap().toggle_breakpoint() end,  desc = "Debug: toggle breakpoint" },
      { "<F10>",      function() dap().step_over() end,          desc = "Debug: step over" },
      { "<F11>",      function() dap().step_into() end,          desc = "Debug: step into" },
      { "<S-F11>",    function() dap().step_out() end,           desc = "Debug: step out" },
      { "<F23>",      function() dap().step_out() end,           desc = "Debug: step out" },
      { "<leader>Dc", function() dap().continue() end,           desc = "Start or continue" },
      { "<leader>Db", function() dap().toggle_breakpoint() end,  desc = "Toggle breakpoint" },
      {
        "<leader>DB",
        function() dap().set_breakpoint(vim.fn.input("Condition: ")) end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>Dp",
        function() dap().set_breakpoint(nil, nil, vim.fn.input("Log message: ")) end,
        desc = "Log point",
      },
      { "<leader>Do", function() dap().step_over() end,          desc = "Step over" },
      { "<leader>Di", function() dap().step_into() end,          desc = "Step into" },
      { "<leader>DO", function() dap().step_out() end,           desc = "Step out" },
      { "<leader>Dl", function() dap().run_last() end,           desc = "Run last" },
      { "<leader>DC", function() dap().run_to_cursor() end,      desc = "Run to cursor" },
      { "<leader>Dt", function() dap().terminate() end,          desc = "Stop" },
      { "<leader>DX", function() dap().clear_breakpoints() end,  desc = "Clear breakpoints" },
      { "<leader>Dv", function() require("dap-view").toggle() end, desc = "Toggle debug view" },
      { "<leader>Dw", function() require("dap-view").add_expr() end, desc = "Watch expression", mode = { "n", "x" } },
      { "<leader>Dh", function() require("dap-view").hover() end,  desc = "Inspect value", mode = { "n", "x" } },
    },
    config = function()
      define_signs()
      require("mason-nvim-dap").setup({
        ensure_installed = { "js", "python" },
        automatic_installation = false,
        handlers = {
          function(config) require("mason-nvim-dap").default_setup(config) end,
          js = function() setup_js(dap().adapters, dap().configurations) end,
        },
      })
    end,
  },

  {
    "igorlfs/nvim-dap-view",
    lazy = true,
    opts = {
      winbar = {
        sections = { "scopes", "watches", "breakpoints", "threads", "exceptions", "repl", "console" },
        default_section = "scopes",
        controls = { enabled = true },
      },
      windows = { size = 0.3, terminal = { position = "right" } },
      -- the values of every variable on screen, written right after the code that set them
      virtual_text = { enabled = true, position = "eol" },
      auto_toggle = true,
    },
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = true,
    dependencies = { "mason-org/mason.nvim" },
  },
}
