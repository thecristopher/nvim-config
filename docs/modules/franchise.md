# Franchise

Franchise: `lua/core/franchise/` picks the world the whole config speaks, rotating one per day
(Elden Ring, Resident Evil, Elizabeth). `:Franchise` or `<leader>jf` switches until midnight,
`vim.g.eldentree_franchise` pins one. A lore with `opt_in = true` (Elizabeth's) only plays where
`vim.g.eldentree_opt_in` names it, set in `lua/core/options_local.lua`, a git ignored file
`core/options` loads and the `claude/*.lua` entry points read too. `names()` in
`core/franchise/actions` is what this machine plays, `all_names()` every folder, for checkhealth and
the specs. Each franchise is a lore folder in `lua/core/franchise/lore/<name>/`, discovered on its
own (no list to register it in): `regions.lua` with the palettes, `skin.lua` with how components
look, `lines.lua` with what the helpers and the HUD say, and `init.lua` with bosses, weather,
banners, hub messages, message templates, landmarks, places, item categories and words. Modules read
`require("core.franchise").current()` instead of keeping their own copies, so never hard code
franchise text in a module. `mechanics` in each lore picks the version a module plays (`travel` fog,
door or curtain, `boss` duel, stalker or scene, `status` grace, ecg or heartbeat, `rest` embers,
typewriter or golden_hour, `ranking`), read it with `require("core.franchise").mechanic(name)`.
`currency`, `merchant` and `banner_styles` (per kind overrides like the dripping death) live there
too. What the HUD, the commit and PR helpers, `:Review` and `:Trial` say lives in each lore's
`lines.lua`: every key and its plain line is in `lua/core/franchise/lines.lua`, a line may be a list
(one is picked each time) and may use `{character}` (the region's character), `{traveler}`,
`{world}` and its own holes. Read them with `require("core.franchise").line(key, vars)`, or
`lines("hud", vars)` for every HUD word at once (views get them as `model.words` and read them
through `parts.word`, falling back to the plain line), and never write a user facing word in those
modules. Errors that explain a technical failure stay plain. `:checkhealth` asks every lore for
every line. `:Franchise new <name>` copies `lua/core/franchise/template/` into a new lore folder,
and `:checkhealth eldentree` runs `core/franchise/actions/validate.lua` over every franchise
(missing words, bosses, weather, portraits, palette contrast, and a mechanic, view, picker or title
style nobody built). Switching fires `User EldentreeFranchise`, everything that dresses up per
franchise listens to it.
