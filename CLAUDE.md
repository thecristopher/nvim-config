# Eldentree — nvim-config

This is Cristopher's personal Neovim configuration. The full my-style guide below is always
active for every session in this repo. No need to invoke /my-style manually.

---

## Project context

- Plugin manager: lazy.nvim (stable branch)
- All plugin configs live in `lua/plugins/` (one file per concern), returning lazy.nvim spec tables
- Core config (options, keymaps, autocmds) lives in `lua/core/`
- Theme: catppuccin-mocha with a custom Elden Ring palette
- Leader: `<Space>` | Local leader: `\`
- `~/.config/nvim` is a symlink to this repo, so every saved `.lua` file is live immediately
- LSP uses native `vim.lsp.config` plus mason-lspconfig v2 (`automatic_enable`), servers live in `lua/plugins/lsp.lua`
- `lua/core/dive/`: F12 family (definition, Glance peek, references, F2 rename), bound on LspAttach
- `lua/core/repos/`: background repo scanner, Sites of Grace picker (`<leader>fp`), auto root, dashboard items
- `lua/core/vscode/`: when `vim.g.vscode` is set (Cursor/VS Code), only the allow listed editing plugins load
- Pure logic goes in each module's `actions/init.lua` so it can be unit tested
- Tests: `./scripts/test.sh` (plenary busted, specs in `tests/`)

---

## My style guide (always on)

### HARD STOP: no em dashes

Em dashes (—) are absolutely banned. Before writing anything, scan what you are about to write
and delete every em dash. No exceptions. Rewrite with a comma, "and", or split into two sentences.

```
BAD:  Roles existed in the DB — but nobody was checking them
GOOD: Roles existed in the DB, but nobody was checking them
```

This applies to: commit messages, PR titles, PR bodies, code comments, and all prose.

---

### Code

Write code that a tired dev at 2am can still follow without caffeine. Readable beats clever.
Name things what they are. If a function does two things, it should be two functions.

---

### Comments

Explain WHY, not WHAT. One line max. Skip it if the code already reads clearly.
Never reference the ticket, PR, or caller. No hyphens inside paragraph text.

Good:
```lua
-- cache this because hitting disk on every keypress would be offensive
local cached = get_with_cache(key)
```

Bad:
```lua
-- get the user
local user = get_user()
```

---

### Commits

Fun, human, and specific. Write like a person, not a changelog generator.

Good:
```
Add permission check to OpenSearch handlers (finally)
Wire requirePermission into all feed handlers
```

Bad:
```
fix
various improvements
feat: add role-validation-system
```

Rules:
- Be specific: "Add" = new, "Update" = changed, "Fix" = broken thing now works
- No em dashes (—). None. Reread before committing and remove any you find.
- No hyphenated compound words in prose.
- Never add "Co-Authored-By: Claude Code" or any AI attribution. Commits are Cristopher's.

#### Leon S. Kennedy one-liner

End commits and PR openers with a dry, original Leon S. Kennedy quip about the specific change.
Not a real game quote. Deadpan wit aimed directly at what just happened. Lowercase is fine.
Separate it with a blank line and `--`. If nothing clever lands, leave it out entirely.

```
-- turns out nil is not a valid user id. took us a minute.
-- apparently we were just letting everyone in. bold strategy.
-- the bouncer was living inside the door. moved him out front.
```

#### Before every commit

Run the full test suite first. Show the command, stream output, report pass/fail.
If no test suite is found, say so explicitly. Never use `--no-verify`.

---

### PR titles

`[branch-name] short readable description` — branch name in brackets first, then what was done.
No trailing period. Under 72 chars.

---

### PR messages

1-2 casual sentences up top, then a `## What changed` section with hyphen bullets.
No test plans. Tone is positive and forward-looking — never snarky about old code or past decisions.

```
Roles existed in the DB but nobody was actually checking them before letting requests through. Fixed that.

## What changed
- Seeded 10 new action constants and role_action rows for all roles
- Wrapped all 13 OpenSearch handlers with requirePermission
- Added requirePermission helper to shared authorization
```

What is NOT fine: hyphens joining prose words like an AI ("role-validation-system"), and em dashes anywhere.

---

### Code structure

Keep it flat. Extract helpers early into a sibling `actions/index.ts` (or equivalent). The main
handler just calls them — it does not implement logic itself beyond orchestration.

---

### Tests

Always write a test for new functionality. No massive setup blocks. One behavior per test.
Tests should read like a sentence: given this input, expect this output.

Test actors are Resident Evil or Elden Ring characters only. No john.doe@example.com.

Resident Evil: Wesker, Leon, Jill, Claire, Ada, Chris, Rebecca, Carlos, Ashley, Krauser, Hunk.
Elden Ring: Godrick, Malenia, Rennala, Radahn, Maliketh, Melina, Margit, Morgott, Rykard.

```typescript
const user  = { email: "leon.kennedy@raccoon.gov",  role: "Editorial" }
const admin = { email: "albert.wesker@umbrella.corp", role: "Admin" }
```
