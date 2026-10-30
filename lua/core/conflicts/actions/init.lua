-- Merge conflicts as a boss fight: how many conflicts a buffer still holds and what the boss is
-- called while the repo keeps more conflicted files. Pure logic only.
local M = {}

--- Counts the conflicts left in a buffer, one per opening marker.
---@param lines string[]
---@return integer
function M.count_markers(lines)
  local count = 0
  for _, line in ipairs(lines) do
    if line == "<<<<<<<" or line:sub(1, 8) == "<<<<<<< " then
      count = count + 1
    end
  end
  return count
end

--- Counts the conflicted files `git diff --name-only --diff-filter=U` printed.
---@param stdout string|nil
---@return integer
function M.unmerged_files(stdout)
  return #vim.split(stdout or "", "\n", { trimempty = true })
end

--- Names the boss, with the conflicted files the repo still holds beside it.
---@param words { boss: string, left: string } the franchise's conflict words
---@param files_left integer conflicted files in the repo, this one included
---@return string
function M.boss_name(words, files_left)
  if files_left <= 1 then
    return words.boss
  end
  return ("%s  ·  %s"):format(words.boss, words.left:format(files_left))
end

return M
