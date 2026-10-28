-- :Review [number] picks a PR, has Claude analyze its diff and opens the verdict in a float.
-- Inside the float, d opens the diff file by file and q closes it.
local actions = require("core.review.actions")

local M = {}

local PR_FIELDS =
  "number,title,body,author,baseRefName,headRefName,additions,deletions,changedFiles,url"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Review", id = "eldentree_review" })
end

local function gh(args, cb)
  vim.system(vim.list_extend({ "gh" }, args), { text = true }, vim.schedule_wrap(cb))
end

local function open_diff(number)
  local Diff = require("snacks.picker.source.diff")
  require("snacks").picker.pick({
    title = ("PR #%d diff"):format(number),
    format = "git_status",
    preview = "diff",
    finder = function(_, ctx)
      return Diff.diff(
        { cmd = "gh", args = { "pr", "diff", tostring(number), "--color=never" } },
        ctx
      )
    end,
  })
end

local function open_report(pr, analysis)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, actions.report_lines(pr, analysis))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local width, height = math.floor(vim.o.columns * 0.7), math.floor(vim.o.lines * 0.75)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = require("core.skin").border(),
    title = (" PR #%d  ·  d diff  ·  q close "):format(pr.number),
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close review" })
  vim.keymap.set("n", "d", function()
    open_diff(pr.number)
  end, { buffer = buf, desc = "Open PR diff" })
end

local function analyze(pr, diff, task)
  task:update(("Claude is reading PR #%d…"):format(pr.number))
  local prompt = actions.build_prompt(pr, diff, vim.g.eldentree_review_lang)
  require("core.claude").run(prompt, function(res)
    if res.code ~= 0 or vim.trim(res.stdout or "") == "" then
      return task:fail(
        "Claude could not analyze the PR: " .. vim.trim(res.stderr or "unknown error")
      )
    end
    task:done(("PR #%d analyzed"):format(pr.number))
    open_report(pr, res.stdout)
  end)
end

function M.review(number)
  local task = require("core.progress").start({
    id = "eldentree_review",
    title = "Review",
    message = ("Fetching PR #%d…"):format(number),
  })
  gh({ "pr", "view", tostring(number), "--json", PR_FIELDS }, function(view)
    if view.code ~= 0 then
      return task:fail(vim.trim(view.stderr or "gh pr view failed"))
    end
    local ok, pr = pcall(vim.json.decode, view.stdout)
    if not ok or type(pr) ~= "table" then
      return task:fail("Could not read the PR details from gh")
    end

    task:update(("Fetching the diff of PR #%d…"):format(number))
    gh({ "pr", "diff", tostring(number), "--color=never" }, function(diff)
      if diff.code ~= 0 or vim.trim(diff.stdout or "") == "" then
        return task:fail(
          vim.trim(diff.stderr or "") ~= "" and vim.trim(diff.stderr) or "This PR has no diff"
        )
      end
      analyze(pr, diff.stdout, task)
    end)
  end)
end

local function pick_pr()
  local task = require("core.progress").start({
    id = "eldentree_review",
    title = "Review",
    message = "Looking for open PRs…",
  })
  gh({
    "pr",
    "list",
    "--state",
    "open",
    "--limit",
    "50",
    "--json",
    "number,title,author,headRefName",
  }, function(res)
    if res.code ~= 0 then
      return task:fail(vim.trim(res.stderr or "gh pr list failed"))
    end
    local ok, prs = pcall(vim.json.decode, res.stdout)
    local items = actions.picker_items(ok and prs or {})
    if #items == 0 then
      task:done("No open PRs in this repo")
      return
    end
    task:done(("%d open PRs"):format(#items))

    require("snacks").picker.pick({
      title = "Review which PR?",
      items = items,
      format = "text",
      layout = { preset = "select" },
      confirm = function(picker, item)
        picker:close()
        if item then
          M.review(item.number)
        end
      end,
    })
  end)
end

function M.open(arg)
  if vim.fn.executable("gh") == 0 then
    return notify(
      "gh CLI not found. Install with: brew install gh && gh auth login",
      vim.log.levels.ERROR
    )
  end
  if arg and vim.trim(tostring(arg)) ~= "" then
    local number = actions.parse_number(arg)
    if not number then
      return notify("Not a PR number or url: " .. tostring(arg), vim.log.levels.ERROR)
    end
    return M.review(number)
  end
  pick_pr()
end

return M
