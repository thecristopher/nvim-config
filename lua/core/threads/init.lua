-- The open review threads of the branch's PR, left at the end of the lines they talk about.
-- <leader>mc lists them, <leader>mo opens the conversation on the cursor line and <leader>mr
-- resolves it on GitHub. Asked to gh in the background the first time a repo file opens.
local actions = require("core.threads.actions")

local M = {}

local ns = vim.api.nvim_create_namespace("eldentree_threads")
-- open threads per repo root, false while a repo is known to have no PR
local cache = {}
-- callbacks waiting on the answer of a fetch already out, per repo root
local fetching = {}
-- uv.now() of each repo's last answer, so the threads are asked again once they are old
local fetched_at = {}

local function words()
  return require("core.franchise").current().threads
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = words().title })
end

local function define_highlights()
  local p = require("core.themes").palette()
  vim.api.nvim_set_hl(0, "EldenThread", { fg = p.sapphire, italic = true })
end

local function locate(buf)
  if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
    return nil
  end
  local root = vim.fs.root(buf, ".git")
  if not root then
    return nil
  end
  root = vim.fs.normalize(root)
  local path = require("core.messages.actions").relative(
    root,
    vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  )
  return root, path
end

local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local root, path = locate(buf)
  if not root or not path or not cache[root] then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  for _, thread in ipairs(actions.for_file(cache[root], path)) do
    if thread.line and thread.line <= line_count then
      vim.api.nvim_buf_set_extmark(buf, ns, thread.line - 1, 0, {
        virt_text = { { "  󰍩 " .. actions.preview(thread), "EldenThread" } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
    end
  end
end

local function render_repo(root)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and locate(buf) == root then
      render(buf)
    end
  end
  require("core.utils").refresh_statusline()
  -- the explorer marks the files with open threads, see core/tree
  vim.api.nvim_exec_autocmds("User", { pattern = "EldentreeThreads", modeline = false })
end

--- The open threads of a repo's PR as last fetched, nil until asked or when it has no PR.
---@param root string repo root
---@return table[]|nil
function M.open_threads(root)
  return cache[root] or nil
end

local function gh(args, root, on_done)
  vim.system(
    vim.list_extend({ "gh" }, args),
    { cwd = root, text = true },
    vim.schedule_wrap(on_done)
  )
end

local function query_threads(root, number, on_done)
  gh({ "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner" }, root, function(repo)
    local owner, name = actions.split_repo(repo.stdout)
    if not owner then
      return on_done(nil, "gh could not tell which repo this is")
    end
    local args = { "api", "graphql", "-f", "query=" .. actions.QUERY }
    vim.list_extend(
      args,
      { "-F", "owner=" .. owner, "-F", "name=" .. name, "-F", "number=" .. number }
    )
    gh(args, root, function(result)
      if result.code ~= 0 then
        return on_done(nil, vim.trim(result.stderr or ""))
      end
      on_done(actions.parse(result.stdout))
    end)
  end)
end

--- Asks GitHub for the open threads of the branch's PR and leaves them on their lines.
---@param root string repo root
---@param on_done? fun(threads: table[]|nil, err: string|nil, no_pr: boolean|nil) no_pr is true when the branch has no PR
function M.fetch(root, on_done)
  on_done = on_done or function() end
  if vim.fn.executable("gh") ~= 1 then
    return on_done(nil, "gh is not available")
  end
  -- a fetch already out answers everyone who asks meanwhile, :Threads right after opening a file
  -- waits for the one the file started instead of failing
  if fetching[root] then
    return table.insert(fetching[root], on_done)
  end
  fetching[root] = { on_done }
  local function answer(threads, err, no_pr)
    local waiting = fetching[root] or {}
    fetching[root] = nil
    for _, callback in ipairs(waiting) do
      callback(threads, err, no_pr)
    end
  end
  gh({ "pr", "view", "--json", "number", "-q", ".number" }, root, function(pr)
    local number = pr.code == 0 and tonumber(vim.trim(pr.stdout or ""))
    if not number then
      cache[root], fetched_at[root] = false, vim.uv.now()
      render_repo(root)
      return answer(nil, nil, true)
    end
    query_threads(root, number, function(threads, err)
      if threads then
        cache[root], fetched_at[root] = threads, vim.uv.now()
        render_repo(root)
      end
      answer(threads, err)
    end)
  end)
end

--- Lists the open threads of the branch's PR, picking one jumps to its line.
function M.pick()
  local root = locate(0) or require("core.repos").root()
  if not root then
    return notify("Not inside a repo", vim.log.levels.WARN)
  end
  root = vim.fs.normalize(root)
  local task = require("core.progress").start({
    id = "eldentree_threads",
    title = words().title,
    message = "Asking GitHub for the open threads…",
  })
  M.fetch(root, function(threads, err, no_pr)
    if err then
      return task:fail(err)
    end
    if no_pr then
      return task:done(words().no_pr)
    end
    if not threads or #threads == 0 then
      return task:done(words().none)
    end
    task:done(("%d open"):format(#threads))
    Snacks.picker({
      title = words().title,
      items = vim.tbl_map(function(thread)
        return {
          text = thread.author .. " " .. thread.body .. " " .. thread.path,
          file = root .. "/" .. thread.path,
          pos = { thread.line or 1, 0 },
          preview_text = actions.preview(thread),
          where = ("%s:%d"):format(thread.path, thread.line or 0),
        }
      end, threads),
      format = function(item)
        return {
          { "󰍩 ", "EldenThread" },
          { item.preview_text, "SnacksPickerFile" },
          { "  " .. item.where, "SnacksPickerDir" },
        }
      end,
    })
  end)
end

--- Asks GitHub again for a repo's threads, a little later (after a push or a new PR, GitHub
--- needs a moment) or right away.
---@param root string|nil repo root, the current project when nil
---@param delay_ms integer|nil
function M.refresh(root, delay_ms)
  root = root or require("core.repos").root()
  if not root or vim.g.eldentree_threads == false then
    return
  end
  root = vim.fs.normalize(root)
  vim.defer_fn(function()
    M.fetch(root)
  end, delay_ms or 0)
end

--- How many review threads are still open in a repo, nil while unknown or without a PR.
---@param root string|nil repo root, the current project when nil
---@return integer|nil
function M.count(root)
  root = root or require("core.repos").root()
  local threads = root and cache[vim.fs.normalize(root)]
  return threads and #threads or nil
end

--- The statusline piece: the thread glyph and how many are open, empty when none are.
---@return string
function M.statusline()
  local root = locate(0) or require("core.repos").root()
  local open = M.count(root)
  if not open or open == 0 then
    return ""
  end
  return ("%%#EldenThread#%s %d%%*"):format(require("core.skin").current().tree.thread, open)
end

--- Moves the cursor to the next or previous open thread in the buffer.
---@param direction 1|-1
function M.jump(direction)
  local root, path = locate(0)
  local threads = root and cache[root]
  if not threads then
    return
  end
  local line = actions.neighbor(threads, path, vim.api.nvim_win_get_cursor(0)[1], direction)
  if line then
    vim.api.nvim_win_set_cursor(0, { line, 0 })
  end
end

local function thread_here()
  local root, path = locate(0)
  local threads = root and cache[root]
  if not threads then
    return nil
  end
  return actions.at(threads, path, vim.api.nvim_win_get_cursor(0)[1]), root
end

--- Opens the whole conversation of the thread on the cursor line.
function M.open()
  local thread = thread_here()
  if not thread then
    return notify("No open thread on this line")
  end
  local lines = actions.conversation(thread)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  local width = math.min(80, vim.o.columns - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(#lines + 1, 20),
    style = "minimal",
    border = require("core.skin").border(),
    title = " " .. require("core.skin").title(words().title) .. " ",
  })
  vim.wo[win].wrap = true
  vim.keymap.set("n", "q", function()
    pcall(vim.api.nvim_win_close, win, true)
  end, { buffer = buf, nowait = true })
end

--- Resolves the thread on the cursor line on GitHub, after asking.
function M.resolve()
  local thread, root = thread_here()
  if not thread then
    return notify("No open thread on this line")
  end
  vim.ui.select({ "Resolve", "Keep it open" }, {
    prompt = ("Resolve %s's thread on GitHub?"):format(thread.author),
  }, function(choice)
    if choice ~= "Resolve" then
      return
    end
    local args =
      { "api", "graphql", "-f", "query=" .. actions.RESOLVE, "-F", "thread=" .. thread.id }
    gh(args, root, function(result)
      if result.code ~= 0 then
        return notify(vim.trim(result.stderr or ""), vim.log.levels.ERROR)
      end
      cache[root] = vim.tbl_filter(function(other)
        return other.id ~= thread.id
      end, cache[root])
      render_repo(root)
      notify(words().resolved)
    end)
  end)
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("eldentree_threads", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = define_highlights })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(ev)
      local root = locate(ev.buf)
      if not root then
        return
      end
      if cache[root] == nil and vim.g.eldentree_threads ~= false then
        return M.fetch(root)
      end
      render(ev.buf)
    end,
  })
  -- coming back to nvim is when a review that landed meanwhile should show up
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      local root = locate(0) or require("core.repos").root()
      root = root and vim.fs.normalize(root)
      if root and cache[root] ~= nil and actions.stale(fetched_at[root], vim.uv.now()) then
        M.refresh(root)
      end
    end,
  })
  vim.keymap.set("n", "]r", function()
    M.jump(1)
  end, { desc = "Next review thread" })
  vim.keymap.set("n", "[r", function()
    M.jump(-1)
  end, { desc = "Previous review thread" })
  vim.api.nvim_create_user_command("Threads", M.pick, { desc = "Open review threads of the PR" })
end

return M
