-- PR helper: pick a source branch, a destination branch, and preview the
-- diff (Snacks pickers), then draft a title + description with Claude Code
-- (headless) following the repo's my-style guide, open it in an editable
-- buffer, and create/update the PR via `gh` on :w.
-- Toggle: <leader>pp

local Snacks = require("snacks")

local M = {}

local MAX_DIFF = 8000

-- bufnr -> { base = "main", branch = "feature/x", pr = { number, url } or nil }
local drafts = {}

local function notify_err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "PR Helper" })
end

local function notify_info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "PR Helper", id = "pr_helper" })
end

-- ── git/gh plumbing (synchronous — quick, local-ish, one-shot user action) ──

local function git_ok(args)
  vim.fn.system(vim.list_extend({ "git" }, args))
  return vim.v.shell_error == 0
end

local function current_branch()
  local out = vim.fn.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
  if vim.v.shell_error ~= 0 then return nil end
  return vim.trim(out)
end

-- Per-repo override: `git config pr-helper.base <branch>` wins over everything.
local function configured_base()
  local out = vim.fn.system({ "git", "config", "--get", "pr-helper.base" })
  if vim.v.shell_error ~= 0 then return nil end
  local v = vim.trim(out)
  return v ~= "" and v or nil
end

-- `staging` is checked before the repo's actual GitHub default branch since
-- most of these repos merge feature work into staging first, promoting to
-- main/master separately later.
local BASE_CANDIDATES = { "staging", "main", "master" }

local function default_branch()
  local cfg = configured_base()
  if cfg then return cfg end

  for _, name in ipairs(BASE_CANDIDATES) do
    if git_ok({ "show-ref", "--verify", "--quiet", "refs/remotes/origin/" .. name }) then
      return name
    end
  end

  local out = vim.fn.system({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
  if vim.v.shell_error == 0 then
    return vim.trim(out):gsub("^origin/", "")
  end
  return nil
end

-- Prefer origin/<base> for comparisons; fall back to the local branch.
local function base_ref(base)
  if git_ok({ "show-ref", "--verify", "--quiet", "refs/remotes/origin/" .. base }) then
    return "origin/" .. base
  end
  return base
end

local function has_upstream()
  vim.fn.system({ "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" })
  return vim.v.shell_error == 0
end

local function unpushed_count()
  local out = vim.fn.system({ "git", "rev-list", "@{u}..HEAD", "--count" })
  if vim.v.shell_error ~= 0 then return 0 end
  return tonumber(vim.trim(out)) or 0
end

local function commit_log(base_r, branch)
  local out = vim.fn.system({ "git", "log", "--reverse", "--format=- %s", base_r .. ".." .. branch })
  if vim.v.shell_error ~= 0 then return "" end
  return vim.trim(out)
end

local function diff_context(base_r, branch)
  local diff = vim.fn.system({ "git", "diff", base_r .. "..." .. branch })
  if vim.v.shell_error ~= 0 then return "" end
  if #diff > MAX_DIFF then
    local stat = vim.fn.system({ "git", "diff", base_r .. "..." .. branch, "--stat" })
    return vim.trim(stat) .. "\n\n[diff too large to include in full; showing stat only]"
  end
  return diff
end

local function existing_pr(branch)
  local out = vim.fn.system({ "gh", "pr", "view", branch, "--json", "number,url" })
  if vim.v.shell_error ~= 0 then return nil end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok or type(decoded) ~= "table" then return nil end
  return decoded
end

-- ── Branch/preview pickers (Snacks) ─────────────────────────────────────────

local function local_branches()
  local out = vim.fn.system({ "git", "for-each-ref", "--format=%(refname:short)%09%(subject)", "refs/heads" })
  if vim.v.shell_error ~= 0 then return {} end
  local list = {}
  for line in vim.gsplit(vim.trim(out), "\n", { plain = true }) do
    local name, subject = line:match("^(.-)\t(.*)$")
    if name then list[#list + 1] = { name = name, subject = subject } end
  end
  return list
end

-- Local-branch picker with `default` sorted to the top (so `<CR>` on open
-- reproduces it). Built from a static item list rather than Snacks'
-- `git_branches` finder + a prefilled fuzzy `pattern`: that combination races
-- the async matcher against the list cursor — the cursor stays pinned to
-- whichever item loaded first instead of following the pattern's top match,
-- so `<CR>` can silently confirm the wrong branch. A static, pre-sorted list
-- has no matcher re-sort to race against.
local function pick_branch(title, default, cb)
  local branches = local_branches()
  if #branches == 0 then
    return notify_err("No local branches found.")
  end
  local items = {}
  local function add(b)
    items[#items + 1] = {
      text   = b.subject ~= "" and (b.name .. "  " .. b.subject) or b.name,
      branch = b.name,
    }
  end
  for _, b in ipairs(branches) do
    if b.name == default then add(b) end
  end
  for _, b in ipairs(branches) do
    if b.name ~= default then add(b) end
  end

  Snacks.picker.pick({
    title   = title,
    items   = items,
    format  = "text",
    confirm = function(picker, item)
      picker:close()
      if not item then
        notify_err("No branch selected.")
        return
      end
      -- the closing picker drops insert mode on its way out, so open the next prompt after it is gone
      vim.schedule(function() cb(item.branch) end)
    end,
  })
end

-- Custom base...branch diff, reusing Snacks' diff-picker rendering (file list
-- with A/M/D/R markers + full diff pane) since the built-in `git_diff` picker
-- only ever diffs against HEAD, not two arbitrary branches.
local function preview_diff(base_r, branch, base, cb)
  local Diff = require("snacks.picker.source.diff")
  local cwd = vim.uv.cwd()
  Snacks.picker.pick({
    finder = function(_, ctx)
      return Diff.diff({
        cmd  = "git",
        args = {
          "-c", "core.quotepath=false", "--no-pager", "diff", "--no-color",
          "--no-ext-diff", "--diff-filter=u", base_r .. "..." .. branch,
        },
        cwd = cwd,
      }, ctx)
    end,
    format  = "git_status",
    preview = "diff",
    title   = ("PR Preview: %s -> %s"):format(branch, base),
    confirm = function(picker)
      picker:close()
      vim.schedule(cb)
    end,
  })
end

-- ── Claude draft (async — this is the slow step) ────────────────────────────

local function draft_via_claude(prompt, cb)
  notify_info("Drafting PR description with Claude…")
  local start = vim.uv.now()
  local timer = vim.uv.new_timer()
  timer:start(6000, 6000, vim.schedule_wrap(function()
    local secs = math.floor((vim.uv.now() - start) / 1000)
    notify_info(("Drafting PR description with Claude… (%ds elapsed)"):format(secs))
  end))
  require("core.claude").run(prompt, function(res)
    timer:stop()
    timer:close()
    cb(res)
  end)
end

local function parse_draft(text)
  local title, body = text:match("TITLE:%s*(.-)\n===\n?(.*)")
  if not title then
    title, body = text:match("^(.-)\n(.*)")
  end
  return vim.trim(title or text), vim.trim(body or "")
end

-- ── Editable draft buffer ────────────────────────────────────────────────────

local function open_editor(base, branch, pr, title, body)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.bo[buf].buftype   = "acwrite"
  vim.bo[buf].filetype  = "markdown"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, ("PR Draft: %s -> %s"):format(branch, base))

  local lines = { title, "" }
  vim.list_extend(lines, vim.split(body, "\n", { plain = true }))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false

  drafts[buf] = { base = base, branch = branch, pr = pr }

  local width, height = math.floor(vim.o.columns * 0.7), math.floor(vim.o.lines * 0.7)
  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
    width     = width,
    height    = height,
    border    = "rounded",
    title     = pr and (" Update PR #%d "):format(pr.number) or " Create PR ",
    title_pos = "center",
  })
  vim.wo[win].wrap      = true
  vim.wo[win].linebreak = true
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer   = buf,
    callback = function() M.submit(buf) end,
  })

  notify_info(("Edit the draft, then :w to %s. :q! discards it."):format(
    pr and ("update PR #" .. pr.number) or "create the PR"))
end

-- ── Submit: push if needed, then gh pr create/edit ──────────────────────────

function M.submit(buf)
  local ctx = drafts[buf]
  if not ctx then return end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local title = vim.trim(lines[1] or "")
  if title == "" then
    notify_err("PR title can't be empty.")
    return
  end
  local body_lines = {}
  for i = 3, #lines do body_lines[#body_lines + 1] = lines[i] end
  local body = vim.trim(table.concat(body_lines, "\n"))

  if not has_upstream() then
    if vim.fn.confirm(("Branch '%s' has no upstream. Push to origin now?"):format(ctx.branch), "&Yes\n&Cancel", 1) ~= 1 then
      return
    end
    notify_info(("Pushing '%s' to origin…"):format(ctx.branch))
    if not git_ok({ "push", "-u", "origin", ctx.branch }) then
      notify_err("git push failed.")
      return
    end
    notify_info("Push complete.")
  else
    local ahead = unpushed_count()
    if ahead > 0 then
      if vim.fn.confirm(("Push %d unpushed commit(s) on '%s' to origin now?"):format(ahead, ctx.branch), "&Yes\n&Cancel", 1) ~= 1 then
        return
      end
      notify_info(("Pushing %d commit(s) to origin…"):format(ahead))
      if not git_ok({ "push" }) then
        notify_err("git push failed.")
        return
      end
      notify_info("Push complete.")
    end
  end

  notify_info(ctx.pr and ("Updating PR #%d on GitHub…"):format(ctx.pr.number) or "Creating PR on GitHub…")
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(body, "\n", { plain = true }), tmp)

  local out
  if ctx.pr then
    out = vim.fn.system({ "gh", "pr", "edit", tostring(ctx.pr.number), "--title", title, "--body-file", tmp })
  else
    out = vim.fn.system({ "gh", "pr", "create", "--title", title, "--body-file", tmp, "--base", ctx.base, "--head", ctx.branch })
  end
  local ok = vim.v.shell_error == 0
  vim.fn.delete(tmp)

  if not ok then
    notify_err(("gh pr %s failed:\n%s"):format(ctx.pr and "edit" or "create", out))
    require("core.banner").show("died", { subtitle = "the pull request did not survive" })
    return
  end

  vim.bo[buf].modified = false
  local url = ctx.pr and ctx.pr.url or vim.trim(out)
  notify_info(ctx.pr and ("Updated PR #%d: %s"):format(ctx.pr.number, url) or ("Created PR: %s"):format(url))
  require("core.banner").show("great", { subtitle = title })

  vim.schedule(function()
    pcall(vim.api.nvim_win_close, 0, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end

-- Builds the Claude prompt and fires the draft request.
local function do_draft(branch, base, log, diff, pr, vibe)
  local vibe_line = vibe ~= ""
    and ('The user set the vibe: "' .. vibe .. '". Let that color the tone of the opener.')
    or  "No specific vibe. Follow the style guide naturally."

  local lines = {
    ("Draft a GitHub pull request for merging branch `%s` into `%s`."):format(branch, base),
    "Use the commit log and diff below for context.",
    "",
  }
  vim.list_extend(lines, require("core.style").prompt_lines())
  vim.list_extend(lines, {
    "",
    vibe_line,
    "",
    "Commits (oldest first):",
    log,
    "",
    "Diff:",
    diff,
    "",
    "Respond with EXACTLY this format and nothing else (no code fences, no preamble):",
    ("TITLE: [%s] <short description of the work, no trailing period, under 72 chars>"):format(branch),
    "===",
    "<1 to 2 casual sentences about what this PR does and why>",
    "",
    "## What changed",
    "- <specific thing that was done>",
    "- <specific thing that was done>",
  })
  local prompt = table.concat(lines, "\n")

  draft_via_claude(prompt, function(res)
    if res.code ~= 0 or not res.stdout or vim.trim(res.stdout) == "" then
      notify_err("Claude failed to draft a description: " .. vim.trim(res.stderr or "unknown error"))
      return
    end
    local title, body = parse_draft(res.stdout)
    open_editor(base, branch, pr, title, body)
  end)
end

-- Runs once source + destination are both chosen: prepares context, shows the
-- diff preview, asks for an optional vibe, then hands off to do_draft.
local function proceed(branch, base)
  local base_r = base_ref(base)
  notify_info("Preparing diff context…")
  local log = commit_log(base_r, branch)
  if log == "" then
    return notify_err(("No commits ahead of '%s'."):format(base))
  end
  local diff = diff_context(base_r, branch)
  local pr   = existing_pr(branch)

  preview_diff(base_r, branch, base, function()
    vim.ui.input({ prompt = "Vibe? (optional, Enter to skip): " }, function(vibe)
      if vibe == nil then return end
      do_draft(branch, base, log, diff, pr, vim.trim(vibe))
    end)
  end)
end

-- ── Entry point ──────────────────────────────────────────────────────────────

function M.open()
  if not git_ok({ "rev-parse", "--is-inside-work-tree" }) then
    return notify_err("Not inside a git repository.")
  end
  if vim.fn.executable("gh") == 0 then
    return notify_err("gh CLI not found. Install with: brew install gh && gh auth login")
  end

  local default_base = default_branch()
  if not default_base then
    return notify_err("Couldn't determine the base branch (no origin/staging, origin/main, origin/master, or origin/HEAD). Set one with: git config pr-helper.base <branch>")
  end
  local branch = current_branch()
  if not branch or branch == "HEAD" then
    return notify_err("Not on a branch (detached HEAD).")
  end

  pick_branch("PR: source branch", branch, function(source)
    pick_branch("PR: destination branch", default_base, function(destination)
      if source == destination then
        return notify_err(("Source and destination can't both be '%s'."):format(source))
      end
      proceed(source, destination)
    end)
  end)
end

return M
