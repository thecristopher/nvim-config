-- PR review: <leader>pr or :Review [number|url] has Claude analyze any PR's changes.

return {
  {
    dir  = vim.fn.stdpath("config"),
    name = "pr-review",
    lazy = true,
    cmd  = { "Review" },
    keys = {
      { "<leader>pr", function() require("core.review").open() end, desc = "PR: analyze with Claude" },
    },
    config = function()
      vim.api.nvim_create_user_command("Review", function(opts)
        require("core.review").open(opts.args)
      end, { nargs = "?", desc = "Analyze a PR with Claude" })
    end,
  },
}
