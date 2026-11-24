# Skin

`lua/core/skin/`: applies the franchise skin: `vim.o.winborder` (so snacks pickers, hovers and
Eldentree floats follow it), the cursor's shapes (`skin.cursor`, turned into `guicursor` by
`core/themes/actions`), the small marks in `skin.glyphs` (indent guides and scope, listchars, fold
and diff fill, the lines between windows (`split`) and the mark past the end of the buffer (`eob`),
the picker prompt, which-key's icons, satellite's thumb and noice's spinner, registered as
`eldentree`), pushed live into each loaded plugin by `core/skin/glyphs.lua` (every push in a pcall,
they reach into plugin internals) while the specs read them on load, diagnostic signs, lualine
separators and bufferline tabs (re-setup from their lazy specs on switch). Never hard code a float
border or a level glyph, use `require("core.skin").border()` and `require("core.skin").icon(level)`
(`skin.icons`, read by lualine, bufferline and every notification, snacks' own icons stay blank so
the franchise's wins), and `require("core.skin").title(text)` for ornamented titles. Every glyph in
a lore, skin or view must exist in the Nerd Font (JetBrainsMono Nerd Font Mono): symbols the font
lacks get drawn by the terminal from another font with a different weight and size. Prefer the `md-`
Material icons (the grace is `md-star_four_points`, the petals `md-flower`). The only exception is
RE's `₧`, the merchant's currency, which has no icon. On `EldentreeFranchise` the skin re-setups
lualine and bufferline after `forget_resolved_opts` drops lazy's cached opts, so the new franchise's
separators and tabs really apply. BMP Private Use glyphs (U+E000 to U+F8FF) get lost when written as
literal text: prefer `md-` glyphs and write a needed PUA glyph as a Lua escape (`"\u{E0BC}"`).
`tests/core/glyphs_spec.lua` fails on any icon, glyph, sign or symbol key left `""` or `" "` outside
its allow list.
