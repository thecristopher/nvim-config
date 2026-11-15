-- Trims trailing whitespace on save, but only on the lines that changed since the file was last
-- written, so saving a legacy file never drags untouched lines into the diff.
local actions = require("core.whitespace.actions")

local M = {}

M.EXCLUDED_FILETYPES = { markdown = true, diff = true }

local diff = vim.text and vim.text.diff or vim.diff

local function lines_on_disk(buf, name)
  local lines = vim.fn.readfile(name)
  if vim.bo[buf].fileformat == "dos" then
    return actions.strip_carriage_returns(lines)
  end
  return lines
end

local function changed_ranges(buf, lines)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.fn.filereadable(name) == 0 then
    return { { 1, #lines } }
  end
  local before = table.concat(lines_on_disk(buf, name), "\n") .. "\n"
  local after = table.concat(lines, "\n") .. "\n"
  return actions.changed_ranges(diff(before, after, { result_type = "indices" }))
end

--- Trims the changed lines of a buffer in place.
---@param buf integer
function M.trim_changed(buf)
  if vim.bo[buf].buftype ~= "" or M.EXCLUDED_FILETYPES[vim.bo[buf].filetype] then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, range in ipairs(changed_ranges(buf, lines)) do
    for row = range[1], range[2] do
      local trimmed = actions.trim(lines[row])
      if trimmed ~= lines[row] then
        vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { trimmed })
      end
    end
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("eldentree_strip_whitespace", { clear = true }),
    callback = function(ev)
      M.trim_changed(ev.buf)
    end,
  })
end

return M
