-- Turns the my-style guide into prompt lines, kept pure so it can be tested without touching disk.
local M = {}

M.FALLBACK = {
  "No style guide was found, so keep it clear, specific and human.",
}

---Drops the YAML frontmatter that slash commands carry, claude only needs the guide itself.
---@param text string raw markdown of the guide
---@return string body without frontmatter
function M.strip_frontmatter(text)
  local body = text:match("^%-%-%-\n.-\n%-%-%-\n(.*)$")
  return vim.trim(body or text)
end

---Builds the style section for a drafting prompt.
---@param guide string|nil raw guide contents, nil when the file is missing
---@return string[] prompt lines
function M.prompt_lines(guide)
  if not guide or vim.trim(guide) == "" then
    return M.FALLBACK
  end
  return {
    "Follow this style guide exactly. It is the only source of style rules:",
    "",
    M.strip_frontmatter(guide),
  }
end

return M
