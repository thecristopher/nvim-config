-- Figures out how a project runs its tests, so :Trial works without being told.
local M = {}

-- checked in order, the first file that exists decides the command
M.RUNNERS = {
  { file = "scripts/test.sh", cmd = { "./scripts/test.sh" } },
  { file = "package.json", cmd = { "npm", "test", "--silent" } },
  { file = "Cargo.toml", cmd = { "cargo", "test" } },
  { file = "go.mod", cmd = { "go", "test", "./..." } },
  { file = "pyproject.toml", cmd = { "pytest", "-q" } },
  { file = "Makefile", cmd = { "make", "test" } },
}

function M.detect(exists)
  for _, runner in ipairs(M.RUNNERS) do
    if exists(runner.file) then
      return runner.cmd
    end
  end
  return nil
end

-- the tail of the output is where test runners put the verdict
function M.tail(output, count)
  local lines = vim.split(vim.trim(output or ""), "\n", { plain = true })
  return table.concat(vim.list_slice(lines, math.max(1, #lines - count + 1)), "\n")
end

return M
