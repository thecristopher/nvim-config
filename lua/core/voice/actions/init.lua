local M = {}

-- every moment a character speaks up for, :checkhealth asks each region for all of them
-- holes: {branch} for ci, pushed and committed, {boss} for boss_felled, {number} for pr_opened
M.MOMENTS = {
  "trial_passed",
  "trial_failed",
  "ci_passed",
  "ci_failed",
  "pushed",
  "boss_felled",
  "committed",
  "pr_opened",
  "region_arrived",
  "morning",
  "conflicts_cleared",
  "woke",
}

---Picks one of the lines, never the one said last when there is another to say.
---@param lines string[]|nil
---@param roll number between 0 and 1, where in the list to land
---@param last string|nil the line said last time
---@return string|nil
function M.pick(lines, roll, last)
  local fresh = vim.tbl_filter(function(line)
    return line ~= last
  end, lines or {})
  if #fresh == 0 then
    fresh = lines or {}
  end
  if #fresh == 0 then
    return nil
  end
  return fresh[math.min(#fresh, math.floor(roll * #fresh) + 1)]
end

---Tells whether today's first greeting is still due, from the day the last one was said.
---@param said_on string|nil the day of the last greeting, as YYYY-MM-DD
---@param today string as YYYY-MM-DD
---@return boolean
function M.morning_due(said_on, today)
  return vim.trim(said_on or "") ~= today
end

---Fills the {name} holes of a line, leaving the ones it has no value for.
---@param line string
---@param vars table<string, string>|nil
---@return string
function M.fill(line, vars)
  return (line:gsub("{(%w+)}", function(key)
    return vars and vars[key] or nil
  end))
end

---The line the character of a region says for a moment, nil when they have nothing for it.
---@param voices table|nil lines by region name, then by moment
---@param region string region name
---@param moment string like trial_passed or pushed
---@param roll number between 0 and 1
---@param last string|nil the line said last time
---@return string|nil
function M.line(voices, region, moment, roll, last)
  local lines = ((voices or {})[region] or {})[moment]
  return M.pick(lines, roll, last)
end

return M
