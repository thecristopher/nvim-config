# Pixel sprites

`lua/core/pixel/`: the tiny 8 bit sprite the region's character pops in a float at the top right of
the window, stepping through its frames (`FRAME_MS`) on core/motion's clock: on a save (one in
`SAVE_CHANCE`) and on every banner (`core/banner` calls `pop(name)`), the same sprite for every
moment. Sprites live in the lore's `pixels.lua`, keyed by region like `voices.lua`: `colors` maps
each pixel letter to a palette slot and `frames` holds the frames (`.` is transparent, two pixel
rows per cell with `▀▄█`). Each region's rows and highlight groups are built once and dropped on
`ColorScheme`. A region without one stays quiet. So far only Elizabeth's `westview` (a hex),
`danger_room` (a katana swoosh) and `haligtree` (a scarlet rot butterfly) have one. `:Pixel`
previews, `vim.g.eldentree_pixels = false` turns it off.
