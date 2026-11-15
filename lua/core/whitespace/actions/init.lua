-- Pure steps behind trimming trailing whitespace only on the lines a save actually changed.
local M = {}

--- Turns diff hunks into the line ranges of the new text that were added or changed.
---@param hunks integer[][] from vim.text.diff with result_type "indices": { start_a, count_a, start_b, count_b }
---@return integer[][] ranges as { first, last }, 1 based and inclusive
function M.changed_ranges(hunks)
  local ranges = {}
  for _, hunk in ipairs(hunks) do
    local start_b, count_b = hunk[3], hunk[4]
    if count_b > 0 then
      table.insert(ranges, { start_b, start_b + count_b - 1 })
    end
  end
  return ranges
end

--- Drops the spaces and tabs at the end of a line.
---@param line string
---@return string
function M.trim(line)
  return (line:gsub("%s+$", ""))
end

--- Removes the carriage return readfile leaves on lines of a dos file, so they compare with the buffer.
---@param lines string[]
---@return string[]
function M.strip_carriage_returns(lines)
  return vim.tbl_map(function(line)
    return (line:gsub("\r$", ""))
  end, lines)
end

return M
