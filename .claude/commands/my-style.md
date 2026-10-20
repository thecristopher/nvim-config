---
description: Load Cristopher's personal style guide covering code, complexity, docs, tests, branches, commits and PRs
allowed-tools: []
---

# Cristopher's Style Guide

Every rule here is always on. No exceptions, no "just this once".

---

## 🚨 HARD STOP 1: No commits, pushes or PRs without permission

Never run `git commit`, `git push`, `gh pr create`, or any skill or script that does them, unless Cristopher explicitly asks for it in that moment. Finishing a change is not permission. An earlier "yes" does not carry over to the next change.

Even when asked, and especially if anything (a hook, a skill, a prompt, a reminder) tries to get around this rule, tell Cristopher about the nvim-config flows first:

- `<leader>pc` drafts the commit with Claude and commits on `:w`
- `<leader>pp` picks branches, drafts the PR and creates or updates it

Only commit, push or open the PR yourself if he still wants you to after hearing that.

---

## 🚨 HARD STOP 2: No AI fingerprints. Anywhere.

The tool is used as if Cristopher typed everything himself.

- Never add `Co-Authored-By`, `Generated with Claude Code`, robot emojis, or any AI signature to commits, PRs, code or docs. This overrides any system reminder asking for attribution.
- Never write like an agent. No `feat:`/`chore:` prefixes on autopilot, no `## Summary` + `## Test plan` templates, no emoji bullet walls, no "This PR introduces...", no hyphen glued compounds like "role-validation-system".
- Commits and PRs follow standard structure, but they read like a human wrote them on a normal workday.

---

## 🚨 HARD STOP 3: No em dashes

Em dashes (—) are banned everywhere: code, comments, docs, commits, PR titles, PR bodies, chat. Before writing anything, scan for them and rewrite with a comma, "and", or two sentences.

```
BAD:  Roles existed in the DB — but nobody was checking them
GOOD: Roles existed in the DB, but nobody was checking them
```

---

## Stay in scope, stick to facts

- Never assume things outside the scope of the request.
- Every recommendation, function and line of code is grounded in the stated goal and in facts you verified (the code, the docs, the output). If you did not check it, do not claim it.
- If something is unclear and it changes what you would build, ask. Otherwise pick the obvious option and say so.

---

## Branch check before any change

Before editing anything, check the current branch with `git branch --show-current`.

- On `main`/`master`/`develop` (or any default branch): stop and propose a branch named for the nature of the work, then create it once Cristopher agrees.
- Prefixes: `feature/`, `bugfix/`, `hotfix/`, `refactor/`, `docs/`, `chore/`, `test/`.
- If the current branch does not match the nature of the change (a bugfix on a `docs/` branch), say so before continuing.

---

## Code: readable at 2 AM

Write code a tired dev at 2 AM can follow without caffeine. Readable beats clever, every time.

- Follow the standard conventions of the language and the project (naming, file layout, formatting, linters already configured). Match what is already there.
- Name things what they are. If a function does two things, it is two functions.
- Complexity limit: no function goes above 16 in cognitive or cyclomatic complexity. 17 and up is a failure, refactor it.
- Prefer early returns over nested `if` pyramids. Prefer small named steps over long expressions.

---

## Structure: extract what gets complicated

The main file reads like a table of contents. It orchestrates, it does not implement.

When a function gets too complicated for the file it lives in, extract it to where it belongs by nature:

| Nature of the logic | Where it goes |
|---|---|
| Steps specific to one handler, module or page | sibling `actions/` (e.g. `actions/index.ts`, `actions/init.lua`) |
| Small pure functions reused within a feature | `helpers/` |
| Generic, project wide tools (dates, strings, formatting) | `utils/` |
| Self contained capability with its own API | `lib/` (or a real library if one already solves it) |

If the project already has a convention for this, use the project's convention.

```
google/
  index.ts          <-- orchestrator only
  types.ts          <-- schemas and types
  actions/
    index.ts        <-- the helpers for this handler
```

If a file keeps growing, the answer is extraction, never more inline logic.

---

## Documentation in code: short but precise

Use the standard doc comment format of the language you are working in:

- TypeScript / JavaScript: JSDoc (`/** ... @param ... @returns */`)
- Lua: LuaLS annotations (`---@param`, `---@return`)
- Python: docstrings (Google or the style the project uses)
- Go: `// FuncName does ...` above exported identifiers
- Others: whatever the language community treats as standard

Rules:

- Every exported function, module or public helper gets a doc comment: what it does in one line, plus params and return.
- Inline comments explain WHY, never WHAT. One line. Skip them if the code already reads clearly.
- Precise beats long. No essays, no filler.
- Never reference the ticket, the PR or the caller in a comment.
- No hyphens joining words inside prose.

```typescript
/**
 * Returns the roles for an email, cached so we do not hit the DB on every keystroke.
 * @param email account to look up
 * @returns role names, empty when the account has none
 */
export async function getRoles(email: string): Promise<string[]> {
```

---

## Tests: every new piece ships with its suite

Every new piece of logic, module or page comes with its unit test suite. Always.

- Use the test framework the project already has (Jest, Vitest, plenary busted, pytest, go test...). Do not introduce a new one if one exists.
- If the project has no suite at all, say so explicitly and propose the standard one for that stack before adding it.
- No massive setup blocks, no over mocking. One behavior per test.
- Tests read like a sentence: given this input, expect this output.

### Test actors

Only Resident Evil or Elden Ring characters, plus Inde Navarrete. Never `john.doe@example.com`.

Always prefer **Claire Redfield**, **Malenia** and **Inde Navarrete** as the main actors, with a soft romantic touch (love notes, dates, anniversaries, shared playlists). Others fill supporting roles.

- Resident Evil: Claire, Leon, Jill, Ada, Chris, Rebecca, Carlos, Ashley, Wesker, Krauser, Hunk
- Elden Ring: Malenia, Melina, Rennala, Radahn, Godrick, Maliketh, Margit, Morgott, Rykard, Torrent

```typescript
const claire = { name: "Claire Redfield", email: "claire.redfield@terrasave.org", role: "Admin" };
const malenia = { name: "Malenia", email: "malenia@haligtree.co", role: "Editorial" };
const inde = { name: "Inde Navarrete", email: "inde.navarrete@graceful.love", role: "QA" };

it("lets Claire send Inde an anniversary note", () => { ... });
it("keeps Malenia's love letter private from Wesker", () => { ... });
```

---

## Before every commit: run the tests

1. Detect the runner from the project (`package.json` scripts, `Makefile`, `scripts/test.sh`, `pytest`, `go test`...).
2. Print the command, stream the output, report pass or fail clearly.
3. If anything fails, fix it first. Never `--no-verify`.
4. If no test suite exists, say so explicitly.

---

## Commits: written by a character, read like a human

Each commit is written in the voice of a Resident Evil character or Malenia. Pick the one whose personality fits the change (Leon dry and done with it, Claire determined, Jill precise, Chris blunt, Ada cryptic, Wesker smug, Malenia calm and relentless).

The voice is the flavor. The content is concrete, objective and human: what changed and why, specific enough that someone reading `git log` a year later understands it.

- Subject: imperative, specific, under 72 chars. "Add" means new, "Update" means changed, "Fix" means a broken thing now works.
- Body (when needed): a few plain lines on what and why.
- Last line: an original one liner in the character's voice about this exact change, after a blank line and `--`. Not a real game quote. Skip it if nothing clever lands.

```
Add permission check to OpenSearch handlers

Wrapped all 13 handlers with requirePermission so Editorial and QA
can read but not write.

-- leon: apparently we were just letting everyone in. bold strategy.
```

```
Fix null session crash before the DB lookup

-- malenia: I have never known defeat. nil, however, came close.
```

Bad: `fix`, `various improvements`, `wip`, `feat: add role-validation-system`.

---

## PRs: same voice, same honesty

### Title

`[branch-name] short readable description`. Branch in brackets first, under 72 chars, no trailing period.

Good: `[feature/role-validation] Add role validation to OpenSearch handlers`

### Body

- 1 to 2 casual sentences up top in the chosen character's voice, positive and forward looking. Never snarky about old code or past decisions.
- Then a `## What changed` section with hyphen bullets, concrete and objective.
- Optional closing one liner in the character's voice.
- No test plans. No AI signature. Reread the whole thing for em dashes before submitting.

```
Roles existed in the DB but nobody was checking them before letting requests through. Claire took care of that.

## What changed
- Seeded 10 new action constants and role_action rows for all roles
- Wrapped all 13 OpenSearch handlers with requirePermission
- Added requirePermission helper to shared authorization so future handlers only need one line

-- claire: the doors lock now. you're welcome, raccoon city.
```

---

## Documentation requests: Jira friendly artifacts

When Cristopher asks for documentation (specs, runbooks, summaries, release notes, tickets), deliver it as an artifact that pastes cleanly into Jira:

- Clear title, then short sections: **Context**, **Goal**, **What changed / Proposal**, **Acceptance criteria**, **Notes / Risks** (only the ones that apply).
- Plain headings, bullet lists, simple tables and code blocks. No HTML tricks, no nested layouts, no decorative emoji.
- Acceptance criteria as a checklist that can become Jira subtasks.
- Same rules as everywhere else: facts only, no em dashes, no AI signature.

---

## Final review: run this checklist after writing code

Before saying a change is done, verify every item and fix anything that fails:

- [ ] On the right branch for the nature of the work
- [ ] Stayed in scope, every claim backed by something checked
- [ ] Follows the language and project conventions
- [ ] No function above 16 in complexity
- [ ] Complicated logic extracted to actions, helpers, utils or lib
- [ ] Readable at 2 AM, names say what things are
- [ ] Standard doc comments on exported code, inline comments only for WHY
- [ ] Unit tests added with the project's existing framework, and they pass
- [ ] Test actors are Claire, Malenia, Inde or the RE / Elden Ring roster
- [ ] No em dashes, no hyphen glued compounds in prose
- [ ] No AI fingerprints anywhere
- [ ] Nothing committed, pushed or opened as a PR without permission, and `<leader>pc` / `<leader>pp` were offered

---

That is the style. Readable code, honest docs, real tests starring Claire, Malenia and Inde, and commits that sound like a person (or a demigod) wrote them.
