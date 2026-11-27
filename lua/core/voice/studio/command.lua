-- :Voice, the studio's controls: status, live or local, write fresh takes now, export and import.
local M = {}

M.SUBCOMMANDS = { "status", "live", "local", "write", "prune", "export", "import" }

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Voice studio" })
end

local function write()
  notify("Asking Claude for fresh takes…")
  require("core.voice.studio").write_now(function(added)
    notify(
      added > 0 and ("%d fresh takes joined the role"):format(added) or "No fresh takes came back"
    )
  end)
end

local HANDLERS = {
  status = function()
    notify(table.concat(require("core.voice.studio").status(), "\n"))
  end,
  live = function()
    require("core.voice.studio").set_mode("live")
    notify("Live: new takes are voiced through Fish Audio")
  end,
  ["local"] = function()
    require("core.voice.studio").set_mode("local")
    notify("Local: only cached takes play, Fish Audio is never called")
  end,
  write = write,
  prune = function(arg)
    local prune = require("core.voice.studio.prune")
    if arg == "all" then
      prune.all()
      return notify("Cache emptied, recorded clips kept")
    end
    notify(("Pruned %d takes nobody needs"):format(prune.run()))
  end,
  export = function(arg)
    require("core.voice.studio.archive").export(arg)
  end,
  import = function(arg)
    require("core.voice.studio.archive").import(arg)
  end,
}

local function run(cmd)
  local name, arg = cmd.args:match("^(%S*)%s*(.-)$")
  local handler = HANDLERS[name ~= "" and name or "status"]
  if not handler then
    return notify("Unknown :Voice " .. name, vim.log.levels.WARN)
  end
  handler(arg)
end

---Registers :Voice.
function M.setup()
  vim.api.nvim_create_user_command("Voice", run, {
    nargs = "*",
    complete = function(lead, line)
      if line:match("^%S+%s+%S+%s") then
        return vim.fn.getcompletion(lead, "file")
      end
      return M.SUBCOMMANDS
    end,
    desc = "The voice studio: status, live, local, write, prune, export, import",
  })
end

return M
