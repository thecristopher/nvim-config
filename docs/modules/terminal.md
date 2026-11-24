# Terminal

`lua/core/terminal/`: OSC 11 paints the terminal background with the region base, iTerm switches to
the skin's profile when `vim.g.eldentree_iterm_profiles = true` (profiles in
`terminal/iterm/Eldentree.json`), Kitty takes `kitty_opacity` with `vim.g.eldentree_kitty_remote =
true`, Ghostty reloads `~/.config/ghostty/eldentree` written from the skin's `ghostty` table (macOS
AppleScript, `vim.g.eldentree_ghostty_config = true`), only when the file changes. Each nvim leaves
its pid in `eldentree_ghostty/` in state and only the last one to leave empties the file. After a
reload `User EldentreeTerminalSettled` fires and the HUD portraits draw again, sending the image
anew. A reload drops the images of every tab, so the nvim that reloads leaves its pid in
`eldentree_ghostty_settled` in state and every other nvim dressing Ghostty polls it and fires the
event too. `:Opacity [90|skin]` or `<leader>uo` overrides the skin's opacity in Kitty and Ghostty,
saved in `eldentree_opacity` in state. The Ghostty file is written atomically (a temp file and a
rename), a suspend only resets OSC 11, and quitting waits at most 500 ms for the reload.
