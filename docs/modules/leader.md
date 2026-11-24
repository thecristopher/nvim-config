# Leader keys

`lua/core/leader/`: every leader key Eldentree binds, in `BINDINGS` of its actions (a `call` like
`core.hud:open`, a `cmd`, a named `handler` or a snacks `toggle`), and every group with its
which-key name and icon in `GROUPS`. Groups: `a` claude, `b` buffer, `c` code, `D` debug, `f` find,
`g` git (`gh` hunks), `h` harpoon, `j` journey (the world's screens and the look of the day), `k`
back to basics, `m` messages and threads, `M` multicursor, `p` pull requests, `s` windows, `S`
sessions, `t` terminal, `T` tests, `u` toggles, `x` diagnostics. Never `vim.keymap.set` a global
leader key inside a module, add a row there instead. Groups marked `owner = "plugins"` take their
keys from lazy specs. Its specs fail on a key bound twice, a key that makes another wait for the
timeout, or a palette key nobody binds.
