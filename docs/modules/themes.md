# Theme

Theme: catppuccin mocha recolored per region of the franchise in use. Color math lives in
`lua/core/themes/actions/`, switch with `<leader>jr` or `:Region`. One region per day, the same in
every repo and every launch (`of_the_day`, from the date and the franchise). Picking one with
`<leader>jr`, `:Region` or the HUD holds until midnight (`eldentree_region` in state keeps the day
and the name), and traveling between repos never changes it. `vim.g.eldentree_region` pins one
everywhere. Each region has a `character` and a `portrait` in `images/portraits/` (pre-cropped to
828x1008, three times the 276:336 box the layouts use, game art with contrast and color lifted, the
real photos in `PHOTOS` only lightly sharpened) that the hub shows when the file exists. Every
portrait carries 72 DPI in its JFIF header (`stamp_density` in `scripts/portraits.py`, checked by
`tests/core/portraits_spec.lua`): ffmpeg wrote its pixel aspect there and snacks, which sizes images
by DPI, drew them a twentieth of their box. A region may also have a `figure`, the whole photo
(662x1186, shaped 331:593 like `FIGURE_RATIO` in `core/hud/actions`), which views with
`SHOWS_FIGURES` draw instead of the portrait (`image_for`), like the wardrobe's mirror. The
originals live in `images/` and `scripts/portraits.py` crops them (`FACES` says where each face
sits, `FIGURES` which ones also get a figure). Adding a region means a palette in the lore's
`regions.lua`, plus its `weather` and `bosses` entries. A region may carry its own `hub_messages`,
which the HUD reads instead of the lore's so a role only speaks of its own character: every
Elizabeth role has them, and her shared lines, templates and landmarks name no character. Never hard
code hex colors in plugin specs, read `require("core.themes").palette()` so they follow the region.
Each skin has a syntax signature (`skin.syntax`: a color, a derived name or a palette slot, and a
style per role, `italic = false` strips every italic). `core/themes/actions.syntax` resolves it so
keyword, function and type stay apart from the error color and from each other. `derive` gives
`keyword`, `func` (under the text), `comment` (`COMMENT_CONTRAST`, 4.5 on the cursor line and under
the parameters), `border` and `search`, so the accent marks focus (cursor number, mode, scope,
titles) instead of every token. Every palette meets `SLOT_FLOORS` (overlay0 3.0, overlay1 4.0,
overlay2 4.5, the accent 4.5 and red 4.5 on its own error background, measured by `slot_contrast`),
so line numbers, delimiters, footers, inlay hints and error messages read in every region: lift a
slot toward the region's `text` when a new palette falls short, never touch the character's hue. The
gutter's fade stops at `GUTTER_FLOOR`. `validate.lua` checks the signature, the hue gap, the comment
contrast and the floors. Catppuccin compiles per franchise and region.
