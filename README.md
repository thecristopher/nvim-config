# Eldentree

A Neovim config forged in the Lands Between, or in Raccoon City depending on the day. Catppuccin Mocha, recolored for whichever region or location you wake up in, with banners, runes and a Site of Grace that lets you rest when you step away.

Runs on macOS, Linux and Windows, and also inside Cursor and VS Code.

![Malenia](images/portraits/malenia.jpg)

## Requirements

- Neovim 0.11 or newer (0.12 recommended)
- git
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal
- The `tree-sitter` CLI, which builds the parsers
- Optional: `ripgrep` and `fd` for faster pickers, and `gh` for PR drafts

## Install

Back up any existing config first, then clone this repo where Neovim looks for its config.

```sh
# macOS and Linux
git clone https://github.com/thecristopher/nvim-config ~/.config/nvim
```

```powershell
# Windows
git clone https://github.com/thecristopher/nvim-config $env:LOCALAPPDATA\nvim
```

Launch `nvim` and lazy.nvim bootstraps itself and installs every plugin on the first run. Mason installs the language servers.

## Your own style guide

Claude follows one style guide in this config: `.claude/commands/my-style.md`. It is loaded into every Claude Code session opened here, it backs `/my-style`, and `<leader>pc` / `<leader>pp` send it to Claude when drafting commits and PRs.

It is Cristopher's guide, so replace that file with yours and everything follows it. To use it outside this repo too, link it as a global command:

```sh
ln -sf ~/.config/nvim/.claude/commands/my-style.md ~/.claude/commands/my-style.md
```

## What is inside

| Module        | What it does                                                                                                      |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| `core/franchise` | Picks the world for the day, rotating between Elden Ring and Resident Evil. Its lore folders hold the palettes, bosses, weather, banners and words. `:Franchise` switches until midnight, `vim.g.eldentree_franchise` pins one. Each lore also picks its `mechanics`, so Resident Evil travels through doors, gets stalked instead of dueling, shows a health ECG, rests at a typewriter and ranks every run |
| `core/themes` | Region palettes from the franchise in use (eleven in Elden Ring, seven in Resident Evil). Each repo keeps its own region (the one you picked there, or one derived from its name), outside a repo each launch rolls a new one. Pin one with `vim.g.eldentree_region` |
| `core/phantom` | `<leader>gw` shows who last wrote the line as a phantom: blue for others, gold for your past self |
| `core/zones`  | The first time you walk into a folder each session, it is announced like a new area of the Lands Between |
| `core/snapshot` | `<leader>cp` / `:Snapshot` saves the buffer or selection as a framed PNG in the region's colors and copies it |
| `core/hub`    | Living dashboard with shimmering gold headers, rising embers and a typed player message                           |
| `core/banner` | Elden Ring style banners fired by commits, PRs, test runs, new projects and region changes                        |
| `core/boss`   | When 3 or more errors linger, the region's boss arrives with a health bar. Each fix lands a hit, the last one fells it. In Resident Evil the boss is a stalker that walks closer while errors stay and backs off with every fix |
| `core/door`   | Resident Evil's travel: the screen goes dark and a door creaks open, where Elden Ring rolls the fog wall |
| `core/ecg`    | Resident Evil's statusline ECG: Fine, Caution or Danger from the buffer's diagnostics |
| `core/map`    | `:Map` / `<leader>fM` shows every folder as a room, red while errors or TODOs are left in it, blue once cleared |
| `core/results` | Ranks each run from S to D by fixes and saves, and the Resident Evil hub shows the last one |
| `core/runes`  | Statusline rune tally (pesetas in Resident Evil, where the Merchant greets every 10,000). Saves and banners pay out, dying leaves a bloodstain |
| `core/rest`   | After 5 idle minutes in normal mode the editor rests at a Site of Grace, or at a Safe Room typewriter in Resident Evil. Any key wakes it |
| `core/repos`  | Background repo scanner, the Sites of Grace project picker and automatic project root                             |
| `core/dive`   | F12 family: go to definition, Glance peek, references and F2 rename                                               |
| `core/trial`  | Runs the project's tests in the background and announces the verdict                                              |
| `core/git`    | Quick branch, pull, push, sync, stash and undo shortcuts, plus the related change staging `<leader>pc` uses       |
| `core/motion` | Shared animation engine. Ambient loops pause while Neovim is unfocused                                            |
| `core/vscode` | Inside Cursor or VS Code, only the allow listed editing plugins load                                              |

Plugin specs live in `lua/plugins/`, one file per concern.

Traveling to a Site of Grace keeps the session of the repo you leave and restores the one you arrive at. Files with unsaved changes are never closed. Turn it off with `vim.g.eldentree_project_sessions = false`, and per project regions with `vim.g.eldentree_region_per_project = false`.

Portraits in `images/portraits/` are 276x336 crops of the originals in `images/`, with contrast, color and sharpness lifted so they survive half block rendering. A region whose portrait is missing simply shows the hub without art.

### Portrait credits

The Resident Evil portraits are fan art and photography by their own authors, used here with love and full credit to them.

| Portrait | Region            | Author                       |
| -------- | ----------------- | ---------------------------- |
| Claire   | Raccoon City      | Artist pending               |
| Leon     | RPD               | Artist pending               |
| Jill     | Spencer Mansion   | Like Detectives              |
| Wesker   | Umbrella Lab      | Artist pending               |
| Ashley   | Salazar Castle    | Artist pending               |
| Ada      | Saddler's Island  | Artist pending               |
| Chris    | The Village       | Artist pending               |

## Keys

Leader is `<Space>`, local leader is `\`.

| Key          | Action                          |
| ------------ | ------------------------------- |
| `<leader>fp` | Find a project (Sites of Grace) |
| `<leader>ut` | Choose a region theme           |
| `<leader>uT` | Next region theme               |
| `<leader>uf` | Choose today's franchise        |
| `<leader>fM` | Project map                     |
| `<leader>um` | Toggle animations               |
| `<leader>cT` | Run tests (Trial)               |
| `<leader>uz` | Zen mode                        |
| `<leader>uB` | Toggle boss fights              |
| `<leader>gw` | Who wrote this line (phantom)   |
| `<leader>cp` | Snapshot the buffer or selection as a PNG |
| `K`          | Hover docs, dressed as an item description |
| `<leader>fR` | Find and replace in the project (grug-far), works on a selection too |
| `<leader>fF` | Find and replace in this file   |
| `<C-n>`      | Add a cursor on the next match (multicursor) |
| `<A-Up>` / `<A-Down>` | Add a cursor above or below |
| `<leader>Ma` | Add a cursor on every match     |
| `<leader>pc` | Stage related changes and draft the commit with Claude |
| `<leader>gN` | New branch (pick a prefix, type a name) |
| `<leader>gj` | Pull                            |
| `<leader>gk` | Push (sets upstream the first time, never forces) |
| `<leader>gm` | Merge the base branch into this one |
| `<leader>gM` | Switch to the base branch and pull |
| `<leader>ga` | Stage related changes (skips .env, logs, swap files) |
| `<leader>gz` | Stash everything, untracked included |
| `<leader>gZ` | Pop the latest stash            |
| `<leader>gu` | Undo the last unpushed commit, keep its changes staged |
| `<leader>gn` | Neogit status                   |
| `<leader>gc` | Neogit commit                   |
| `<leader>gp` / `<leader>gP` | Neogit pull / push popups |
| `<leader>gv` | Neogit log                      |
| `<leader>gr` | Neogit branch popup             |
| `<leader>gC` | Search commits (Telescope)      |

Inside a toggleterm terminal, the bar at the top lists the quick git keys. Press `<Esc>` and then `<Space>g` to use them.

While several cursors are active, `n` / `N` add the next or previous match, `q` / `Q` skip one, `<Left>` / `<Right>` switch the main cursor and `<Esc>` clears them.

| Key          | Action                          |
| ------------ | ------------------------------- |
| `<leader>Tt` | Run the nearest test (neotest)  |
| `<leader>Tf` | Run every test in this file     |
| `<leader>Td` | Debug the nearest test          |
| `<leader>Ts` | Test summary                    |
| `<leader>To` | Output of the test under the cursor |
| `<leader>Tw` | Rerun this file on every save   |
| `]T` / `[T`  | Next or previous failed test    |
| `F5`         | Start or continue debugging     |
| `Shift F5`   | Stop debugging                  |
| `F9`         | Toggle breakpoint               |
| `F10` / `F11` / `Shift F11` | Step over, into, out |
| `<leader>DB` | Conditional breakpoint          |
| `<leader>Dp` | Log point                       |
| `<leader>Dv` | Toggle the debug view           |
| `<leader>Dw` | Watch the expression under the cursor |

On macOS, F11 shows the desktop unless "Use F1, F2, etc. keys as standard function keys" is on. `<leader>Di` steps into without it.

| Key          | Action                          |
| ------------ | ------------------------------- |
| `F12`        | Go to definition                |
| `F2`         | Rename symbol                   |

## Commands

| Command                                        | Action                                  |
| ---------------------------------------------- | --------------------------------------- |
| `:Region`                                      | Switch region theme                     |
| `:Map`                                         | Open the project map                    |
| `:Franchise [elden_ring\|resident_evil]`       | Switch today's franchise                |
| `:Banner felled\|great\|died\|grace\|cleansed` | Fire a banner                           |
| `:Trial`                                       | Run the project's tests                 |
| `:Rest`                                        | Rest at a Site of Grace now             |
| `:Motion`                                      | Toggle animations                       |
| `:Boss`                                        | Toggle boss fights                      |
| `:Phantom`                                     | Who wrote the line under the cursor     |
| `:Snapshot`                                    | Save a framed PNG of the buffer or range |
| `:GrugFar`                                     | Find and replace across the project     |
| `:OpenFolder`                                  | Open the file tree at a folder you pick |
| `:Repos` / `:ReposRescan`                      | Browse or rescan known repositories     |

## Tests

Specs live in `tests/` and run with plenary busted in a headless Neovim.

```sh
./scripts/test.sh
```
