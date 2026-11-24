# CI

`lua/core/ci/`: the branch's CI run from `gh run list` in the statusline (`ci` in the lore), polled
faster while it runs and never while unfocused, rechecked after `<leader>gk`. A run that finishes in
front of you fires `felled` or `died`. `:CI` / `<leader>gi`, `vim.g.eldentree_ci = false`. `:CI` on
a failed run opens the failing step's log (`gh run view --log-failed`, trimmed by `failed_excerpt`)
in a float, `o` opens the browser. The branch is read from `.git/HEAD`, never with a sync git call.
