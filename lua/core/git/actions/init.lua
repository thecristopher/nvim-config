-- Pure helpers for the quick git shortcuts: branch names, status parsing and what to stage.
local M = {}

-- same prefixes the style guide asks branches to use
M.PREFIXES = { "feature", "bugfix", "hotfix", "refactor", "docs", "chore", "test" }

-- untracked files that are local noise or secrets, never part of a code change
M.UNRELATED = {
  "^%.env$",
  "^%.env%.",
  "%.pem$",
  "%.key$",
  "%.log$",
  "%.DS_Store$",
  "%.sw[po]$",
  "~$",
}

-- templates are meant to be committed even though they look like env files
local KEEP = { "%.example$", "%.sample$", "%.template$" }

---Turns free text into a git friendly slug.
---@param text string what the user typed
---@return string slug lowercase, words joined by hyphens
function M.slug(text)
  local slug = vim.trim(text or ""):lower()
  slug = slug:gsub("[%s_]+", "-")
  slug = slug:gsub("[^%w%-%./]", "")
  slug = slug:gsub("%-+", "-")
  slug = slug:gsub("^[%-/.]+", ""):gsub("[%-/.]+$", "")
  return slug
end

---Builds the branch name, keeping a prefix the user already typed.
---@param prefix string|nil one of PREFIXES, ignored when name has its own
---@param name string what the user typed
---@return string|nil branch nil when nothing usable is left
function M.branch_name(prefix, name)
  local slug = M.slug(name)
  if slug == "" then
    return nil
  end
  if slug:find("/", 1, true) or not prefix then
    return slug
  end
  return prefix .. "/" .. slug
end

---Parses `git status --porcelain=v1 -z` into entries.
---@param raw string NUL separated status output
---@return { code: string, path: string }[] entries in git's order
function M.parse_status(raw)
  local entries = {}
  local fields = vim.split(raw or "", "\0", { plain = true })
  local i = 1
  while i <= #fields do
    local field = fields[i]
    if #field > 3 then
      local code = field:sub(1, 2)
      entries[#entries + 1] = { code = code, path = field:sub(4) }
      -- renames and copies carry the old path as the next field
      if code:find("[RC]") then
        i = i + 1
      end
    end
    i = i + 1
  end
  return entries
end

local function matches_any(path, patterns)
  local name = vim.fs.basename(path)
  for _, pattern in ipairs(patterns) do
    if name:find(pattern) then
      return true
    end
  end
  return false
end

---Tells whether an untracked file looks like noise or a secret.
---@param path string repo relative path
---@return boolean
function M.is_unrelated(path)
  return matches_any(path, M.UNRELATED) and not matches_any(path, KEEP)
end

---Splits status entries into paths worth staging and paths to leave alone.
---Tracked changes always count, untracked files only when they are not noise.
---Entries already fully staged are left out, since there is nothing left to add.
---@param entries { code: string, path: string }[]
---@return string[] stage, string[] skipped
function M.related(entries)
  local stage, skipped = {}, {}
  for _, entry in ipairs(entries) do
    local untracked = entry.code == "??"
    -- a staged deletion is gone from disk and index, so `git add -- path` would abort the whole add
    local fully_staged = entry.code:sub(2, 2) == " "
    if untracked and M.is_unrelated(entry.path) then
      skipped[#skipped + 1] = entry.path
    elseif not fully_staged then
      stage[#stage + 1] = entry.path
    end
  end
  return stage, skipped
end

---Push arguments, setting the upstream the first time a branch goes out.
---@param has_upstream boolean
---@return string[] args for git
function M.push_args(has_upstream)
  if has_upstream then
    return { "push" }
  end
  return { "push", "-u", "origin", "HEAD" }
end

---Checkout arguments for a branch, tracking a remote one under its own name.
---@param branch string like "feature/map" or "remotes/origin/feature/map"
---@return string[] args for git
function M.checkout_args(branch)
  local remote_branch = branch:match("^remotes/[^/]+/(.+)$")
  if remote_branch then
    return { "switch", "-c", remote_branch, "--track", (branch:gsub("^remotes/", "")) }
  end
  return { "switch", branch }
end

---@class GitQuickKey
---@field key string pressed after <leader>g
---@field fn string function name in core.git
---@field desc string which-key description
---@field short string word shown in the terminal hint

-- one list feeds the keymaps, which-key and the terminal hint so they never drift apart
---@type GitQuickKey[]
M.QUICK_KEYS = {
  { key = "N", fn = "new_branch", desc = "New branch", short = "branch" },
  { key = "j", fn = "pull", desc = "Pull", short = "pull" },
  { key = "k", fn = "push", desc = "Push", short = "push" },
  { key = "m", fn = "sync", desc = "Merge base branch in", short = "merge" },
  { key = "M", fn = "home", desc = "Switch to base branch and pull", short = "base" },
  { key = "a", fn = "stage", desc = "Stage related changes", short = "stage" },
  { key = "z", fn = "stash", desc = "Stash changes", short = "stash" },
  { key = "Z", fn = "stash_pop", desc = "Pop stash", short = "pop" },
  { key = "u", fn = "undo_commit", desc = "Undo last commit (keep changes)", short = "undo" },
}

-- splits a unified diff into one chunk per file, each starting at its "diff --git" line
local function file_chunks(diff)
  local chunks, current = {}, nil
  for _, line in ipairs(vim.split(diff, "\n", { plain = true })) do
    if line:match("^diff %-%-git ") or not current then
      current = {}
      table.insert(chunks, current)
    end
    table.insert(current, line)
  end
  return chunks
end

-- keeps a file's first lines within its share of the budget, saying how many were left out
local function trim_chunk(lines, budget)
  local kept, size = {}, 0
  for index, line in ipairs(lines) do
    size = size + #line + 1
    if size > budget and index > 1 then
      table.insert(kept, ("[%d more lines of this file left out]"):format(#lines - index + 1))
      return kept
    end
    table.insert(kept, line)
  end
  return kept
end

---Fits a diff into a budget by giving every file an equal share, so a big file never pushes the
---others out of the prompt. A diff that already fits comes back whole.
---@param diff string unified diff
---@param budget integer characters
---@return string
function M.trim_diff(diff, budget)
  if #diff <= budget then
    return diff
  end
  local chunks = file_chunks(diff)
  local share = math.floor(budget / #chunks)
  local out = {}
  for _, chunk in ipairs(chunks) do
    vim.list_extend(out, trim_chunk(chunk, share))
  end
  return table.concat(out, "\n")
end

---Comment lines for the bottom of a commit draft, naming the files left out of it. git drops
---lines starting with # from the message, and so does the draft's submit.
---@param files string[]
---@return string[]
function M.left_out_comments(files)
  if #files == 0 then
    return {}
  end
  local lines = { "", "# Left out of this commit:" }
  for _, file in ipairs(files) do
    table.insert(lines, "#   " .. file)
  end
  return lines
end

---Winbar text listing the quick git keys, for terminals where <leader> only works after <Esc>.
---@param keys GitQuickKey[]
---@return string winbar statusline formatted, % escaped
function M.terminal_hint(keys)
  local parts = {}
  for _, entry in ipairs(keys) do
    parts[#parts + 1] = ("%%#Special#%s%%* %s"):format(entry.key, entry.short)
  end
  -- the trailing %< trims the last keys on narrow windows instead of the instructions
  return " %#Title# git%* %#Comment#<Esc> then <Space>g%*  " .. table.concat(parts, "  ") .. "%<"
end

return M
