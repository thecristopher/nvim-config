# Claude panel

`lua/core/claude_panel/`: the claudecode side panel (`DEFAULT_SHARE` of the editor). `<leader>aF` /
`:ClaudeFullscreen` lets it take the whole editor (the rest folds to its border, `winwidth` drops to
1) and hides the HUD portrait, again to put the layout back with `core/resize`. While fullscreen,
focus that lands on a collapsed window (a float closing, a picker looking for its main window) goes
back to Claude so it never gets squeezed, and a new split ends fullscreen and resets the layout
(`on_focus` in its actions).
