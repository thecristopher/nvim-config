# Eldentree, nvim-config

This is Cristopher's personal Neovim configuration. The my-style guide is always active for
every session in this repo (see the style section below).

---

## Project context

- Plugin manager: lazy.nvim (stable branch)
- All plugin configs live in `lua/plugins/` (one file per concern), returning lazy.nvim spec tables
- Core config (options, keymaps, autocmds) lives in `lua/core/`
- The detail of the bigger modules lives in `docs/modules/<name>.md`: read the one for the module you touch and keep it current when the module changes
- Franchise: `lua/core/franchise/` picks the world the config speaks (Elden Ring, Resident Evil, Elizabeth), one per day, `:Franchise` or `<leader>jf` to switch. Never hard code franchise text in a module, read `current()`, `line()` and `mechanic()` ([details](docs/modules/franchise.md))
- `lua/core/skin/`: borders, glyphs, icons and titles per franchise. Use `border()`, `icon(level)` and `title(text)` from `core.skin`, never hard code them, and every glyph must exist in the Nerd Font ([details](docs/modules/skin.md))
- `lua/core/hud/`: the start screen inventory HUD (`:Hud`, `<leader>jh`), one pure view per franchise sized from the window, anything slow fetched through `core/hud/background.lua` ([details](docs/modules/hud.md))
- `lua/core/tree/`: the explorer dressed by the franchise: guides, map rooms left, review threads and ground messages per file ([details](docs/modules/tree.md))
- `lua/core/drift/`: the region's weather drifts through the empty rows under the last line of prose (markdown, text, gitcommit) and empty buffers, never in code, in one borderless float that takes no focus and lets clicks through, only in normal mode, sleeping with core/motion. `vim.g.eldentree_drift = false` turns it off
- `lua/core/pixel/`: the region's 8 bit sprite popping at the top right on saves and banners, every region has one in its lore's `pixels.lua` (`:Pixel` previews) ([details](docs/modules/pixel.md))
- `lua/core/title/`: the franchise title screen in block letters (shimmer, drip or a marquee of chasing bulbs), once a day per franchise and on every switch, `:Title`, `vim.g.eldentree_title = false`. The shimmer style writes the name in thin strokes (`THIN`) under the arc of the ring, and the drip style flickers like a failing light
- `lua/core/terminal/`: dresses the terminal itself: OSC 11 background, iTerm profiles, Kitty and Ghostty opacity (`:Opacity`, `<leader>uo`) ([details](docs/modules/terminal.md))
- `lua/core/sound/`: plays `sounds/<franchise>/<event>.*` on the HUD and moment channels through a resident Swift player, `scripts/sounds.py` builds and imports the files (`:Sound <event>`) ([details](docs/modules/sound.md))
- `lua/core/door/`: the dark and the door that opens when the franchise travels by door. `core/fog` hands any travel that is not fog to the module named after it (`core.door`, `core.curtain`), passing the project or branch you travel to. The door is sized to the screen, its planked panels slide into the frame, and `words.loading` sits small at the bottom
- `lua/core/curtain/`: velvet drapes in the region's accent close from both sides, announce the stage you travel to and part on it, for franchises whose `travel` is `curtain`
- `lua/core/signpost/`: the sign every travel shows (fog, door or curtain), with its timing and `{ on_covered, on_done }` in its actions ([details](docs/modules/signpost.md))
- `lua/core/heartbeat/`: the statusline heart for franchises whose `status` is `heartbeat`, beating with a lub and a dub, calm on a clean buffer and racing (broken at Danger) as the ECG's conditions get worse. It lives only in lualine, like the ECG
- `lua/core/ecg/`: the health ECG statusline piece (Fine, Caution, Danger) for franchises whose `status` is `ecg`. It lives only in lualine: the HUD and Claude's statusline leave it out, and the same goes for the grace glyph and the runes
- `lua/core/map/`: `:Map` / `<leader>jm`: each top folder is a wing and each room a box, red while errors or TODOs are left, blue when cleared, with the skin's `tree.left`/`cleared` glyph and the current room marked (▲), `<Tab>` steps between rooms and `<CR>` opens the files picker there. `layout` and `room_at` in its actions are pure, so a HUD tab can draw the same map. Room names are unique per project (`zones.zone_names`)
- `lua/core/results/`: counts saves and fixes per run, ranks it S to D on exit (`eldentree_results.json` in state), the HUD shows it in STATUS in the lore's `words` (`last_run`, `rank`, `saves`, `fixes`, required when `ranking` is on)
- Theme: catppuccin mocha recolored per region (`lua/core/themes/`, `:Region`, `<leader>jr`), one region per day. Never hard code hex colors, read `require("core.themes").palette()` ([details](docs/modules/themes.md))
- Leader: `<Space>` | Local leader: `\`
- `~/.config/nvim` is a symlink to this repo, so every saved `.lua` file is live immediately
- LSP uses native `vim.lsp.config` plus mason-lspconfig v2 (`automatic_enable`), servers live in `lua/plugins/lsp.lua`. Mason and the servers are wired after the first frame (`after_first_frame`), so a file opened from the command line draws first
- Startup: `vim.loader.enable()` runs first in `init.lua`. Only lualine and bufferline load on VeryLazy, everything else nobody needs in the first frame loads one plugin per tick through `lua/core/later/` (`PLUGINS` in its actions), and yanky waits for the first yank (every clipboard read costs ~11 ms). The HUD validates repos with a `stat` and spawns its git processes after it is on screen. `./scripts/startup.sh [runs] [file]` measures the first frame and the moment everything is loaded, `tests/core/startup_spec.lua` guards these rules
- `lua/eldentree/tools.lua`: every program Eldentree calls, what it unlocks and where it comes from, read by `:checkhealth eldentree`. `Brewfile` installs the Homebrew ones (a spec fails when one is missing there) and `./scripts/install.sh` gets a new machine ready: the tools, the `~/.config/nvim` link and every plugin at its locked version
- `lua/plugins/data.lua`: dadbod for databases (`<leader>cd`, tables and columns completed in SQL buffers) and treesj (`<leader>cj` splits or joins a block)
- `lua/core/dive/`: F12 family (definition, Glance peek, references, F2 rename), bound on LspAttach. `K` hover floats are dressed as item descriptions (`item_categories` in the franchise lore). Hover titles go through `core.skin.title`. dropbar shows the file plus the 2 innermost scopes (`innermost` in `core/dive/actions`)
- `lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root and a session per project and per branch ([details](docs/modules/repos.md))
- `lua/core/find/`: the pickers that need more than one Snacks call (recent files per repo with `<C-a>` to flip, branches with sessions). Every picker is Snacks, Telescope is gone, so never add one back
- `lua/core/chrome/`: the editor's chrome per franchise: mode badge, fading line numbers, statusline tiers (`STATUSLINE_MIN`), notifications, pickers and the command line ([details](docs/modules/chrome.md))
- `lua/core/leader/`: every leader key in `BINDINGS` and every group in `GROUPS`. Never `vim.keymap.set` a global leader key inside a module, add a row there ([details](docs/modules/leader.md))
- `lua/core/palette/`: `<leader><leader>` or `?` on the HUD, every Eldentree command with its key, in aligned columns and a window as wide as they need. `ENTRIES` in its actions is the list, add a row there when a module gets a command. A spec fails when a command defined in lua/core has no palette row and no reason in `UNLISTED`
- Floats and menus are opaque and wear one frame (`NormalFloat` and `FloatBorder` on `mantle`), only the effects that blend on purpose set their own `winblend` ([details](docs/modules/floats.md))
- `lua/core/motion/`: the one animation clock (tweens, ambient loops, fades), `<leader>um` stills everything. Repaint the statusline only through `core.utils.refresh_statusline()` ([details](docs/modules/motion.md))
- `lua/core/spell/`: the repo's own spell word list in `spell/en.utf-8.add` (technical words, the franchises' names and the authors of the voice sheets), set as `spellfile` so `zg` adds to the same versioned file. The compiled `.spl` is git ignored and rebuilt on startup whenever the list is newer (`needs_build`). Add a word with `zg`, never by hand to a `.spl`
- Trouble groups diagnostics by file, its path from the project root, instead of under the absolute directory
- `lua/core/chrome/glint.lua`: every save of a real file sends a glint over the statusline (badge first, then branch, then the middle, mirrored on the right) on core/motion's clock, timing and colors in `chrome/actions/glint.lua`, always ending on the theme's exact colors
- `lua/core/chrome/yank.lua`: yanked text glows in the region's accent (`EldenYank`) and fades out on core/motion's clock, a short plain flash while motion is stilled, and every yanky put glows the same way (`prime_put` on `YankyPut`)
- Clipboard: `clipboard` is the system's, so only a yank or a `d` cut lands in it. `x`, `X`, `c` and `C` throw away what they remove, and `p` over a selection is yanky's put before, which keeps the register: pasting over two selections pastes the same thing twice
- `lua/core/whitespace/`: trims trailing whitespace on save only on the lines that changed since the file was last written (a diff against the file on disk), so legacy files never drag untouched lines into a PR
- `lua/core/banner/`: Elden Ring style banners (`:Banner felled|great|died|grace|cleansed`) for commits, PRs, `:Trial`, travels and long fights, styled per lore ([details](docs/modules/banner.md))
- `lua/core/hub/`: the HUD's ambient life: shimmering gold on ornamented rows, a typed player message and per region weather drifting through rows without frames (`weather` in the franchise lore: embers, rot petals, glintstone, rain, snow). The weather keeps 2 cells clear around text, and the hub message is picked again when the world changes
- `lua/core/fog/`: fog wall that rolls over the editor when you travel to a Site of Grace (`:Fog`, `<leader>uf` or `vim.g.eldentree_fog = false`)
- `lua/core/messages/`: Elden Ring style messages left on lines of code, stored per repo in state (`<leader>mw` write, `md` erase, `ml` list, `:Inscribe`, `:Inscriptions`). A save with no messages to move writes nothing
- `lua/core/folds/`: the closed fold text nvim-ufo shows (first line plus a hidden line tally)
- `lua/core/desk/`: the manager desk (`:Desk`, `<leader>jd`), its listener and work agents, and the inbox nvim watches for implement and review requests ([details](docs/modules/desk.md))
- `lua/core/review/`: `:Review [number|url]` / `<leader>pr` has Claude (headless, subscription) analyze a PR's diff into a float, `d` opens the diff per file
- `lua/core/git/`: quick git keys under `<leader>g` (`QUICK_KEYS`), every call runs in the buffer's repo, `<leader>pc` commits in the background with a Claude draft ([details](docs/modules/git.md))
- `lua/core/btb/` and `lua/plugins/btb.lua`: back-to-basics drills under `<leader>k`, coached by the character of the day, hints sold by the franchise's merchant ([details](docs/modules/btb.md))
- `lua/core/progress/`: the one way to report a wait: `require("core.progress").start({ id, title, message })`, then `task:update`, `task:done` or `task:fail` ([details](docs/modules/progress.md))
- `lua/core/trial/`: `:Trial` / `<leader>TT` runs the project's tests in the background and announces the verdict
- `lua/core/boss/`: boss health bar for buffers where 3+ errors linger 8 seconds, the region's boss (`bosses` in the franchise lore) takes a hit per fix and the last one fires the `felled` banner (`:Boss`, `<leader>ub` or `vim.g.eldentree_boss = false`)
- `lua/core/boss/` plays the franchise's `boss` mechanic: `duel` (the health bar), `stalker` (a hall it walks down) or `scene` (the villain steals the scene: every error is a broken heart, each fix mends one that glows as it heals, `hearts` and `heart_row` in its actions)
- `lua/core/boss/` also takes staged fights: `require("core.boss").stage(buf, { name, count, peak?, banner? })` lets another module count the hits instead of the diagnostics (`nil` ends it quietly, `banner = false` fells it without one). `core/conflicts` stages merge conflicts on it (`conflict` in the lore), and `core/btb` stages the onsite levels of back-to-basics from `User BtbFight`
- `lua/core/ci/`: the branch's CI run in the statusline from `gh run list`, `:CI` / `<leader>gi` opens the run or its failing log ([details](docs/modules/ci.md))
- `lua/core/threads/`: the PR's open review threads as virtual text, `<leader>mc` lists, `<leader>mo` opens, `<leader>mr` resolves, `]r` and `[r` jump ([details](docs/modules/threads.md))
- `lua/core/voice/`: the region's character speaks on moments (`say(moment, vars)`), written lines in each lore's `voices.lua`, clips in `sounds/<franchise>/voices/<region>/` ([details](docs/modules/voice.md))
- `lua/core/bestiary/`: diagnostics cleared by an edit (the changedtick moved, so closing a buffer fells nothing) count per code and repo in `eldentree_bestiary.json` in state, each code named from `bestiary.enemies` by `core.utils` hash. `:Bestiary` / `<leader>jb`
- `lua/core/expedition/`: `:Expedition [minutes|stop]` / `<leader>je` silences sound, motion and notifications below WARN, counts down in lualine and ranks the block with `core/results` math when it ends (`expedition` in the lore). While a block runs `eldentree_expedition` in state holds its end in epoch seconds, so Claude Code's hooks stay quiet too
- `lua/core/chronicle/`: every finished run adds to its day in `eldentree_chronicle.json` in state, `:Chronicle` / `<leader>jc` draws the last 20 weeks lit by rank and by your commits in the repo (`chronicle` in the lore). Days are drawn with a shade per level (`·░▒▓█`), keyed in the footer, so ranks read without color
- `lua/core/phantom/`: `<leader>gw` / `:Phantom` blames the buffer through stdin and shows the last author as a phantom float. Its title goes through `core.skin.title`
- `lua/core/zones/`: the first visit to a folder each day (per repo, `eldentree_zones.json` in state) fires the quiet `zone` banner, `landmarks` in the franchise lore names well known folders. Other folders take a place from the region's own `places` first, then the lore's shared ones (`places_of`), so Elizabeth's roles never borrow each other's worlds
- `lua/core/snapshot/`: `<leader>cp` / `:Snapshot` builds an SVG card from the on screen highlights and renders it with `rsvg-convert` to `~/Pictures/Eldentree`
- `lua/core/utils/`: project wide helpers (the stable `hash`, `refresh_statusline`). Write state files with `require("core.utils").write_state(path, lines)`, never a bare `writefile`: it skips the fsync that costs ~4 ms per write on macOS, and some state is written on every save
- `lua/core/links/`: Ctrl+click opens a link a terminal printed, `<leader>to` opens the last one ([details](docs/modules/links.md))
- `lua/core/trace/`: `:InsertTrace` logs every exit from insert mode with the keys right before it (typed, mapped or sent by a plugin) to `eldentree_insert_trace.log` in state, off until toggled
- `lua/core/music/`: what Cider or Apple Music plays, in the statusline and a now playing panel with the cover, an equalizer and synced lyrics (`<leader>o`, `:Music`) ([details](docs/modules/music.md))
- `lua/core/claude_ui/` and `claude/`: Claude Code dressed by the franchise (theme, spinner verbs, statusline, sound hooks), wired by `claude/install.lua` ([details](docs/modules/claude_ui.md))
- `lua/core/claude_context/`: `<leader>al` sends the function under the cursor (tree-sitter, `FUNCTION_TYPES`) as an at mention, `<leader>ae` types a one line ask to fix the buffer's diagnostics into Claude's prompt without submitting it (a newline would submit). `<leader>ar` / `<leader>aC` open Claude with `--resume` / `--continue`
- Completion: blink for the LSP, paths, snippets and dadbod in SQL buffers, Copilot as ghost text and next edit suggestions, quieter inside back-to-basics exercises ([details](docs/modules/completion.md))
- `lua/core/claude_panel/`: the claudecode side panel, `<leader>aF` / `:ClaudeFullscreen` lets it take the whole editor ([details](docs/modules/claude_panel.md))
- `lua/core/resize/`: border handles to drag with the mouse, `<leader>sw` moves borders with hjkl, `<leader>se` resets the layout ([details](docs/modules/resize.md))
- `lua/core/runes/`: statusline rune tally (saves and banners pay out, YOU DIED leaves a bloodstain) plus the breathing grace glyph
- `lua/core/rest/`: after 5 idle minutes in normal mode the editor rests at a Site of Grace (embers), a typewriter or under the afternoon sun through the blinds (`golden_hour`, `sun_spans` in its actions) (`:Rest`, `vim.g.eldentree_rest_after`), any key wakes it and is swallowed. Embers show the grace menu (`words.grace_menu`), golden hour hangs an intermission card (`words.intermission`, `words.back_soon`)
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
- README GIFs: `./scripts/record.sh [tape...]` records `docs/tapes/*.tape` with vhs into `images/demo/`, inside a sandbox of made up repos (`docs/tapes/demo.lua` pins the franchise and silences sound), and a back-to-basics world built by `scripts/demo-sandbox.mjs` in the clone that `btb` and `btb_re` record with). Never record with real repos, the repo is public

---

## Style: one source

The only style guide is `.claude/commands/my-style.md`. Everything reads it:

- a SessionStart hook in `.claude/settings.json` loads it into every new conversation
- `/my-style` runs it on demand in this repo (and `~/.claude/commands/my-style.md` is a symlink to it)
- `<leader>pc` and `<leader>pp` send it to Claude when drafting commits and PRs

Follow it with no exceptions. If it did not load, invoke `/my-style` before anything else.
Never copy its rules into other files, prompts or this one. Change the guide instead.

Developers using this config can swap that file for their own guide and every piece above follows it.
