# Eldentree

A Neovim config forged in the Lands Between. Catppuccin Mocha, recolored for whichever Elden Ring region you wake up in, with banners, runes and a Site of Grace that lets you rest when you step away.

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
| `core/themes` | Region palettes. Each launch rolls a random region, never the previous one. Pin one with `vim.g.eldentree_region` |
| `core/hub`    | Living dashboard with shimmering gold headers, rising embers and a typed player message                           |
| `core/banner` | Elden Ring style banners fired by commits, PRs, test runs, new projects and region changes                        |
| `core/runes`  | Statusline rune tally. Saves and banners pay out, YOU DIED leaves a bloodstain                                    |
| `core/rest`   | After 5 idle minutes in normal mode the editor rests at a Site of Grace. Any key wakes it                         |
| `core/repos`  | Background repo scanner, the Sites of Grace project picker and automatic project root                             |
| `core/dive`   | F12 family: go to definition, Glance peek, references and F2 rename                                               |
| `core/trial`  | Runs the project's tests in the background and announces the verdict                                              |
| `core/git`    | Quick branch, pull, push, sync, stash and undo shortcuts, plus the related change staging `<leader>pc` uses       |
| `core/motion` | Shared animation engine. Ambient loops pause while Neovim is unfocused                                            |
| `core/vscode` | Inside Cursor or VS Code, only the allow listed editing plugins load                                              |

Plugin specs live in `lua/plugins/`, one file per concern.

## Keys

Leader is `<Space>`, local leader is `\`.

| Key          | Action                          |
| ------------ | ------------------------------- |
| `<leader>fp` | Find a project (Sites of Grace) |
| `<leader>ut` | Choose a region theme           |
| `<leader>uT` | Next region theme               |
| `<leader>um` | Toggle animations               |
| `<leader>cT` | Run tests (Trial)               |
| `<leader>uz` | Zen mode                        |
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
| `F12`        | Go to definition                |
| `F2`         | Rename symbol                   |

## Commands

| Command                                        | Action                                  |
| ---------------------------------------------- | --------------------------------------- |
| `:Region`                                      | Switch region theme                     |
| `:Banner felled\|great\|died\|grace\|cleansed` | Fire a banner                           |
| `:Trial`                                       | Run the project's tests                 |
| `:Rest`                                        | Rest at a Site of Grace now             |
| `:Motion`                                      | Toggle animations                       |
| `:OpenFolder`                                  | Open the file tree at a folder you pick |
| `:Repos` / `:ReposRescan`                      | Browse or rescan known repositories     |

## Tests

Specs live in `tests/` and run with plenary busted in a headless Neovim.

```sh
./scripts/test.sh
```
