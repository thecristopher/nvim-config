-- Claude-assisted commit: stage the related changes, ask for an optional vibe,
-- draft a message from the repo's my-style guide, edit in buffer, commit on :w.
-- Mapped to <leader>pc from lua/plugins/commit.lua.

local M = {}

local MAX_DIFF = 6000

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
  local task = require("core.progress").start({
    id = "commit_claude",
    title = "Commit",
    message = "Drafting commit message with Claude…",
  })
  require("core.claude").run(prompt, function(res)
    if res.code ~= 0 or vim.trim(res.stdout or "") == "" then
      task:fail("Claude could not draft the commit")
    else
      task:done("Draft ready")
    end
    cb(res)
  end)
end

local function open_editor(msg)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].filetype = "gitcommit"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_name(buf, "COMMIT_EDITMSG (Claude)")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(msg, "\n", { plain = true }))
  vim.bo[buf].modified = false
  pending[buf] = true

  local width = math.min(math.floor(vim.o.columns * 0.7), 100)
  local height = math.min(math.floor(vim.o.lines * 0.45), 18)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = require("core.skin").border(),
    title = " Commit Message ",
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

function M.submit(buf)
  if not pending[buf] then
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

  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.split(msg, "\n", { plain = true }), tmp)
  local out = vim.fn.system({ "git", "commit", "-F", tmp })
  vim.fn.delete(tmp)

  if vim.v.shell_error ~= 0 then
    notify_err("git commit failed:\n" .. out)
    require("core.banner").show("died", { subtitle = "git commit failed" })
    return
  end

  vim.bo[buf].modified = false
  pending[buf] = nil
  notify_info("Committed: " .. (msg:match("^([^\n]+)") or ""))
  require("core.banner").show("felled", { subtitle = msg:match("^([^\n]+)") })

  vim.schedule(function()
    pcall(vim.api.nvim_win_close, 0, true)
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end)
end

function M.open()
  if not git_ok({ "rev-parse", "--is-inside-work-tree" }) then
    return notify_err("Not inside a git repository.")
  end

  local staged, skipped = require("core.git").stage_related()
  if not staged then
    return notify_err("git add failed.")
  end
  if #skipped > 0 then
    vim.notify(
      "Left out of the commit: " .. table.concat(skipped, ", "),
      vim.log.levels.WARN,
      { title = "Commit" }
    )
  end
  if not has_staged() then
    return notify_info("Nothing to commit.")
  end

  local diff = staged_diff()
  if diff == "" then
    return notify_err("No staged diff to commit.")
  end

  if #diff > MAX_DIFF then
    diff = vim.trim(vim.fn.system({ "git", "diff", "--cached", "--stat" }))
      .. "\n\n[diff truncated — stat only]"
  end

  local log = recent_log()
  local branch = branch_name()

  vim.ui.input({ prompt = "Vibe? (optional, Enter to skip): " }, function(vibe)
    if vibe == nil then
      return
    end -- user hit <Esc>
    vibe = vim.trim(vibe)

    local vibe_line = vibe ~= ""
        and ('The user set the vibe: "' .. vibe .. '". Let that flavor the personality of the message.')
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
      open_editor(vim.trim(res.stdout))
    end)
  end)
end

return M
