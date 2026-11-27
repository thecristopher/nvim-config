-- Packs the studio's audio and fresh takes into one file to carry to another machine, and unpacks
-- one here without losing anything already cached.
local store = require("core.voice.studio.store")
local writer = require("core.voice.studio.actions.writer")

local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Voice studio" })
end

---The file an export writes when none is named: the desktop, dated.
---@return string
function M.default_target()
  return vim.fn.expand(("~/Desktop/eldentree-voices-%s.tar.gz"):format(os.date("%Y-%m-%d")))
end

---Packs every voice's audio and the fresh takes into a .tar.gz.
---@param target string|nil where to write it, the desktop when nil
function M.export(target)
  target = vim.fn.expand(target and target ~= "" and target or M.default_target())
  local root = store.root()
  if vim.fn.isdirectory(root) == 0 then
    return notify("Nothing to export yet, no take has been voiced", vim.log.levels.WARN)
  end
  local command = { "tar", "-czf", target, "-C", vim.fn.fnamemodify(root, ":h"), "voices" }
  vim.system(command, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return notify("Export failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
      end
      notify("Voices exported to " .. target)
    end)
  end)
end

-- copies every file of an unpacked voice folder that is not cached here yet
local function copy_missing(from, to)
  local copied = 0
  for name, kind in vim.fs.dir(from, { depth = 2 }) do
    local target = to .. "/" .. name
    if kind == "file" and name:match("%.mp3$") and not vim.uv.fs_stat(target) then
      vim.fn.mkdir(vim.fn.fnamemodify(target, ":h"), "p")
      vim.uv.fs_copyfile(from .. "/" .. name, target)
      copied = copied + 1
    end
  end
  return copied
end

local function join_library(unpacked)
  local ok, lines = pcall(vim.fn.readfile, unpacked .. "/lines.json")
  local decoded, incoming = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  if decoded and type(incoming) == "table" then
    store.save_library(writer.join(store.library(), incoming))
  end
end

---Unpacks an export here: audio not cached yet is copied in, fresh takes join the library.
---@param source string the .tar.gz an export wrote
function M.import(source)
  source = vim.fn.expand(source or "")
  if not vim.uv.fs_stat(source) then
    return notify("No export at " .. source, vim.log.levels.WARN)
  end
  local scratch = vim.fn.tempname()
  vim.fn.mkdir(scratch, "p")
  vim.system({ "tar", "-xzf", source, "-C", scratch }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return notify("Import failed: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
      end
      vim.fn.mkdir(store.root(), "p")
      local copied = copy_missing(scratch .. "/voices", store.root())
      join_library(scratch .. "/voices")
      vim.fn.delete(scratch, "rf")
      notify(("Imported %d takes"):format(copied))
    end)
  end)
end

return M
