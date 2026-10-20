# Eldentree — nvim-config

This is Cristopher's personal Neovim configuration. The my-style guide is always active for
every session in this repo (see the style section below).

---

## Project context

- Plugin manager: lazy.nvim (stable branch)
- All plugin configs live in `lua/plugins/` (one file per concern), returning lazy.nvim spec tables
- Core config (options, keymaps, autocmds) lives in `lua/core/`
- Theme: catppuccin mocha recolored per Elden Ring region. Palettes and color math live in `lua/core/themes/actions/`, switch with `<leader>ut` or `:Region`. Each launch rolls a random region (never the previous one) unless `vim.g.eldentree_region` pins it. Each region has a `character` and a `portrait` in `images/portraits/` (pre-cropped, contrast lifted) that the hub shows. Never hard code hex colors in plugin specs, read `require("core.themes").palette()` so they follow the region
- Leader: `<Space>` | Local leader: `\`
- `~/.config/nvim` is a symlink to this repo, so every saved `.lua` file is live immediately
- LSP uses native `vim.lsp.config` plus mason-lspconfig v2 (`automatic_enable`), servers live in `lua/plugins/lsp.lua`
- `lua/core/dive/`: F12 family (definition, Glance peek, references, F2 rename), bound on LspAttach
- `lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root, dashboard items
- `lua/core/motion/`: shared animation engine (tween, ambient loop, highlight fades). `<leader>um` or `:Motion` stills everything, ambient loops pause while unfocused
- `lua/core/banner/`: Elden Ring style banners (`:Banner felled|great|died|grace|cleansed`) fired by commits, PRs, `:Trial`, new Sites of Grace, region changes and long fights with errors
- `lua/core/hub/`: living dashboard, shimmering gold headers, rising embers and a typed player message
- `lua/core/review/`: `:Review [number|url]` / `<leader>pr` has Claude (headless, subscription) analyze a PR's diff into a float, `d` opens the diff per file
- `lua/core/trial/`: `:Trial` / `<leader>cT` runs the project's tests in the background and announces the verdict
- `lua/core/runes/`: statusline rune tally (saves and banners pay out, YOU DIED leaves a bloodstain) plus the breathing grace glyph
- `lua/core/rest/`: after 5 idle minutes in normal mode the editor rests at a Site of Grace (`:Rest`, `vim.g.eldentree_rest_after`), any key wakes it and is swallowed
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
