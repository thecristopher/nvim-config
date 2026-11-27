-- Talks to Fish Audio: voices a take into the cache and reads the prepaid balance, always in the
-- background so the editor never waits on the network.
local actions = require("core.voice.studio.actions")
local fish = require("core.voice.studio.actions.fish")

local M = {}

---Voices a take into a file. The audio lands in a temporary file first and only takes the cached
---name once Fish Audio answered with real audio, so a failure never leaves half a take behind.
---@param job { key: string, voice: string, model: string, text: string, out: string }
---@param cb fun(outcome: "ok"|"broke"|"failed") called on the main loop
function M.voice(job, cb)
  vim.fn.mkdir(vim.fn.fnamemodify(job.out, ":h"), "p")
  local partial = job.out .. ".part"
  local body = fish.body(actions.for_model(job.text, job.model), job.voice)
  local command = fish.tts_command(job.key, job.model, partial)
  local started = pcall(vim.system, command, { text = true, stdin = body }, function(res)
    local stat = vim.uv.fs_stat(partial)
    local outcome = fish.outcome(res.code, vim.trim(res.stdout or ""), stat and stat.size or 0)
    if outcome == "ok" then
      vim.uv.fs_rename(partial, job.out)
    else
      vim.uv.fs_unlink(partial)
    end
    vim.schedule(function()
      cb(outcome)
    end)
  end)
  if not started then
    vim.schedule(function()
      cb("failed")
    end)
  end
end

---Reads the prepaid balance.
---@param key string
---@param cb fun(balance: number|nil) called on the main loop
function M.balance(key, cb)
  local started = pcall(vim.system, fish.wallet_command(key), { text = true }, function(res)
    local balance = res.code == 0 and fish.balance(res.stdout) or nil
    vim.schedule(function()
      cb(balance)
    end)
  end)
  if not started then
    vim.schedule(function()
      cb(nil)
    end)
  end
end

return M
