-- Merge conflicts fight back: a buffer with conflict markers stages the conflict boss on the
-- boss bar, every conflict you resolve lands a hit and the last one fells it.
local actions = require("core.conflicts.actions")

local M = {}

-- conflicted files per repo root, refreshed in the background on enter and on write
local unmerged = {}
local staged = {}

local function words()
  return require("core.franchise").current().conflict
end

local function root_of(buf)
  return vim.fs.root(buf, ".git")
end

-- a conflict only exists while git is in the middle of something, a stat costs nothing next to
-- spawning git on every BufEnter
local function merging(root)
  local dotgit = root .. "/.git"
  local stat = vim.uv.fs_stat(dotgit)
  if not stat then
    return false
  end
  local dir = dotgit
  -- a worktree's .git is a file naming the real git directory
  if stat.type == "file" then
    local ok, lines = pcall(vim.fn.readfile, dotgit, "", 1)
    dir = require("core.repos.actions").gitdir_from_file(ok and lines[1] or nil, root) or dotgit
  end
  for _, name in ipairs(actions.IN_PROGRESS) do
    if vim.uv.fs_stat(dir .. "/" .. name) then
      return true
    end
  end
  return false
end

local function count_unmerged(root)
  if not merging(root) then
    unmerged[root] = nil
    return
  end
  vim.system(
    { "git", "-C", root, "diff", "--name-only", "--diff-filter=U" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        unmerged[root] = actions.unmerged_files(result.stdout)
      end
    end)
  )
end

--- Stages, updates or ends the conflict fight of a buffer from the markers it holds.
---@param buf integer
function M.refresh(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local count = actions.count_markers(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  if count == 0 and not staged[buf] then
    return
  end
  local root = root_of(buf)
  local files = root and unmerged[root] or 1
  local was_staged = staged[buf]
  staged[buf] = count > 0 or nil
  require("core.boss").stage(buf, {
    name = actions.boss_name(words(), files),
    count = count,
  })
  if was_staged and count == 0 then
    require("core.voice").say("conflicts_cleared")
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_conflicts", { clear = true })
  -- a merge writes the markers from outside, so a reload is when they show up
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FileChangedShellPost" }, {
    group = group,
    callback = function(ev)
      local root = root_of(ev.buf)
      if root then
        count_unmerged(root)
      end
      M.refresh(ev.buf)
    end,
  })
  -- resolving a conflict is an edit, not a diagnostic, so a fight on screen follows the text
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = group,
    callback = function(ev)
      if staged[ev.buf] then
        M.refresh(ev.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      staged[ev.buf] = nil
    end,
  })
end

return M
