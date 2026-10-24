-- Tests in place: neotest runs the one under the cursor and marks each test in the gutter.
-- :Trial (<leader>cT) still runs the whole suite in the background and announces the verdict.

local function neotest() return require("neotest") end

local function this_file() return vim.fn.expand("%") end

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
    },
    keys = {
      { "<leader>Tt", function() neotest().run.run() end,                            desc = "Run nearest test" },
      { "<leader>Tf", function() neotest().run.run(this_file()) end,                 desc = "Run file" },
      { "<leader>Ta", function() neotest().run.run(vim.uv.cwd()) end,                desc = "Run all in project" },
      { "<leader>Tl", function() neotest().run.run_last() end,                       desc = "Run last" },
      { "<leader>Td", function() neotest().run.run({ strategy = "dap" }) end,        desc = "Debug nearest test" },
      { "<leader>TS", function() neotest().run.stop() end,                           desc = "Stop" },
      { "<leader>Ts", function() neotest().summary.toggle() end,                     desc = "Summary" },
      { "<leader>To", function() neotest().output.open({ enter = true, auto_close = true }) end, desc = "Output" },
      { "<leader>TO", function() neotest().output_panel.toggle() end,                desc = "Output panel" },
      { "<leader>Tw", function() neotest().watch.toggle(this_file()) end,            desc = "Watch file" },
      { "]T",         function() neotest().jump.next({ status = "failed" }) end,     desc = "Next failed test" },
      { "[T",         function() neotest().jump.prev({ status = "failed" }) end,     desc = "Prev failed test" },
    },
    opts = function()
      return {
        -- each adapter only claims files from projects that depend on its runner
        adapters = {
          require("neotest-vitest"),
          require("neotest-jest")({}),
          require("neotest-python")({ runner = "pytest" }),
          require("neotest-plenary"),
        },
        status   = { virtual_text = true, signs = true },
        output   = { open_on_run = false },
        quickfix = { open = false },
        floating = { border = "rounded" },
        icons = {
          passed  = "✓",
          failed  = "✗",
          running = "◈",
          skipped = "○",
          unknown = "·",
          running_animated = { "◇", "◈", "◆", "◈" },
        },
      }
    end,
  },
}
