# HUD

`lua/core/hud/`: the start screen, an inventory HUD drawn in its own buffer (`eldentree_hud`),
opened on an empty start, with `:Hud` or `<leader>jh`. `skin.dashboard` picks the view in
`core/hud/views/`: `roundtable` (Elden Ring: category tabs, Inventory and Chest grids, the
description under them), `inventory` (Resident Evil: STATUS panel with the survivor and DATA, plate
tabs ITEM KEYS BOX FILE MAP EXIT, the COMMAND menu EQUIP CHECK COMBN, the item banner) and
`wardrobe` (Elizabeth: her whole figure in a vanity mirror ringed with hearts on the left, over a
dressing table, standing every row the mirror leaves up to `PORTRAIT.max` (60), and beside her a
marquee sign, the tabs hanging as tags from a clothes rail and two framed columns, the rack with a
close up of the selected piece and the stages with the call sheet of the quest, capped at
`SIDE_MAX`. The mirror stays on the left while its portrait stands at least `LEFT_SHARE` of the
tallest any shape allows, otherwise it stands above the body). The hub chases light around every
heart (`HEART` in the view, `heart_lit` in the hub's actions), and a lore's `hud_tabs` renames the
roundtable and wardrobe tabs (Elizabeth's Vanity, Props, Roles). Views are pure (model in, lines and
marks out) and size themselves from the window in their `plan`: the portrait gets the room first and
should always show: every shape is tried (beside a body of two columns or more, beside a single
column, above the body with the name under it) and `biggest_portrait` in `core/hud/actions` keeps
the one where it stands tallest, the quest or changed file rows give way before it does, then the
grid, and in roundtable the quest's changes also give their rows up before the inventory drops under
`GRID_ROWS.comfort` (two rows). In inventory both columns share their edges: the plates start on
STATUS's top edge and DATA ends on its bottom edge, the room left over goes between the grid and
DATA. The whole stage is centered, chunks carry a `spot` so the cursor and the portrait land exactly
where the layout put them. The quest's last file is the newest recent file inside the project
(`last_in`), not the newest anywhere. `core/hud/views/parts.lua` holds the pieces the views share
(the champion's plaque, the quest block with branch and changes, the changed files).
`core/hud/items.lua` fills the tabs from real data, and anything that needs a process (branches with
their ahead counts in one `for-each-ref`, stashes, the map survey) goes through
`core/hud/background.lua`, a cache fetched again in the background every 10 s that rebuilds the tabs
when something new lands, so building them never waits on git. Snacks' image detection runs in the
background too, and nothing may touch snacks' image code until the terminal answers: snacks would
settle its environment without the answer (Ghostty is only known from it) and keep it all session.
Meanwhile `supports_images` in `core/terminal` says no, `awaiting_images` says whether pixels are
coming, and portraits asked for in that moment wait and draw on `User EldentreeImagesKnown` (hub
keys in `core/hud/keys.lua`, recent files, branches and stashes, ground messages, regions, projects
with changed file counts, map rooms), every item has `use`, `check` and maybe `combine`. hjkl move,
Tab switches tabs, Enter uses (or opens COMMAND in RE), K checks, C combines, `?` opens the palette,
the hub keys and digits still work directly. Reopening lands on the tab and slot you left
(`resume_place`), unless the franchise changed. `core/hud/portrait.lua` draws the champion with
chafa or real pixels, first throwing away snacks' converted copies older than the image
(`stale_copies`), since snacks keys its cache by path alone and a recropped portrait would keep its
old pixels, and converting and sending it again when its mtime changed during the session
(`reload_if_changed`), since snacks also keeps every image it loaded in memory. The HUD's looks come
from `hud_groups` in `core/hud/actions`, and its transitions start from a lit or sunk copy and fade
to rest on core/motion's clock: the selection glows and settles on every move (`selection_flash`), a
new tab flashes its plate or rule, and the whole HUD rises out of the background when it opens
(`sunk`). The key hints color each key apart from its label (`hint_chunks`). The selected item's
description types itself in (`typing_ms`, `reveal` in core/hud/actions, views cut it with
`model.typed`). The trophies tab (`items.trophies`, counting in `core/hud/actions/trophies.lua`,
words in `lore.trophies`) sits inside Resident Evil's FILE tab. While music plays, `parts.player`
takes the stats row (the gap above the message in inventory), reading `core.music.now_playing()` and
redrawing on `User EldentreeMusicChanged`. The snacks dashboard is off Each lore has a `hud.lua`
(`lore.hud`): `keys` (name, slot, desc and flavor per hub key), `tabs`, `tab_icons`, `kinds`
(category and flavor per item kind), `trophy_icons`, `stats` (the Roundtable's attributes, RE's
conditions and ribbons, the call sheet's labels), `used` (the Roundtable's use toast), a lore's
optional `guest_messages` (`GUEST_CHANCE`), and `validate` asks each view for what it reads.
Roundtable: runes held in the corner, an item screen band (name, category, effect, italic flavor), a
glint along the selected frame (`state.glint`, `glint_run`), the attributes under the plaque when
every pair fits or in the footer otherwise, and an "Obtained" toast on use. Resident Evil: the grid
is an attaché case (`pack`, `case_move`, `case_scroll`, `joint` in `core/hud/actions`, items carry
`size`), with the condition (FINE, CAUTION, DANGER) under the survivor, the typewriter caret and ink
ribbons on the banner, and Check opening a paged file reader (`pages`). Elizabeth: the call sheet
reads SCENE, CAST, LOCATION and CALL, and a spotlight spills onto the rows beside the selection. HUD
floats open beside the selection (`float_beside`) and hide the portrait while open, `:Hud` from a
float opens in a regular window and wipes the blank start buffer, Recent files carry their folder
when names collide (`file_labels`) and the trophies say where each number comes from. HUD text never
shows a label or a sentence cut mid word: names are only cut where they break (`fit_words`,
`fit_name`), dates, call times and DATA values shorten to their first whole form (`first_fit`), and
greetings, flavor lines, messages and areas show whole or give their row away (`wrap_whole`,
`parts.whole_line`).
