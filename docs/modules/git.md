# Git

`lua/core/git/`: quick git keys under `<leader>g` (`N` new branch, `j` pull, `k` push, `m`/`M` base
branch, `z`/`Z` stash, `u` undo commit) and the related change staging `<leader>pc` runs first.
`QUICK_KEYS` in its actions is the one list behind the keymaps and the toggleterm winbar hint. Keep
`<leader>g` maps at two keys so none waits on a timeout. Every git call runs in the buffer's repo
(`core.git.repo()`, then the project, then cwd). `<leader>pc` commits there with `git commit` in the
background under the progress bar (hooks never freeze the UI, a failing hook reopens the draft),
Claude reads every file's diff trimmed to a fair share of the budget (`core.git.actions.trim_diff`),
and the files left out are listed as comments at the bottom of the draft. Claude runs stop after 3
minutes (`core.claude.actions.TIMEOUT_MS`).
