# Resize

`lua/core/resize/`: resizing every window. Hovering a border with a window across it lights it and
draws a handle the mouse drags through (the statusline under the lowest window never gets one),
placed from the window's geometry so it rides the border while it moves. `<leader>sw` / `:Resize`
lights the borders hjkl will move and moves them (shift for bigger steps, `=` resets), `<leader>se`
/ `:ResizeReset` puts the tree and the Claude panel at their defaults and equalizes the rest. The
tree stays between `TREE_MIN` and `TREE_MAX` whatever moved it, except while Claude is fullscreen.
