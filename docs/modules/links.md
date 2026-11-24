# Links

`lua/core/links/`: opens links terminals print. Ctrl+click opens the one under the mouse in a
toggleterm buffer (the terminal never sends Cmd to nvim) and hovering underlines it with
`EldenLink`, `<leader>to` opens the last one printed in any terminal. A url keeps a closing
parenthesis only when it opened one (a wiki page, not an aside), and a long url the terminal wrapped
over several lines opens whole, from whichever line was clicked (`logical_line` joins lines that
fill the terminal's width).
