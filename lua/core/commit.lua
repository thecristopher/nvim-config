-- Claude-assisted commit: stage if needed, ask for an optional vibe,
-- draft a my-style-compliant message, edit in buffer, commit on :w.
-- Mapped to <leader>pc from lua/plugins/commit.lua.

local M = {}

local MAX_DIFF = 6000
local DISALLOWED_TOOLS = "Bash Edit Write NotebookEdit Read Grep Glob Task WebFetch WebSearch Agent Artifact"

-- bufnr -> true while an uncommitted draft is open
local pending = {}

local function notify_err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Commit" })
end

local function notify_info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "Commit", id = "commit_claude" })
end

local function git_ok(args)
  vim.fn.system(vim.list_extend({ "git" }, args))
  return vim.v.shell_error == 0
end

local function has_staged()
  vim.fn.system({ "git", "diff", "--cached", "--quiet" })
  return vim.v.shell_error ~= 0
end

local function has_unstaged()
  vim.fn.system({ "git", "diff", "--quiet" })
  return vim.v.shell_error ~= 0
end

local function has_untracked()
  return vim.trim(vim.fn.system({ "git", "ls-files", "--others", "--exclude-standard" })) ~= ""
end

local function staged_diff()
  local out = vim.fn.system({ "git", "diff", "--cached" })
  return vim.v.shell_error == 0 and vim.trim(out) or ""
end

local function recent_log()
  local out = vim.fn.system({ "git", "log", "--oneline", "-5" })
  return vim.v.shell_error == 0 and vim.trim(out) or ""
end

local function branch_name()
  local out = vim.fn.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
  return vim.v.shell_error == 0 and vim.trim(out) or "unknown"
end

local function draft_via_claude(prompt, cb)
  notify_info("Drafting commit message with Claude…")
  local start = vim.loop.now()
  local timer = vim.loop.new_timer()
  timer:start(4000, 4000, vim.schedule_wrap(function()
    local secs = math.floor((vim.loop.now() - start) / 1000)
    notify_info(("Drafting… (%ds)"):format(secs))
  end))
  vim.system(
    { "claude", "-p", prompt, "--disallowedTools", DISALLOWED_TOOLS },
    { text = true },
    function(res)
      timer:stop()
      timer:close()
      vim.schedule(function() cb(res) end)
    end
  )
end

local function open_editor(msg)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.bo[buf].buftype   = "acwrite"
  vim.bo[buf].filetype  = "gitcommit"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "COMMIT_EDITMSG (Claude)")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(msg, "\n", { plain = true }))
  vim.bo[buf].modified = false
  pending[buf] = true

  local width  = math.min(math.floor(vim.o.columns * 0.7), 100)
  local height = math.min(math.floor(vim.o.lines * 0.45), 18)
  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
    width     = width,
    height    = height,
    border    = "rounded",
    title     = " Commit Message ",
    title_pos = "center",
  })
  vim.wo[win].wrap      = true
  vim.wo[win].linebreak = true
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer   = buf,
    callback = function() M.submit(buf) end,
  })

  notify_info("Edit then :w to commit. :q! discards.")
end

function M.submit(buf)
  if not pending[buf] then return end

  local lines     = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local msg_lines = vim.tbl_filter(function(l) return not l:match("^%s*#") end, lines)
  local msg       = vim.trim(table.concat(msg_lines, "\n"))

  if msg == "" then
    notify_err("Commit message can't be empty.")
    return
  end

  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(msg, "\n", { plain = true }), tmp)
  local out = vim.fn.system({ "git", "commit", "-F", tmp })
  vim.fn.delete(tmp)

  if vim.v.shell_error ~= 0 then
    notify_err("git commit failed:\n" .. out)
    return
  end

  vim.bo[buf].modified = false
  pending[buf] = nil
  notify_info("Committed: " .. (msg:match("^([^\n]+)") or ""))

  vim.schedule(function()
    pcall(vim.api.nvim_win_close, 0, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end

function M.open()
  if not git_ok({ "rev-parse", "--is-inside-work-tree" }) then
    return notify_err("Not inside a git repository.")
  end

  local staged = has_staged()

  if not staged then
    if not has_unstaged() and not has_untracked() then
      return notify_info("Nothing to commit.")
    end
    local choice = vim.fn.confirm("Nothing staged. Stage all changes?", "&Yes\n&Cancel", 1)
    if choice ~= 1 then return end
    if not git_ok({ "add", "-A" }) then
      return notify_err("git add -A failed.")
    end
    notify_info("Staged all changes.")
  end

  local diff = staged_diff()
  if diff == "" then return notify_err("No staged diff to commit.") end

  if #diff > MAX_DIFF then
    diff = vim.trim(vim.fn.system({ "git", "diff", "--cached", "--stat" }))
      .. "\n\n[diff truncated — stat only]"
  end

  local log    = recent_log()
  local branch = branch_name()

  vim.ui.input({ prompt = "Vibe? (optional, Enter to skip): " }, function(vibe)
    if vibe == nil then return end  -- user hit <Esc>
    vibe = vim.trim(vibe)

    local vibe_line = vibe ~= ""
      and ('The user set the vibe: "' .. vibe .. '". Let that flavor the personality of the message.')
      or  "No specific vibe set. Follow the style guide naturally."

    local prompt = table.concat({
      "Write a git commit message for the staged diff below.",
      "",
      "Style rules (non-negotiable):",
      "- Fun, human, and specific. Write like a person, not a changelog.",
      "  Good: 'Add permission check to API handler (finally)'",
      "  Bad: 'fix stuff', 'update code', 'refactor authentication logic'",
      "- One short subject line under 72 chars. Optionally one blank line then a",
      "  short body if the change is genuinely complex.",
      "- NEVER use em dashes (—) anywhere. Not even once.",
      "- No hyphenated compound words in prose.",
      "- Never add 'Co-Authored-By: Claude Code' or any AI attribution.",
      "- End with a dry, original Leon S. Kennedy one-liner aimed at this exact change.",
      "  Deadpan wit about what just happened. Specific to the diff, not generic.",
      "  Separate it from the body with a blank line and '--' on a new line.",
      "  Example: '-- turns out nil is not a valid user id. took us a minute.'",
      "  If nothing clever lands, leave it out. A weak line is worse than none.",
      "",
      vibe_line,
      "",
      "Current branch: " .. branch,
      "Recent commits (for tone reference):",
      log,
      "",
      "Staged diff:",
      diff,
      "",
      "Output ONLY the commit message. No explanation, no code fences, no preamble.",
    }, "\n")

    draft_via_claude(prompt, function(res)
      if res.code ~= 0 or not res.stdout or vim.trim(res.stdout) == "" then
        notify_err("Claude failed: " .. vim.trim(res.stderr or "unknown error"))
        return
      end
      open_editor(vim.trim(res.stdout))
    end)
  end)
end

return M
