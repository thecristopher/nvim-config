-- What a closed fold says: its first line in full syntax color, then how many lines sleep inside.
local M = {}

--- Returns the tally shown after a closed fold.
---@param hidden integer lines inside the fold
---@return string
function M.suffix(hidden)
  return ("  󰁂 %d %s "):format(hidden, hidden == 1 and "line" or "lines")
end

--- Builds nvim-ufo virtual text: the fold's first line cut to fit, followed by the tally.
---@param virt_text table[] chunks of { text, hl } ufo hands over for the first line
---@param hidden integer lines inside the fold
---@param width integer room in the window
---@param truncate fun(text: string, width: integer): string ufo's display width aware cutter
---@return table[] chunks
function M.fold_chunks(virt_text, hidden, width, truncate)
  local suffix = M.suffix(hidden)
  local room = width - vim.fn.strdisplaywidth(suffix)
  local chunks, used = {}, 0
  for _, chunk in ipairs(virt_text) do
    local text, hl = chunk[1], chunk[2]
    local text_width = vim.fn.strdisplaywidth(text)
    if used + text_width > room then
      table.insert(chunks, { truncate(text, room - used), hl })
      break
    end
    table.insert(chunks, chunk)
    used = used + text_width
  end
  table.insert(chunks, { suffix, "UfoFoldedEllipsis" })
  return chunks
end

return M
