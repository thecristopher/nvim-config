-- Pure pieces of the PR review: argument parsing, picker rows, diff trimming and the prompt.
local M = {}

M.MAX_DIFF = 60000

-- accepts 42, "42", "#42" or a full GitHub PR url
function M.parse_number(arg)
  if type(arg) == "number" then return arg end
  if type(arg) ~= "string" then return nil end
  local trimmed = vim.trim(arg)
  local from_url = trimmed:match("/pull/(%d+)")
  if from_url then return tonumber(from_url) end
  return tonumber(trimmed:match("^#?(%d+)$"))
end

function M.picker_items(prs)
  local items = {}
  for _, pr in ipairs(prs or {}) do
    local author = pr.author and pr.author.login or "?"
    items[#items + 1] = {
      text   = ("#%d  %s  (%s, %s)"):format(pr.number, pr.title, author, pr.headRefName or "?"),
      number = pr.number,
    }
  end
  return items
end

-- huge diffs blow past what claude reads well, so keep the head and say what got cut
function M.trim_diff(diff, max)
  max = max or M.MAX_DIFF
  if #diff <= max then return diff end
  return diff:sub(1, max) .. ("\n\n[diff truncated: showing %d of %d characters]"):format(max, #diff)
end

function M.build_prompt(pr, diff, lang)
  local author = pr.author and pr.author.login or "unknown"
  return table.concat({
    ("Analyze GitHub pull request #%d so a reviewer can understand it fast."):format(pr.number),
    ("Write the whole analysis in %s."):format(lang or "Spanish"),
    "Be concrete and specific to this diff. Skip generic review advice.",
    "Em dashes are never allowed anywhere.",
    "",
    "Use exactly these markdown sections:",
    "## Resumen",
    "<2 to 3 sentences: what the PR does and why>",
    "## Cambios",
    "- <each meaningful change, grouped by area, naming the files involved>",
    "## Riesgos",
    "- <possible bugs, edge cases, breaking changes or missing tests; say 'Nada relevante' if none>",
    "## Qué revisar",
    "- <the specific spots worth a careful look or a manual test>",
    "",
    "Translate the section headings too if the language is not Spanish.",
    "Respond with the markdown only, no preamble and no code fences around it.",
    "",
    ("Title: %s"):format(pr.title or ""),
    ("Author: %s"):format(author),
    ("Branches: %s -> %s"):format(pr.headRefName or "?", pr.baseRefName or "?"),
    ("Size: +%d -%d across %d files"):format(pr.additions or 0, pr.deletions or 0, pr.changedFiles or 0),
    "",
    "Description:",
    (pr.body and vim.trim(pr.body) ~= "") and pr.body or "(no description)",
    "",
    "Diff:",
    M.trim_diff(diff),
  }, "\n")
end

-- header the report opens with, so the float says which PR it is about before the analysis
function M.report_lines(pr, analysis)
  local lines = {
    ("# #%d %s"):format(pr.number, pr.title or ""),
    "",
    ("`%s` -> `%s`  ·  +%d -%d  ·  %d files"):format(
      pr.headRefName or "?", pr.baseRefName or "?",
      pr.additions or 0, pr.deletions or 0, pr.changedFiles or 0),
    pr.url or "",
    "",
  }
  vim.list_extend(lines, vim.split(vim.trim(analysis), "\n", { plain = true }))
  return lines
end

return M
