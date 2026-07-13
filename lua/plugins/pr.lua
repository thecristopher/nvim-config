-- PR helper — draft, edit, and create/update a GitHub PR without leaving nvim.
-- <leader>pp: Claude drafts a title + description from your commit log/diff,
-- opens it in an editable buffer; :w pushes (if needed) and runs gh pr create/edit.

return {
  {
    -- Local module, no external package.
    -- lazy.nvim only wires the keymap; the module loads on first use.
    dir  = vim.fn.stdpath("config"),
    name = "pr-helper",
    lazy = true,
    keys = {
      { "<leader>pp", function() require("core.pr").open() end, desc = "PR: draft & create/update" },
    },
    config = function()
      local ok, wk = pcall(require, "which-key")
      if ok then wk.add({ { "<leader>p", group = "pr" } }) end
    end,
  },
}
