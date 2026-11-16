-- :Trial runs the project's tests in the background and lets the banner announce the verdict.
local actions = require("core.trial.actions")

local M = {}

-- what the franchise says while the tests run, see the trial.* keys in lua/core/franchise/lines.lua
local function say(key, vars)
  return require("core.franchise").line("trial." .. key, vars)
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = say("title"), id = "eldentree_trial" })
end

function M.run()
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local cmd = vim.g.eldentree_trial_cmd
    or actions.detect(function(file)
      return vim.uv.fs_stat(root .. "/" .. file) ~= nil
    end)
  if not cmd then
    return notify("No test suite found in " .. root, vim.log.levels.WARN)
  end

  local task = require("core.progress").start({
    id = "eldentree_trial",
    title = say("title"),
    message = say("facing", { command = table.concat(cmd, " ") }),
  })
  vim.system(
    cmd,
    { cwd = root, text = true },
    vim.schedule_wrap(function(result)
      local output = (result.stdout or "") .. (result.stderr or "")
      if result.code == 0 then
        task:done(say("passed"))
        require("core.banner").show("felled", { subtitle = say("won") })
        require("core.voice").say("trial_passed")
      else
        task:fail(actions.tail(output, 15))
        require("core.banner").show("died", { subtitle = say("lost") })
        require("core.voice").say("trial_failed")
      end
    end)
  )
end

function M.setup()
  vim.api.nvim_create_user_command("Trial", M.run, { desc = "Run the project's tests" })
end

return M
