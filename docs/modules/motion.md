# Motion

`lua/core/motion/`: shared animation engine (tween, ambient loop, highlight fades) on one clock: a
single timer wakes for whoever is due next, beats count from the same epoch so rhythms that share a
period land on the same frame, and it stops when nothing is due. `<leader>um` or `:Motion` stills
everything, the plugins that animate on their own included (`vim.g.snacks_animate` for snacks scroll
and indent, `vim.g.minianimate_disable`, smear's `enabled`), ambient loops stop while unfocused and
a replaying macro jumps every tween to its last frame. Indent guides are snacks.indent, the region's
rainbow in `EldenIndent1..6` and the scope in `EldenIndentScope` (catppuccin `custom_highlights`),
drawn only on visible lines: indent-blankline recomputed its scope on every cursor move and was the
biggest cost of moving around. `core.utils.refresh_statusline()` folds every call in the same tick
into one repaint, so never call `lualine.refresh` directly. The code area stays calm: indent guides
in one quiet tone with only the scope in the accent and no scope animation, rainbow only on
brackets, treesitter context at most 2 lines following the topline on the panel color with a thin
underline instead of a separator row, blame a few spaces after the code after 1.5 s, and `o`/`O`
never continuing a comment.
