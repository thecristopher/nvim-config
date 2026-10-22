-- Commit helper — Claude-drafted commit messages from inside nvim.
-- <leader>pc: stage related changes, pick a vibe, get a message, edit, commit on :w.

return {
  {
    dir  = vim.fn.stdpath("config"),
    name = "commit-helper",
    lazy = true,
    keys = {
      { "<leader>pc", function() require("core.commit").open() end, desc = "Commit: draft with Claude" },
    },
  },
}
