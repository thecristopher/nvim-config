# Review threads

`lua/core/threads/`: the PR's open review threads through `gh api graphql`, as virtual text at the
end of their lines, asked once per repo on the first file read (`vim.g.eldentree_threads = false`
turns that off). `<leader>mc` / `:Threads` refetches and lists, `<leader>mo` opens the conversation,
`<leader>mr` resolves after asking. Words in `threads` in the lore. Refreshed after 5 minutes on
FocusGained, after a push and after the PR helper publishes. `:Threads` on a branch without a PR
says `threads.no_pr`, `require("core.threads").statusline()` (in lualine beside CI) and `.count()`
(in the HUD's quest) give the open count, `]r`/`[r` jump between threads.
