-- Claude-assisted commit: stage the related changes, ask for an optional vibe,
-- draft a message from the repo's my-style guide, edit in buffer, commit on :w.
-- Mapped to <leader>pc from lua/plugins/commit.lua.

local M = {}

-- characters of diff Claude reads, shared fairly between the files, see core.git.actions.trim_diff
local MAX_DIFF = 16000

-- what the franchise says while drafting, see the commit.* keys in lua/core/franchise/lines.lua
local function say(key, vars)
  return require("core.franchise").line("commit." .. key, vars)
end

-- bufnr -> the repo its draft commits into, while an uncommitted draft is open
local pending = {}
-- bufnr -> true while git commit runs, so a second :w never commits twice
local committing = {}

local function notify_err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = say("title") })
end

local function notify_info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = say("title"), id = "commit_claude" })
end

local function git(root, args)
  return vim.list_extend({ "git", "-C", root }, args)
end

local function git_ok(root, args)
  vim.fn.system(git(root, args))
  return vim.v.shell_error == 0
end

local function has_staged(root)
  vim.fn.system(git(root, { "diff", "--cached", "--quiet" }))
  return vim.v.shell_error ~= 0
end

local function staged_diff(root)
  local out = vim.fn.system(git(root, { "diff", "--cached" }))
  return vim.v.shell_error == 0 and vim.trim(out) or ""
end

local function recent_log(root)
  local out = vim.fn.system(git(root, { "log", "--oneline", "-5" }))
  return vim.v.shell_error == 0 and vim.trim(out) or ""
end

local function branch_name(root)
  local out = vim.fn.system(git(root, { "rev-parse", "--abbrev-ref", "HEAD" }))
  return vim.v.shell_error == 0 and vim.trim(out) or "unknown"
end

local function draft_via_claude(prompt, cb)
  -- the character speaks in the dialogue box, the bar keeps its own id so the editor's hint
  -- never replaces it
  require("core.voice").say("committing")
  local task = require("core.progress").start({
    id = "commit_claude_draft",
    title = say("title"),
    message = say("drafting"),
  })
  require("core.claude").run(prompt, function(res)
    if res.code ~= 0 or vim.trim(res.stdout or "") == "" then
      task:fail(say("failed"))
    else
      task:done(say("ready"))
    end
    cb(res)
  end)
end

local function open_editor(msg, root, skipped)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].filetype = "gitcommit"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "COMMIT_EDITMSG (Claude)")

  local lines = vim.split(msg, "\n", { plain = true })
  vim.list_extend(lines, require("core.git.actions").left_out_comments(skipped))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  pending[buf] = root

  local width = math.min(math.floor(vim.o.columns * 0.7), 100)
  local height = math.min(math.floor(vim.o.lines * 0.45), 18)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = require("core.skin").border(),
    title = " " .. require("core.skin").title(say("window")) .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      M.submit(buf)
    end,
  })

  notify_info("Edit then :w to commit. :q! discards.")
end

local function committed(buf, msg)
  pending[buf] = nil
  local subject = msg:match("^([^\n]+)") or ""
  -- a commit pays its runes without the merchant, he only comes for the purse elsewhere
  require("core.banner").show("felled", { subtitle = subject, merchant = false })
  local root = require("core.git").repo()
  local branch = { branch = require("core.repos").branch(root) or "" }
  vim.schedule(function()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      pcall(vim.api.nvim_win_close, win, true)
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
  require("core.voice").say("committed", branch)
  return say("done", { subject = subject })
end

-- git commit runs in the background, so a slow pre-commit hook moves the bar instead of freezing
local function commit(buf, root, msg)
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(msg, "\n", { plain = true }), tmp)
  committing[buf] = true
  -- :wq quits right after the write, a draft still marked modified would refuse to close
  vim.bo[buf].modified = false
  local task = require("core.progress").start({
    id = "commit_claude",
    title = say("title"),
    message = say("committing"),
  })
  vim.system(
    git(root, { "commit", "-F", tmp }),
    { text = true },
    vim.schedule_wrap(function(result)
      vim.fn.delete(tmp)
      committing[buf] = nil
      if result.code ~= 0 then
        pending[buf] = nil
        if vim.api.nvim_buf_is_valid(buf) then
          pending[buf] = root
          vim.bo[buf].modified = true
        else
          -- :wq already closed the draft, a failing hook must not throw the message away
          open_editor(msg, root, {})
        end
        task:fail(
          "git commit failed:\n" .. vim.trim((result.stdout or "") .. "\n" .. (result.stderr or ""))
        )
        require("core.banner").show("died", { subtitle = say("fell") })
        return
      end
      task:done(committed(buf, msg))
    end)
  )
end

function M.submit(buf)
  local root = pending[buf]
  if not root or committing[buf] then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local msg_lines = vim.tbl_filter(function(l)
    return not l:match("^%s*#")
  end, lines)
  local msg = vim.trim(table.concat(msg_lines, "\n"))

  if msg == "" then
    notify_err("Commit message can't be empty.")
    return
  end

  commit(buf, root, msg)
end

function M.open()
  -- the buffer's repo, so a file opened from another repo commits there and not in nvim's cwd
  local root = require("core.git").repo()
  if not git_ok(root, { "rev-parse", "--is-inside-work-tree" }) then
    return notify_err("Not inside a git repository.")
  end

  local staged, skipped = require("core.git").stage_related(root)
  if not staged then
    return notify_err("git add failed.")
  end
  if #skipped > 0 then
    vim.notify(
      say("left_out", { files = table.concat(skipped, ", ") }),
      vim.log.levels.WARN,
      { title = say("title") }
    )
  end
  if not has_staged(root) then
    return notify_info(say("nothing"))
  end

  local diff = staged_diff(root)
  if diff == "" then
    return notify_err("No staged diff to commit.")
  end
  -- every file keeps its share of the budget, so Claude reads real changes and not just a stat
  diff = require("core.git.actions").trim_diff(diff, MAX_DIFF)

  local log = recent_log(root)
  local branch = branch_name(root)

  vim.ui.input({ prompt = "Vibe? (optional, Enter to skip): " }, function(vibe)
    if vibe == nil then
      return
    end -- user hit <Esc>
    vibe = vim.trim(vibe)

    local vibe_line = vibe ~= ""
        and ('The user set the vibe: "' .. vibe .. '". Let that color the tone of the message.')
      or "No specific vibe set. Follow the style guide naturally."

    local lines = { "Write a git commit message for the staged diff below.", "" }
    vim.list_extend(lines, require("core.style").prompt_lines())
    vim.list_extend(lines, {
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
    })
    local prompt = table.concat(lines, "\n")

    draft_via_claude(prompt, function(res)
      if res.code ~= 0 or not res.stdout or vim.trim(res.stdout) == "" then
        notify_err("Claude failed: " .. vim.trim(res.stderr or "unknown error"))
        return
      end
      open_editor(vim.trim(res.stdout), root, skipped)
    end)
  end)
end

return M
