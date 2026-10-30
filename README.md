# Eldentree

[![CI](https://github.com/thecristopher/nvim-config/actions/workflows/ci.yml/badge.svg)](https://github.com/thecristopher/nvim-config/actions/workflows/ci.yml)

A Neovim config shaped like a tree whose branches are worlds. Every day it wakes up in a different one: the Lands Between, Raccoon City, or any franchise you add as a lore folder. The colors, the words, the sounds, the start screen, the way you travel and the way you rest all change with it.

Under the costume it is a full daily editor: native LSP, Snacks pickers, git and PRs without leaving nvim, CI and review threads in the buffer, tests and debugging, Claude Code dressed to match, your music with its lyrics, and coached drills from [back-to-basics](https://github.com/thecristopher/back-to-basics).

Runs on macOS, Linux and Windows, and also inside Cursor and VS Code.

![Malenia](images/portraits/malenia.jpg)

## A look around

The title screen, once a day per franchise and on every switch.

![Elden Ring title screen](images/demo/title.gif)

The start screen is an inventory. Elden Ring opens the Roundtable Hold with its tabs, the item grid and your Sites of Grace.

![Elden Ring HUD](images/demo/hud.gif)

On Resident Evil days it is the STATUS screen, with Claire, her DATA and the COMMAND menu.

![Resident Evil inventory](images/demo/hud_re.gif)

Banners land on commits, PRs, test runs and felled bosses. When you die, the code crumbles into rain behind the banner and comes back as it fades.

![Banners](images/demo/banner.gif)

Whatever Apple Music or Cider is playing sits in the statusline, with the cover and the lyrics a keypress away.

![Now playing panel](images/demo/music.gif)

Daily drills come from back-to-basics, coached by the character of the day's region. Here Claire briefs the exercise, a Bedrock one here, and every name and place in it stays in Raccoon City.

![Claire briefs a Bedrock exercise](images/demo/btb_re_coach.png)

Then the fight opens by hand, with the statement beside it and completion off.

![The Bedrock exercise beside its statement](images/demo/btb_re_exercise.png)

On Elden Ring days it is Malenia, and the exercises live in the Lands Between.

![Malenia briefs a Python exercise](images/demo/btb_coach.png)

![The Python exercise beside its statement](images/demo/btb_exercise.png)

## Requirements

- Neovim 0.11 or newer (0.12 recommended)
- git
- A [Nerd Font](https://www.nerdfonts.com/) in your terminal
- The `tree-sitter` CLI, which builds the parsers
- Optional: `ripgrep` and `fd` for faster pickers, and `gh` for PRs, CI and review threads
- Optional: the Claude Code CLI for commit and PR drafts and PR reviews
- Optional: a GitHub Copilot account for inline suggestions. Run `:Copilot auth` once, the first use downloads Copilot's language server

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

Every option is a global with the `eldentree_` prefix (`vim.g.eldentree_sound = false`, `vim.g.eldentree_franchise = "resident_evil"`), set them in `lua/core/options.lua`.

## The worlds

| Module           | What it does |
| ---------------- | ------------ |
| `core/franchise` | Picks the world for the day, rotating between Elden Ring and Resident Evil. `:Franchise` or `<leader>uf` switches until midnight, `vim.g.eldentree_franchise` pins one. Each lore also picks its `mechanics`, so Resident Evil travels through doors, gets stalked instead of dueling, shows a health ECG, rests at a typewriter and ranks every run |
| `core/themes`    | Catppuccin Mocha recolored per region (ten in Elden Ring, seven in Resident Evil). One region per day, the same in every repo and every launch. Picking another with `<leader>ut` or `:Region` holds until midnight, and traveling between repos never changes it. `vim.g.eldentree_region` pins one |
| `core/skin`      | Dresses components per franchise: float borders, gutter signs, statusline separators and tabs. Elden Ring is rounded and ornate, Resident Evil wears the inventory's double frames |
| `core/chrome`    | The editor speaks the franchise: the mode badge says ROAM or SURVIVE and fades into the next mode, line numbers fade away from the cursor, notifications arrive titled Radio, Danger or Omen with the hour, pickers take an inventory or grace layout, and the command line becomes a Typewriter or an Incantation |
| `core/title`     | A title screen in big block letters once a day per franchise and on every switch, `:Title` shows it again, `vim.g.eldentree_title = false` skips it |
| `core/terminal`  | Paints the terminal around nvim with the region's background, and switches iTerm profiles, Kitty opacity or the Ghostty font and opacity per franchise. `:Opacity [90\|skin]` or `<leader>uo` picks your own opacity, kept until set back to `skin` |
| `core/sound`     | Plays the franchise's sounds for titles, doors, deaths, the merchant and the HUD (see [Sounds](#sounds)) |
| `core/motion`    | The shared animation engine. `<leader>um` or `:Motion` stills everything, ambient loops pause while nvim is unfocused |

### Your own world

Each franchise is a folder in `lua/core/franchise/lore/<name>/`, found on its own with nothing to register: `regions.lua` holds the palettes, `skin.lua` how components look, and `init.lua` the bosses, weather, banners, words, coach and mechanics. `:Franchise new Silent Hill` copies the template into a new folder, and `:checkhealth eldentree` lists what it still needs (missing words, bosses, weather, portraits, palette contrast).

## The start screen

| Module         | What it does |
| -------------- | ------------ |
| `core/hud`     | The start screen is a playable inventory. Elden Ring shows category tabs with the Inventory and the Chest side by side, Resident Evil a STATUS panel with the survivor, plate tabs and the COMMAND menu. The tabs fill from real data: recent files, branches, stashes, projects, messages and map rooms. hjkl walks the slots, Tab changes category, Enter uses, K checks, C combines, and reopening lands where you left. `:Hud` or `<leader>uh` |
| `core/hub`     | The HUD's ambient life: shimmering gold, the region's weather and a typed player message |
| `core/palette` | `<leader><leader>` (or `?` on the HUD) lists everything Eldentree does, each with its key |

## Fighting your code

| Module            | What it does |
| ----------------- | ------------ |
| `core/boss`       | When 3 or more errors linger, the region's boss arrives with a health bar. Each fix lands a hit, the last one fells it. In Resident Evil the boss is a stalker that walks closer while errors stay and backs off with every fix. `:Boss` or `<leader>uB` |
| `core/conflicts`  | Merge conflicts fight back: a buffer with conflict markers brings Godrick the Grafted (Uroboros in Resident Evil) to the boss bar, each conflict resolved lands a hit and the header counts the conflicted files left in the repo |
| `core/banner`     | Elden Ring style banners fired by commits, PRs, test runs, new projects, region changes and long fights with errors. `:Banner felled\|great\|died\|grace\|cleansed` |
| `core/bestiary`   | Every kind of error or warning you clear by editing is a foe felled, named from the franchise's enemies by its code. `:Bestiary` / `<leader>ub` shows which ones you fight the most in the repo |
| `core/runes`      | Statusline rune tally (pesetas in Resident Evil, where the Merchant greets every 10,000). Saves and banners pay out, dying leaves a bloodstain |
| `core/results`    | Ranks each run from S to D by fixes and saves, and the Resident Evil STATUS panel shows the last one |
| `core/chronicle`  | `:Chronicle` / `<leader>uj`: the last 20 weeks as a grid, each day lit by its run's rank and your commits in the repo |
| `core/expedition` | `:Expedition [minutes]` / `<leader>ue`: a focus block. Sounds, animations and quiet notifications step aside, the statusline counts down and the end ranks the block on its own |
| `core/trial`      | `:Trial` / `<leader>cT` runs the project's tests in the background and announces the verdict |
| `core/ecg`        | Resident Evil's statusline ECG: Fine, Caution or Danger from the buffer's diagnostics |
| `core/map`        | `:Map` / `<leader>fM` shows every folder as a room, red while errors or TODOs are left in it, blue once cleared |
| `core/zones`      | The first time you walk into a folder each session, it is announced like a new area |
| `core/rest`       | After 5 idle minutes in normal mode the editor rests at a Site of Grace, or at a Safe Room typewriter in Resident Evil. Any key wakes it, `:Rest` rests now |

## Git, CI and pull requests

| Module          | What it does |
| --------------- | ------------ |
| `core/git`      | Quick branch, pull, push, merge, stash and undo keys under `<leader>g`, plus the related change staging `<leader>pc` uses. Neogit covers the rest |
| Commits and PRs | `<leader>pc` stages related changes and has Claude draft the commit, `:w` commits it. `<leader>pp` picks the branches, previews the diff, has Claude draft the PR and `:w` creates or updates it with `gh`. Both follow [your style guide](#your-own-style-guide) |
| `core/review`   | `:Review [number\|url]` / `<leader>pr` has Claude analyze any PR's diff into a float, `d` opens the diff per file |
| `core/ci`       | The branch's CI run in the statusline in the franchise's words, asked to `gh` in the background. A run that finishes while you work fires the felled or the died banner, `:CI` / `<leader>gi` opens it |
| `core/threads`  | The open review threads of the branch's PR sit at the end of their lines. `<leader>mc` lists them, `<leader>mo` opens the conversation and `<leader>mr` resolves it on GitHub after asking |
| `core/phantom`  | `<leader>gw` shows who last wrote the line as a phantom: blue for others, gold for your past self |
| `core/messages` | Elden Ring style messages left on lines of code, kept per repo. `<leader>mw` writes one, `<leader>md` erases it, `<leader>ml` lists them all |

## Moving around

| Module       | What it does |
| ------------ | ------------ |
| `core/repos` | A background repo scanner, the Sites of Grace project picker (`<leader>fp`) and automatic project root. Traveling keeps the session of the repo you leave and restores the one you arrive at, files with unsaved changes are never closed (`vim.g.eldentree_project_sessions = false` turns it off). Switching branch with `<leader>gb` keeps a session per branch too |
| `core/fog`   | The fog wall that rolls over the editor when you travel, `:Fog` or `<leader>uF`. In Resident Evil `core/door` takes over: the screen goes dark and a door creaks open |
| `core/find`  | The pickers that need more than one Snacks call: recent files per repo (`<C-a>` flips to everywhere) and branches with their sessions |
| `core/dive`  | F12 family: go to definition, Glance peek, references and F2 rename. `K` hover docs arrive dressed as item descriptions |
| `core/links` | Ctrl+click opens the link under the mouse in a terminal, `<leader>to` opens the last one any terminal printed, like the dev server's localhost |

`:OpenFolder` opens the file tree at a folder you pick, and `:BrowseFolders` walks folders with hjkl, Enter travels to a repo.

## Claude Code

Claude Code can wear Eldentree too. One command wires it into `~/.claude/settings.json`, keeping everything already there and a backup of the settings from before (`settings.json.eldentree.bak`):

```sh
nvim -l claude/install.lua --dry-run   # list what would change
nvim -l claude/install.lua
```

- **Statusline**: the model on top and both usage limits below it as the game's bars (FP and stamina in the Lands Between, AMMO and HERBS in Raccoon City). The branch, the song, the region, the runes and the ECG stay in the editor's statusline right under it, so Claude Code keeps its room
- **Theme**: nvim rewrites `~/.claude/themes/eldentree.json` from the region's palette on every region or franchise change, and Claude Code reloads it on the spot. Restart Claude Code once after the first install so it sees the new themes folder
- **Spinner verbs**: every franchise's `claude.verbs`, like "Seeking grace" or "Combining herbs"
- **Sounds**: grace when Claude finishes, died when it fails, the fog wall or the door when it asks for permission

`ELDENTREE_CLAUDE_SOUND=0` mutes the sounds, and `vim.g.eldentree_claude_ui = false` stops nvim from touching the theme. Organizations that set `allowManagedHooksOnly` keep the sound hooks from running, the rest still works.

### Your own style guide

Claude follows one style guide in this config: `.claude/commands/my-style.md`. It is loaded into every Claude Code session opened here, it backs `/my-style`, and `<leader>pc` / `<leader>pp` send it to Claude when drafting commits and PRs.

It is Cristopher's guide, so replace that file with yours and everything follows it. To use it outside this repo too, link it as a global command:

```sh
ln -sf ~/.config/nvim/.claude/commands/my-style.md ~/.claude/commands/my-style.md
```

## Music

`core/music` puts the song playing in Cider (macOS, Windows, Linux) or Apple Music (macOS, Windows) in the statusline. `<leader>o` or a click on it opens the now playing panel: the album cover beside the song, artist and album, a two row equalizer, the progress bar, and the lyrics from LRCLIB swept karaoke style. `p` plays or pauses, `n` and `b` skip, `l` shows or hides the lyrics and `j` / `k` scroll the ones without timing. `:Music [playpause|next|previous]` controls it without the panel.

Cider needs its API on in Settings > Connectivity, and `vim.g.eldentree_cider_token` when it asks for a token (nvim warns once when Cider refuses it). On Windows, Apple Music is read through the system media controls with Windows PowerShell. `vim.g.eldentree_lyrics = false` starts with the lyrics hidden, `vim.g.eldentree_music = false` turns it all off.

## back-to-basics

`core/btb` brings [back-to-basics](https://github.com/thecristopher/back-to-basics) in: daily drills by hand, coached by the character of the day's region on a stage with their portrait: Claire, Malenia and Ada by their own persona, anyone else (Leon, Wesker, Radahn, Mohg...) summoned by btb the first time they coach.

- `b` on the HUD or `<leader>kk` starts the lesson, `<leader>kb` opens the library of lessons fought so far
- Saving runs the tests, and failing ones land on your solution as warnings on the line they broke
- Hints are sold by the franchise's merchant and cost runes
- Clean solves fell the enemy, level ups bring the great banner, and the pass that ends the day closes it with a rank
- `<leader>kd` opens your solution beside the reference with Claude's review on the lines it names
- `<leader>km` / `:BtbPath` draws every track as a map of levels, `<leader>kC` / `:BtbConcepts` the concepts as rooms

Needs the clone in `~/Documents/GitHub/back-to-basics` or `vim.g.eldentree_btb_dir`.

## The editor underneath

Plugin specs live in `lua/plugins/`, one file per concern, managed by lazy.nvim.

- **LSP** through native `vim.lsp.config` and mason, servers in `lua/plugins/lsp.lua`. Treesitter runs on its `main` branch, nvim-lint runs only the linters that are installed
- **Pickers** are all Snacks: files, grep, recent, branches, the palette and Sites of Grace
- **Completion** with blink. Copilot is one more source, and the top item previews inline as ghost text
- **Tests** with neotest (vitest, jest, pytest, plenary) under `<leader>T`, while `:Trial` owns the whole suite verdict
- **Debugging** with nvim-dap and dap-view, F5/F9/F10/F11 plus `<leader>D`. js-debug and debugpy come from mason
- **Editing**: quicker.nvim makes the quickfix list editable (change a line, `:w` writes it back), yanky.nvim keeps a yank history, grug-far finds and replaces across the project, multicursor adds cursors, nvim-ufo folds with a hidden line tally, and spell checks English and Spanish in markdown, commits and text
- **Snapshots**: `<leader>cp` / `:Snapshot` saves the buffer or selection as a framed PNG in the region's colors and copies it
- **Inside Cursor or VS Code** only the allow listed editing plugins load
- **`:InsertTrace`** logs every exit from insert mode with the keys right before it, for when something keeps kicking you out

A few classics from ThePrimeagen's setup live here too: cloak.nvim masks `.env` values so secrets never show on a shared screen or a snapshot, `<leader>rw` replaces the word under the cursor across the file, `<leader>cx` makes the file executable, `:VimBeGood` trains your motions, and `<leader>ur` makes it rain. Dying makes it rain on its own, `vim.g.eldentree_rain = false` keeps the code standing.

### Terminals

Everything works in iTerm. A few extras are worth turning on:

- **Fonts per franchise in iTerm.** Link the profiles once, then add `vim.g.eldentree_iterm_profiles = true` to `lua/core/options.lua`. Elden Ring switches to JetBrains Mono Light with a light blur, Resident Evil to SemiBold with no transparency.

  ```sh
  ln -s ~/.config/nvim/terminal/iterm/Eldentree.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/
  ```

- **Fonts per franchise in Ghostty.** nvim writes the franchise's font, opacity and blur to `~/.config/ghostty/eldentree` and asks Ghostty to reload it (macOS, through AppleScript). Include it once from your Ghostty config, the `?` keeps Ghostty quiet while the file does not exist yet. Reloading applies to every Ghostty window, and leaving the last nvim empties the file so Ghostty goes back to its own look, while other nvims still open keep it. `vim.g.eldentree_ghostty_config = false` turns it off.

  ```
  config-file = ?~/.config/ghostty/eldentree
  ```

- **Real image portraits.** Ghostty, Kitty and WezTerm speak the kitty graphics protocol, so the HUD shows the portraits as actual pictures instead of chafa's half blocks. The portraits are JPEG, so snacks needs ImageMagick to convert them (`brew install imagemagick`), without it they stay in chafa. Ghostty is the closest to iTerm in feel: `brew install --cask ghostty`.

Portraits in `images/portraits/` are 276x336 crops of the originals in `images/`, with contrast, color and sharpness lifted so they survive half block rendering. `python3 scripts/portraits.py` builds them with the face centered, from where `FACES` says it sits in each original, pass names to rebuild only those. A region whose portrait is missing simply shows the HUD without art.

### Sounds

Some sounds are clips from the games, the rest are made from scratch by `python3 scripts/sounds.py` out of synthesized tones and noise, with ffmpeg for the echo. Run it again after tweaking a recipe, or pass a franchise to rebuild only that one. `:Sound died` previews any of them.

To use your own instead, drop audio files into `sounds/elden_ring/` or `sounds/resident_evil/`, named after the moment they belong to: `title`, `door`, `fog`, `rest`, `boss`, `merchant`, `felled`, `great`, `died`, `grace`, `cleansed`, `region`, `zone`, `phantom`, `continue`, `summon` (the spirit calling bell that opens back-to-basics' coach stage), `comfort` (failing the same exercise again), `bought` (a hint bought from the merchant), `welcome` (the merchant opening the hint shop for the first time that day, after that `merchant` asks what you are buying), `weapon` (the merchant praising a back-to-basics pass, the banner stays quiet when it plays), `expedition` (the last sound before an expedition goes quiet), and the inventory HUD's `hud_open`, `hud_close`, `hud_move`, `hud_select`, `hud_back`. Variants like `died_2.wav` take turns. Every sound plays at 60% volume (`VOLUME` in `core/sound/actions`). Missing files stay quiet, `vim.g.eldentree_sound = false` silences everything.

### Portrait credits

The Resident Evil portraits are fan art and photography by their own authors, used here with love and full credit to them.

| Portrait | Region           | Author          |
| -------- | ---------------- | --------------- |
| Claire   | Raccoon City     | Artist pending  |
| Leon     | RPD              | Artist pending  |
| Jill     | Spencer Mansion  | Like Detectives |
| Wesker   | Umbrella Lab     | Artist pending  |
| Ashley   | Salazar Castle   | Artist pending  |
| Ada      | Saddler's Island | Artist pending  |
| Chris    | The Village      | Artist pending  |

## Keys

Leader is `<Space>`, local leader is `\`. `<leader><leader>` shows the Eldentree ones with their keys at any time.

### Worlds and the HUD

| Key                | Action                                                                         |
| ------------------ | ------------------------------------------------------------------------------ |
| `<leader><leader>` | Command palette: everything Eldentree does, each with its key (`?` on the HUD) |
| `<leader>uh`       | Open the inventory HUD                                                         |
| `<leader>uf`       | Choose today's franchise                                                       |
| `<leader>ut`       | Choose a region theme                                                          |
| `<leader>uT`       | Next region theme                                                              |
| `<leader>uo`       | Choose the terminal opacity (Kitty, Ghostty)                                   |
| `<leader>um`       | Toggle animations                                                              |
| `<leader>uF`       | Walk through a fog wall                                                        |
| `<leader>uB`       | Toggle boss fights                                                             |
| `<leader>ub`       | Bestiary of the repo                                                           |
| `<leader>ue`       | Start or end an expedition (focus block)                                       |
| `<leader>uj`       | Chronicle of the weeks you fought                                              |
| `<leader>ur`       | Make it rain                                                                   |
| `<leader>o`        | Now playing panel with the album cover and lyrics                              |

### Finding and moving

| Key                         | Action                                                                                        |
| --------------------------- | --------------------------------------------------------------------------------------------- |
| `<leader>fp`                | Sites of Grace. Enter travels, `<C-f>` `<C-g>` `<C-o>` travel and open files, grep or recent  |
| `<leader>ff` / `<leader>fa` | Find files / all files, hidden and ignored too. `file:line` jumps to the line                 |
| `<leader>fr`                | Recent files in this repo, `<C-a>` flips to everywhere                                        |
| `<leader>f.`                | Resume the last picker where you left it                                                      |
| `<leader>fM`                | Project map                                                                                   |
| `<leader>fy`                | Yank history                                                                                  |
| `<leader>fR`                | Find and replace in the project (grug-far), works on a selection too                          |
| `<leader>fF`                | Find and replace in this file                                                                 |
| `<leader>Ss` / `<leader>SS` | Restore this folder's session / pick one (`Sl` last, `Sd` stop saving)                        |
| `<leader>to`                | Open the last link a terminal printed, like the dev server's localhost                        |
| `<C-LeftMouse>`             | In a terminal, open the link under the mouse                                                  |

### Code

| Key                         | Action                                                                             |
| --------------------------- | ---------------------------------------------------------------------------------- |
| `F12`                       | Go to definition                                                                   |
| `F2`                        | Rename symbol                                                                      |
| `K`                         | Hover docs, dressed as an item description                                         |
| `<leader>xd`                | Diagnostic float                                                                   |
| `<leader>xQ`                | Toggle the quickfix list, editable (quicker)                                       |
| `<leader>ui`                | Toggle inlay hints                                                                 |
| `<leader>c>` / `<leader>c<` | Swap the parameter with the next or previous one                                   |
| `<leader>cT`                | Run tests (Trial)                                                                  |
| `<leader>cp`                | Snapshot the buffer or selection as a PNG                                          |
| `<leader>cx`                | Make this file executable                                                          |
| `<leader>rw`                | Replace the word under the cursor in this file (`<C-w>` clears the prefilled word) |
| `<leader>uc` / `<leader>uC` | Toggle the `.env` cloak, or peek one line                                          |
| `[y` / `]y`                 | Right after a paste, swap it for the older or newer yank                           |
| `<C-n>`                     | Add a cursor on the next match (multicursor)                                       |
| `<A-Up>` / `<A-Down>`       | Add a cursor above or below                                                        |
| `<leader>Ma`                | Add a cursor on every match                                                        |
| `<leader>mw` / `md` / `ml`  | Write a message on this line / erase it / list every message in the repo           |

While several cursors are active, `n` / `N` add the next or previous match, `q` / `Q` skip one, `<Left>` / `<Right>` switch the main cursor and `<Esc>` clears them.

### Git, CI and PRs

| Key                         | Action                                                       |
| --------------------------- | ------------------------------------------------------------ |
| `<leader>pc`                | Stage related changes and draft the commit with Claude       |
| `<leader>pp`                | Pick branches and draft the PR with Claude, `:w` creates it  |
| `<leader>pr`                | Claude reviews a PR's diff                                   |
| `<leader>gb`                | Switch branch, the files of each branch come back with it    |
| `<leader>gN`                | New branch (pick a prefix, type a name)                      |
| `<leader>gj`                | Pull                                                         |
| `<leader>gk`                | Push (sets upstream the first time, never forces)            |
| `<leader>gm`                | Merge the base branch into this one                          |
| `<leader>gM`                | Switch to the base branch and pull                           |
| `<leader>ga`                | Stage related changes (skips .env, logs, swap files)         |
| `<leader>gz`                | Stash everything, untracked included                         |
| `<leader>gZ`                | Pop the latest stash                                         |
| `<leader>gu`                | Undo the last unpushed commit, keep its changes staged       |
| `<leader>gi`                | Open the branch's CI run                                     |
| `<leader>gw`                | Who wrote this line (phantom)                                |
| `<leader>mc` / `mo` / `mr`  | PR review threads / open the one on this line / resolve it   |
| `<leader>gn`                | Neogit status                                                |
| `<leader>gc`                | Neogit commit                                                |
| `<leader>gp` / `<leader>gP` | Neogit pull / push popups                                    |
| `<leader>gv`                | Neogit log                                                   |
| `<leader>gr`                | Neogit branch popup                                          |
| `<leader>gC`                | Search commits                                               |

Inside a toggleterm terminal, the bar at the top lists the quick git keys. Press `<Esc>` and then `<Space>g` to use them.

### back-to-basics

| Key          | Action                                             |
| ------------ | -------------------------------------------------- |
| `<leader>kk` | Lesson with the coach                              |
| `<leader>kb` | Lesson library                                     |
| `<leader>kd` | Your solution beside the reference                 |
| `<leader>km` | The path as a map of levels                        |
| `<leader>kC` | The concept map                                    |

### Tests and debugging

| Key                         | Action                                |
| --------------------------- | ------------------------------------- |
| `<leader>Tt`                | Run the nearest test (neotest)        |
| `<leader>Tf`                | Run every test in this file           |
| `<leader>Td`                | Debug the nearest test                |
| `<leader>Ts`                | Test summary                          |
| `<leader>To`                | Output of the test under the cursor   |
| `<leader>Tw`                | Rerun this file on every save         |
| `]T` / `[T`                 | Next or previous failed test          |
| `F5`                        | Start or continue debugging           |
| `Shift F5`                  | Stop debugging                        |
| `F9`                        | Toggle breakpoint                     |
| `F10` / `F11` / `Shift F11` | Step over, into, out                  |
| `<leader>DB`                | Conditional breakpoint                |
| `<leader>Dp`                | Log point                             |
| `<leader>Dv`                | Toggle the debug view                 |
| `<leader>Dw`                | Watch the expression under the cursor |

On macOS, F11 shows the desktop unless "Use F1, F2, etc. keys as standard function keys" is on. `<leader>Di` steps into without it.

## Commands

| Command                                        | Action                                          |
| ---------------------------------------------- | ----------------------------------------------- |
| `:Franchise [elden_ring\|resident_evil]`       | Switch today's franchise                        |
| `:Franchise new <name>`                        | Create a new franchise from the template        |
| `:checkhealth eldentree`                       | Check every franchise is complete               |
| `:Region`                                      | Switch region theme                             |
| `:Opacity [90\|skin]`                          | Override the terminal opacity, or go back to the skin's |
| `:Title`                                       | Show the franchise's title screen               |
| `:Hud`                                         | Open the inventory HUD                          |
| `:Sound <event>`                               | Preview one of the franchise's sounds           |
| `:Banner felled\|great\|died\|grace\|cleansed` | Fire a banner                                   |
| `:Motion`                                      | Toggle animations                               |
| `:Fog`                                         | Walk through a fog wall                         |
| `:Rest`                                        | Rest at a Site of Grace now                     |
| `:Boss`                                        | Toggle boss fights                              |
| `:Bestiary`                                    | The foes felled in this repo                    |
| `:Expedition [minutes\|stop]`                  | A quiet focus block with its own rank           |
| `:Chronicle`                                   | The weeks you fought, as a grid                 |
| `:Trial`                                       | Run the project's tests                         |
| `:Map`                                         | Open the project map                            |
| `:Repos` / `:ReposRescan`                      | Browse or rescan known repositories             |
| `:OpenFolder`                                  | Open the file tree at a folder you pick         |
| `:BrowseFolders`                               | Walk folders with hjkl, Enter travels to a repo |
| `:Review [number\|url]`                        | Claude reviews a PR's diff                      |
| `:CI`                                          | Open the branch's CI run                        |
| `:Threads`                                     | Open review threads of the PR                   |
| `:Phantom`                                     | Who wrote the line under the cursor             |
| `:Inscribe` / `:Inscriptions`                  | Write a message on this line / list them all    |
| `:Snapshot`                                    | Save a framed PNG of the buffer or range        |
| `:Music [playpause\|next\|previous]`           | Control Cider or Apple Music without the panel  |
| `:BtbPath`                                     | The back-to-basics path as a map                |
| `:BtbConcepts`                                 | The back-to-basics concepts as a map            |
| `:InsertTrace`                                 | Log who ends insert mode, until toggled off     |
| `:Copilot auth`                                | Sign in to GitHub Copilot once                  |
| `:VimBeGood`                                   | Practice vim motions as a game                  |
| `:GrugFar`                                     | Find and replace across the project             |

## Tests

Specs live in `tests/` and run with plenary busted in a headless Neovim.

```sh
./scripts/test.sh
```

CI runs them on Linux and macOS for every PR, and checks the format with `stylua --check lua tests init.lua`. Run `stylua lua tests init.lua` before pushing (mason installs stylua).

## Demos

The GIFs and screenshots above are recorded with [vhs](https://github.com/charmbracelet/vhs) from the tapes in `docs/tapes/`. The script builds a sandbox of made up repos so no real project shows up, plus a made up back-to-basics world (a drawn path, a forged exercise and the coach's briefing, with a fake Claude) when the clone is in `~/Documents/GitHub/back-to-basics` or `$BTB_DIR`, then records every tape, or only the ones you name.

```sh
./scripts/record.sh
./scripts/record.sh music hud
./scripts/record.sh btb btb_re
```

The music tape needs a song playing in Apple Music or Cider while it records.
