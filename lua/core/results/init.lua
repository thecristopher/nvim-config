-- Keeps score of the run while you work, ranks it when you leave, and hands the last one to the hub.
-- The run's time is the time you were active: a gap of more than IDLE_GAP_MS between two signs of
-- life (a move, an edit, a focus) is a break and never counts, so a session left open overnight
-- does not turn into a twelve hour run.
local actions = require("core.results.actions")

local M = {}

local state_file = vim.fn.stdpath("state") .. "/eldentree_results.json"
local active_ms, last_seen = 0, vim.uv.now()
local run = { saves = 0, fixes = 0 }
local errors_by_buf = {}

--- Returns the run so far, with how long it has lasted.
---@return table run as { seconds, saves, fixes }
function M.current()
  local active = actions.active_after(active_ms, last_seen, vim.uv.now())
  return { seconds = math.floor(active / 1000), saves = run.saves, fixes = run.fixes }
end

local function touch()
  local now = vim.uv.now()
  active_ms = actions.active_after(active_ms, last_seen, now)
  last_seen = now
end

--- Returns the last finished run, nil before the first one.
---@return table|nil
function M.last()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  if not ok then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(decoded) == "table" and decoded or nil
end

--- Returns the hub line for the last run, nil when the franchise has no results screen.
---@return string|nil
function M.summary()
  local lore = require("core.franchise").current()
  local last = M.last()
  if not lore.mechanics.ranking or not last then
    return nil
  end
  return actions.summary(lore.words, last)
end

local function finish()
  local final = M.current()
  if not actions.worth_saving(final) then
    return
  end
  final.rank = actions.rank(final)
  require("core.utils").write_state(state_file, { vim.json.encode(final) })
  pcall(function()
    require("core.chronicle").record(final)
  end)
end

local function count_fixes(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local errors = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
  run.fixes = run.fixes + actions.fixed(errors_by_buf[buf], errors)
  errors_by_buf[buf] = errors
end

function M.setup()
  local group = vim.api.nvim_create_augroup("eldentree_results", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      touch()
      run.saves = run.saves + 1
    end,
  })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(ev)
      count_fixes(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev)
      errors_by_buf[ev.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd({
    "CursorMoved",
    "CursorMovedI",
    "TextChanged",
    "TextChangedI",
    "TextChangedT",
    "BufEnter",
    "FocusGained",
    "CmdlineEnter",
  }, { group = group, callback = touch })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = finish })
end

return M
