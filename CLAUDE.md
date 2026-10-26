# Eldentree — nvim-config

This is Cristopher's personal Neovim configuration. The my-style guide is always active for
every session in this repo (see the style section below).

---

## Project context

- Plugin manager: lazy.nvim (stable branch)
- All plugin configs live in `lua/plugins/` (one file per concern), returning lazy.nvim spec tables
- Core config (options, keymaps, autocmds) lives in `lua/core/`
- Franchise: `lua/core/franchise/` picks the world the whole config speaks, rotating one per day (Elden Ring, Resident Evil). `:Franchise` or `<leader>uf` switches until midnight, `vim.g.eldentree_franchise` pins one. Each franchise is a lore folder in `lua/core/franchise/lore/<name>/`, discovered on its own (no list to register it in): `regions.lua` with the palettes, `skin.lua` with how components look, and `init.lua` with bosses, weather, banners, hub messages, message templates, landmarks, places, item categories and words. Modules read `require("core.franchise").current()` instead of keeping their own copies, so never hard code franchise text in a module. `mechanics` in each lore picks the version a module plays (`travel` fog or door, `boss` duel or stalker, `status` grace or ecg, `rest` embers or typewriter, `ranking`), read it with `require("core.franchise").mechanic(name)`. `currency`, `merchant` and `banner_styles` (per kind overrides like the dripping death) live there too. `:Franchise new <name>` copies `lua/core/franchise/template/` into a new lore folder, and `:checkhealth eldentree` runs `core/franchise/actions/validate.lua` over every franchise (missing words, bosses, weather, portraits, palette contrast). Switching fires `User EldentreeFranchise`, everything that dresses up per franchise listens to it
- `lua/core/skin/`: applies the franchise skin: `vim.o.winborder` (so snacks pickers, hovers and Eldentree floats follow it), diagnostic signs, lualine separators and bufferline tabs (re-setup from their lazy specs on switch). Never hard code a float border, use `require("core.skin").border()`, and `require("core.skin").title(text)` for ornamented titles
- `lua/core/hud/`: the start screen, an inventory HUD drawn in its own buffer (`eldentree_hud`), opened on an empty start, with `:Hud` or `<leader>uh`. `skin.dashboard` picks the view in `core/hud/views/`: `roundtable` (Elden Ring: category tabs, Inventory and Chest grids, the description under them) and `inventory` (Resident Evil: STATUS panel with DATA and the CONDITION ECG, plate tabs ITEM KEYS BOX FILE MAP EXIT, the COMMAND menu EQUIP CHECK COMBN, the item banner). Views are pure (model in, lines and marks out) and size themselves from the window in their `plan`: the portrait gets the room first, then the grid, and the whole stage is centered, chunks carry a `spot` so the cursor, the portrait and the ECG land exactly where the layout put them. `core/hud/views/parts.lua` holds the pieces both share (the champion's plaque, the quest line with branch and changes, the changed files). `core/hud/items.lua` fills the tabs from real data (hub keys in `core/hud/keys.lua`, recent files, branches and stashes, ground messages, regions, projects with changed file counts, map rooms), every item has `use`, `check` and maybe `combine`. hjkl move, Tab switches tabs, Enter uses (or opens COMMAND in RE), K checks, C combines, the hub keys and digits still work directly. `core/hud/portrait.lua` draws the champion with chafa or real pixels. The snacks dashboard is off
- `lua/core/title/`: the franchise title screen in block letters (shimmer or drip), once a day per franchise and on every switch, `:Title`, `vim.g.eldentree_title = false`
- `lua/core/terminal/`: OSC 11 paints the terminal background with the region base, iTerm switches to the skin's profile when `vim.g.eldentree_iterm_profiles = true` (profiles in `terminal/iterm/Eldentree.json`), Kitty takes `kitty_opacity` with `vim.g.eldentree_kitty_remote = true`, Ghostty reloads `~/.config/ghostty/eldentree` written from the skin's `ghostty` table (macOS AppleScript, `vim.g.eldentree_ghostty_config = true`), only when the file changes. Each nvim leaves its pid in `eldentree_ghostty/` in state and only the last one to leave empties the file. After a reload `User EldentreeTerminalSettled` fires and the HUD portraits draw again, sending the image anew. `:Opacity [90|skin]` or `<leader>uo` overrides the skin's opacity in Kitty and Ghostty, saved in `eldentree_opacity` in state
- `lua/core/sound/`: plays `sounds/<franchise>/<event>.{wav,mp3,aiff,m4a,ogg}` (variants as `event_2.wav`) for title, door, fog, rest, boss, merchant, phantom, continue (opening a repo visited before), the HUD's `hud_open`, `hud_close`, `hud_move`, `hud_select`, `hud_back` and every banner kind, `vim.g.eldentree_sound = false`, `:Sound <event>` previews. The files are built from scratch by `scripts/sounds.py` (stdlib synthesis, Piper voices with macOS `say` as fallback, ffmpeg), a recipe per event in its `RECIPES` table. `--setup-voices` installs Piper in `~/.local/share/eldentree` (keep that path short, espeak inside Piper fails on long data paths)
- `lua/core/door/`: the dark and the door that opens when the franchise travels by door, `core/fog` hands off to it
- `lua/core/ecg/`: the health ECG statusline piece (Fine, Caution, Danger) for franchises whose `status` is `ecg`
- `lua/core/map/`: `:Map` / `<leader>fM`, folders as rooms, red with errors or TODOs left, blue once cleared, `<CR>` opens the files picker there
- `lua/core/results/`: counts saves and fixes per run, ranks it S to D on exit (`eldentree_results.json` in state), the HUD shows it in STATUS
- Theme: catppuccin mocha recolored per region of the franchise in use. Color math lives in `lua/core/themes/actions/`, switch with `<leader>ut` or `:Region`. One region per day, the same in every repo and every launch (`of_the_day`, from the date and the franchise). Picking one with `<leader>ut`, `:Region` or the HUD holds until midnight (`eldentree_region` in state keeps the day and the name), and traveling between repos never changes it. `vim.g.eldentree_region` pins one everywhere. Each region has a `character` and a `portrait` in `images/portraits/` (pre-cropped, contrast lifted) that the hub shows when the file exists. Adding a region means a palette in the lore's `regions.lua`, plus its `weather` and `bosses` entries. Never hard code hex colors in plugin specs, read `require("core.themes").palette()` so they follow the region
- Leader: `<Space>` | Local leader: `\`
- `~/.config/nvim` is a symlink to this repo, so every saved `.lua` file is live immediately
- LSP uses native `vim.lsp.config` plus mason-lspconfig v2 (`automatic_enable`), servers live in `lua/plugins/lsp.lua`
- `lua/core/dive/`: F12 family (definition, Glance peek, references, F2 rename), bound on LspAttach. `K` hover floats are dressed as item descriptions (`item_categories` in the franchise lore)
- `lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root. A repo counts only when its `.git` leads to a readable `HEAD`. Traveling saves the old project's session (persistence) and restores the new one, unsaved buffers stay open
- `lua/core/motion/`: shared animation engine (tween, ambient loop, highlight fades). `<leader>um` or `:Motion` stills everything, ambient loops pause while unfocused
- `lua/core/banner/`: Elden Ring style banners (`:Banner felled|great|died|grace|cleansed`) fired by commits, PRs, `:Trial`, new Sites of Grace, region changes and long fights with errors. `died` crumbles the window behind it into cellular-automaton rain (`lua/plugins/fun.lua`) and closes it as the banner fades, `vim.g.eldentree_rain = false` turns that off
- `lua/core/hub/`: the HUD's ambient life: shimmering gold on ornamented rows, a typed player message and per region weather drifting through rows without frames (`weather` in the franchise lore: embers, rot petals, glintstone, rain, snow)
- `lua/core/fog/`: fog wall that rolls over the editor when you travel to a Site of Grace (`:Fog`, `<leader>uF` or `vim.g.eldentree_fog = false`)
- `lua/core/messages/`: Elden Ring style messages left on lines of code, stored per repo in state (`<leader>mw` write, `md` erase, `ml` list, `:Inscribe`, `:Inscriptions`)
- `lua/core/folds/`: the closed fold text nvim-ufo shows (first line plus a hidden line tally)
- `lua/core/review/`: `:Review [number|url]` / `<leader>pr` has Claude (headless, subscription) analyze a PR's diff into a float, `d` opens the diff per file
- `lua/core/git/`: quick git keys under `<leader>g` (`N` new branch, `j` pull, `k` push, `m`/`M` base branch, `z`/`Z` stash, `u` undo commit) and the related change staging `<leader>pc` runs first. `QUICK_KEYS` in its actions is the one list behind the keymaps and the toggleterm winbar hint. Keep `<leader>g` maps at two keys so none waits on a timeout
- `lua/core/trial/`: `:Trial` / `<leader>cT` runs the project's tests in the background and announces the verdict
- `lua/core/boss/`: boss health bar for buffers where 3+ errors linger 8 seconds, the region's boss (`bosses` in the franchise lore) takes a hit per fix and the last one fires the `felled` banner (`:Boss`, `<leader>uB` or `vim.g.eldentree_boss = false`)
- `lua/core/phantom/`: `<leader>gw` / `:Phantom` blames the buffer through stdin and shows the last author as a phantom float
- `lua/core/zones/`: first visit to a folder each session fires the quiet `zone` banner, `landmarks` in the franchise lore names well known folders
- `lua/core/snapshot/`: `<leader>cp` / `:Snapshot` builds an SVG card from the on screen highlights and renders it with `rsvg-convert` to `~/Pictures/Eldentree`
- `lua/core/utils/`: project wide helpers (the stable `hash`)
- `lua/core/links/`: opens links terminals print. Ctrl+click opens the one under the mouse in a toggleterm buffer (the terminal never sends Cmd to nvim) and hovering underlines it with `EldenLink`, `<leader>to` opens the last one printed in any terminal
- `lua/core/trace/`: `:InsertTrace` logs every exit from insert mode with the keys right before it (typed, mapped or sent by a plugin) to `eldentree_insert_trace.log` in state, off until toggled
- `lua/core/music/`: what Cider (REST API on `localhost:10767`, any OS) or Music.app (osascript, macOS) is playing, in the statusline. `<leader>o` or a click on it opens the now playing panel (`core/music/panel.lua`, layout in `actions/panel.lua`) with the album cover drawn by the HUD portrait, the song, artist and album beside it over a two row equalizer and the progress bar, and the lyrics from LRCLIB (`core/music/lyrics.lua`, timing in `actions/lyrics.lua`) between two dividers, the sung line swept karaoke style and its neighbors fading with distance, `l` shows or hides the lyrics (the panel shrinks without them), `j`/`k` scroll lyrics without timing. The bar, dividers and sung marks come from `music` in the skin, the panel title and lyric messages from `music` in the lore, `p` play/pause, `n` next, `b` previous. Covers are cached per album and lyrics per song in `stdpath("cache")/eldentree/music`, `vim.g.eldentree_lyrics = false` starts with the lyrics hidden, and hidden lyrics never ask LRCLIB. `:Music [playpause|next|previous]`. Cider is asked first, polling stops while nvim is unfocused. `vim.g.eldentree_cider_token` when Cider's auth is on, `vim.g.eldentree_music = false` turns it off
- `lua/core/claude_ui/` and `claude/`: Claude Code in the franchise. nvim rewrites `~/.claude/themes/eldentree.json` from the palette on `EldentreeRegionSettled` and `EldentreeFranchise`. `claude/*.lua` are tiny `nvim -l` entry points (they add the repo's `lua/` to the path, since `-l` skips the user config) for the statusline, the sound hook, the banner words and the installer, each calling `core.claude_ui.<name>.run`. `claude/install.lua` merges them into `~/.claude/settings.json`, replacing only its own hooks and keeping the first backup. Bar labels and spinner verbs live in each lore's `claude` table (`:checkhealth` requires it)
- `lua/core/runes/`: statusline rune tally (saves and banners pay out, YOU DIED leaves a bloodstain) plus the breathing grace glyph
- `lua/core/rest/`: after 5 idle minutes in normal mode the editor rests at a Site of Grace (`:Rest`, `vim.g.eldentree_rest_after`), any key wakes it and is swallowed
- `lua/plugins/debug.lua`: nvim-dap with dap-view, F5/F9/F10/F11 plus `<leader>D`, js-debug and debugpy come from mason
- `lua/plugins/test.lua`: neotest (vitest, jest, pytest, plenary) under `<leader>T`, `:Trial` still owns the whole suite verdict
- Cursor colors follow the mode through `guicursor` and the `EldenCursor*` groups, smear-cursor follows them too
- `lua/core/lint/`: decides which nvim-lint linters can run (installed, and selene only with a `selene.toml`)
- Treesitter runs on the `main` branch (master crashes on 0.12), parsers build with the tree-sitter CLI
- `lua/core/vscode/`: when `vim.g.vscode` is set (Cursor/VS Code), only the allow listed editing plugins load
- `lua/core/style/`: reads the my-style guide so `<leader>pc` and `<leader>pp` draft with the same rules
- Pure logic goes in each module's `actions/init.lua` so it can be unit tested
- Tests: `./scripts/test.sh` (plenary busted, specs in `tests/`)
- CI (`.github/workflows/ci.yml`) runs the specs on Linux and macOS and `stylua --check lua tests init.lua`, so run `stylua lua tests init.lua` after editing Lua
- `.luarc.json` gives lua_ls outside nvim the same globals as `lua/plugins/lsp.lua`, keep both lists in sync
- README GIFs: `./scripts/record.sh [tape...]` records `docs/tapes/*.tape` with vhs into `images/demo/`, inside a sandbox of made up repos (`docs/tapes/demo.lua` pins the franchise and silences sound). Never record with real repos, the repo is public

---

## Style: one source

The only style guide is `.claude/commands/my-style.md`. Everything reads it:

- a SessionStart hook in `.claude/settings.json` loads it into every new conversation
- `/my-style` runs it on demand in this repo (and `~/.claude/commands/my-style.md` is a symlink to it)
- `<leader>pc` and `<leader>pp` send it to Claude when drafting commits and PRs

Follow it with no exceptions. If it did not load, invoke `/my-style` before anything else.
Never copy its rules into other files, prompts or this one. Change the guide instead.

Developers using this config can swap that file for their own guide and every piece above follows it.
