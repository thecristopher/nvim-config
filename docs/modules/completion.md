# Completion

Completion: blink for the LSP, paths and snippets, Copilot as inline ghost text (`<Tab>` accepts it
first, `accept_copilot` in `plugins/completion.lua`) plus next edit suggestions through copilot-lsp
(`<Tab>` in normal mode). blink's own ghost text stays off so the two never overlap.
`lua/core/copilot/` asks the server once whether someone is signed in and, if not, leaves one INFO
hint naming `:Copilot auth` (one sign in covers ghost text and NES). Inside a back-to-basics
exercise (`vim.b.btb_exercise`) `M.mute` empties every ghost text and next edit suggestion, and
blink takes the LSP alone and offers only function and method names, inserted bare (`function_names`
in `core/btb/actions`). Signature help stays hidden there too: `plugins/completion.lua` wraps
blink's `signature.trigger.show` (blink reads `signature.enabled` only at setup) and dive's `<C-k>`
does nothing in an exercise. `plugins/btb.lua` passes `completion = true` so the plugin leaves blink
on and Eldentree decides what an exercise completes.
