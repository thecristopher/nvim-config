# Progress

`lua/core/progress/`: the one way to report a wait. `require("core.progress").start({ id, title,
message })` keeps a notification on screen with a bar in the skin's `music.bar` style and the
elapsed time, redrawn until `task:done(message)` or `task:fail(message)`, and `task:update(message,
fraction)` changes the text or fills the bar. Anything slow (Claude, git over the network, gh, test
runs, back-to-basics) uses it and runs async, so the bar never freezes and no status message expires
halfway.
