-- Pure money logic of the voice studio: what the paid model may spend today, when it falls back to
-- the free one, and the ledger that remembers it between sessions.
local M = {}

M.PAID = "drama-3"
M.FREE = "s2.1-pro-free"

-- dollars per million bytes of text, a little over what Drama 3 charged in testing so the ledger
-- never thinks it spent less than it did
M.PRICE_PER_MILLION = 15

M.DEFAULTS = {
  -- what the paid model may spend in a day before the free one takes over
  daily = 0.5,
  -- the prepaid balance the paid model never digs below
  floor = 0.5,
  -- times a day the studio asks Claude for fresh takes for one role
  writes = 3,
}

---What a take costs on the paid model.
---@param bytes integer length of the text sent
---@return number dollars
function M.cost(bytes)
  return bytes * M.PRICE_PER_MILLION / 1e6
end

---The ledger for today: the day's spend and writes start over on a new day, everything else stays.
---@param ledger table|nil as read from state
---@param today string as YYYY-MM-DD
---@return table
function M.rollover(ledger, today)
  local fresh = vim.deepcopy(ledger or {})
  fresh.mode = fresh.mode or "live"
  if fresh.day ~= today then
    fresh.day, fresh.spent, fresh.writes = today, 0, 0
  end
  local month = today:sub(1, 7)
  if fresh.month ~= month then
    fresh.month, fresh.month_spent = month, 0
  end
  return fresh
end

---Whether the paid model may voice a take today, and why not when it may not.
---@param ledger table rolled over to today
---@param bytes integer length of the take
---@param limits { daily: number, floor: number }
---@return boolean allowed
---@return string|nil reason
function M.paid_allowed(ledger, bytes, limits)
  if ledger.broke == ledger.day then
    return false, "out of credit"
  end
  local cost = M.cost(bytes)
  if (ledger.spent or 0) + cost > limits.daily then
    return false, "daily cap reached"
  end
  if ledger.balance and ledger.balance - cost < limits.floor then
    return false, "balance at the floor"
  end
  return true, nil
end

---The model that voices a take: the paid one while the budget allows, the free one otherwise.
---@param ledger table rolled over to today
---@param bytes integer
---@param limits { daily: number, floor: number }
---@return string
function M.model(ledger, bytes, limits)
  return M.paid_allowed(ledger, bytes, limits) and M.PAID or M.FREE
end

---Writes a paid take into the ledger, the balance going down with it until the wallet is read again.
---@param ledger table rolled over to today
---@param bytes integer
---@return table
function M.spend(ledger, bytes)
  local next = vim.deepcopy(ledger)
  local cost = M.cost(bytes)
  next.spent = (next.spent or 0) + cost
  next.month_spent = (next.month_spent or 0) + cost
  next.balance = next.balance and next.balance - cost or nil
  return next
end

---Whether the studio may ask Claude for fresh takes once more today.
---@param ledger table rolled over to today
---@param limits { writes: integer }
---@return boolean
function M.writer_due(ledger, limits)
  return (ledger.writes or 0) < limits.writes
end

---The limits in use: the defaults, with any the config sets over them.
---@param overrides { daily?: number, floor?: number, writes?: integer }|nil
---@return { daily: number, floor: number, writes: integer }
function M.limits(overrides)
  return vim.tbl_extend("force", M.DEFAULTS, overrides or {})
end

return M
