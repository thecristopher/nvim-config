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

local function count_unmerged(root)
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
  staged[buf] = count > 0 or nil
  require("core.boss").stage(buf, {
    name = actions.boss_name(words(), files),
    count = count,
  })
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
