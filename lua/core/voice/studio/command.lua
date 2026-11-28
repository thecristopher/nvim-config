-- :Voice, the studio's controls: status, live or local, write fresh takes now, what was said last,
-- ban it, prune, export and import.
local M = {}

M.SUBCOMMANDS = { "status", "live", "local", "write", "last", "ban", "prune", "export", "import" }

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

local function last()
  local said = require("core.voice").last()
  if not said then
    return notify("Nobody has said anything yet")
  end
  local take = require("core.voice.studio").last()
  local lines = {
    ("%s at %s, %s:"):format(said.character, said.moment, said.spoke and "out loud" or "written"),
    said.line,
  }
  if take and take.line and require("core.voice.studio.actions").plain(take.line) == said.line then
    vim.list_extend(lines, { "", "Take: " .. take.take, "Ban it with :Voice ban" })
  end
  notify(table.concat(lines, "\n"))
end

local function ban()
  local take = require("core.voice.studio").ban_last()
  if not take then
    return notify("No studio take to ban yet", vim.log.levels.WARN)
  end
  notify("Banned, it will never be said again:\n" .. take)
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
  last = last,
  ban = ban,
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
    desc = "The voice studio: status, live, local, write, last, ban, prune, export, import",
  })
end

return M
