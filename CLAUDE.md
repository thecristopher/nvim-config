# Eldentree — nvim-config

This is Cristopher's personal Neovim configuration. The my-style guide is always active for
every session in this repo (see the style section below).

---

## Project context

- Plugin manager: lazy.nvim (stable branch)
- All plugin configs live in `lua/plugins/` (one file per concern), returning lazy.nvim spec tables
- Core config (options, keymaps, autocmds) lives in `lua/core/`
- Theme: catppuccin mocha recolored per Elden Ring region. Palettes and color math live in `lua/core/themes/actions/`, switch with `<leader>ut` or `:Region`. Eleven regions. A repo wears its own region (picked there and saved in state, or derived from the folder name with `project_region`), and `DirChanged` crossfades into it. Outside a repo each launch rolls a random region (never the previous one). `vim.g.eldentree_region` pins one everywhere. Each region has a `character` and a `portrait` in `images/portraits/` (pre-cropped, contrast lifted) that the hub shows when the file exists. Adding a region means a palette, a `WEATHER` entry in the hub actions and a boss in `BOSSES`. Never hard code hex colors in plugin specs, read `require("core.themes").palette()` so they follow the region
- Leader: `<Space>` | Local leader: `\`
- `~/.config/nvim` is a symlink to this repo, so every saved `.lua` file is live immediately
- LSP uses native `vim.lsp.config` plus mason-lspconfig v2 (`automatic_enable`), servers live in `lua/plugins/lsp.lua`
- `lua/core/dive/`: F12 family (definition, Glance peek, references, F2 rename), bound on LspAttach. `K` hover floats are dressed as item descriptions (`ITEM_CATEGORIES` in its actions)
- `lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root, dashboard items. A repo counts only when its `.git` leads to a readable `HEAD`. Traveling saves the old project's session (persistence) and restores the new one, unsaved buffers stay open
- `lua/core/motion/`: shared animation engine (tween, ambient loop, highlight fades). `<leader>um` or `:Motion` stills everything, ambient loops pause while unfocused
- `lua/core/banner/`: Elden Ring style banners (`:Banner felled|great|died|grace|cleansed`) fired by commits, PRs, `:Trial`, new Sites of Grace, region changes and long fights with errors
- `lua/core/hub/`: living dashboard, shimmering gold headers, a typed player message and per region weather (`WEATHER` in its actions: embers, rot petals, glintstone, blood, snow)
- `lua/core/fog/`: fog wall that rolls over the editor when you travel to a Site of Grace (`:Fog`, `<leader>uF` or `vim.g.eldentree_fog = false`)
- `lua/core/messages/`: Elden Ring style messages left on lines of code, stored per repo in state (`<leader>mw` write, `md` erase, `ml` list, `:Inscribe`, `:Inscriptions`)
- `lua/core/folds/`: the closed fold text nvim-ufo shows (first line plus a hidden line tally)
- `lua/core/review/`: `:Review [number|url]` / `<leader>pr` has Claude (headless, subscription) analyze a PR's diff into a float, `d` opens the diff per file
- `lua/core/git/`: quick git keys under `<leader>g` (`N` new branch, `j` pull, `k` push, `m`/`M` base branch, `z`/`Z` stash, `u` undo commit) and the related change staging `<leader>pc` runs first. `QUICK_KEYS` in its actions is the one list behind the keymaps and the toggleterm winbar hint. Keep `<leader>g` maps at two keys so none waits on a timeout
- `lua/core/trial/`: `:Trial` / `<leader>cT` runs the project's tests in the background and announces the verdict
- `lua/core/boss/`: boss health bar for buffers where 3+ errors linger 8 seconds, the region's boss (`BOSSES` in its actions) takes a hit per fix and the last one fires `ENEMY FELLED` (`:Boss`, `<leader>uB` or `vim.g.eldentree_boss = false`)
- `lua/core/phantom/`: `<leader>gw` / `:Phantom` blames the buffer through stdin and shows the last author as a phantom float
- `lua/core/zones/`: first visit to a folder each session fires the quiet `zone` banner, `LANDMARKS` in its actions names well known folders
- `lua/core/snapshot/`: `<leader>cp` / `:Snapshot` builds an SVG card from the on screen highlights and renders it with `rsvg-convert` to `~/Pictures/Eldentree`
- `lua/core/utils/`: project wide helpers (the stable `hash`)
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

---

## Style: one source

The only style guide is `.claude/commands/my-style.md`. Everything reads it:

- a SessionStart hook in `.claude/settings.json` loads it into every new conversation
- `/my-style` runs it on demand in this repo (and `~/.claude/commands/my-style.md` is a symlink to it)
- `<leader>pc` and `<leader>pp` send it to Claude when drafting commits and PRs

Follow it with no exceptions. If it did not load, invoke `/my-style` before anything else.
Never copy its rules into other files, prompts or this one. Change the guide instead.

Developers using this config can swap that file for their own guide and every piece above follows it.
