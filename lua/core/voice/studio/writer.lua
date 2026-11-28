-- Asks Claude (headless, subscription) for fresh takes in a role's voice, from its voice sheet and
-- the takes it already has, and keeps them in the studio's library.
local store = require("core.voice.studio.store")
local writer = require("core.voice.studio.actions.writer")

local M = {}

local writing = false

local function sheet(franchise, character)
  local path = ("%s/docs/voices/%s.md"):format(require("core.utils").root(), franchise)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and writer.sheet_section(table.concat(lines, "\n"), character) or nil
end

-- every take a moment already has, banned ones too, so a paraphrase of any never joins
local function known(role, fresh)
  local all = {}
  for _, moment in ipairs(role.order) do
    all[moment] = vim.list_extend(vim.deepcopy(role.takes[moment] or {}), fresh[moment] or {})
    vim.list_extend(all[moment], role.banned or {})
  end
  return all
end

---Whether a run is on its way, so two never ask for the same moments.
---@return boolean
function M.busy()
  return writing
end

---Asks Claude for one fresh take per moment for the role's moments with the fewest, and adds the
---answer to the library.
---@param role { key: string, franchise: string, character: string, world: string, bond?: string, voice?: string, takes: table<string, string[]>, banned: string[], order: string[] }
---@param cb fun(added: integer) called on the main loop with how many takes joined the library
function M.write(role, cb)
  if writing then
    return cb(0)
  end
  writing = true
  local fresh = store.library()[role.key] or {}
  local moments = writer.moments_to_write(role.order, fresh, writer.MOMENTS_PER_RUN)
  local prompt = writer.prompt({
    character = role.character,
    world = role.world,
    sheet = sheet(role.franchise, role.character),
    bond = role.bond,
    moments = moments,
    takes = role.takes,
    fresh = fresh,
    banned = role.banned,
  })
  require("core.claude").run(prompt, function(res)
    writing = false
    local new = res.code == 0 and writer.parse(res.stdout, moments, known(role, fresh)) or {}
    if vim.tbl_isempty(new) then
      return cb(0)
    end
    local library = store.library()
    library[role.key] = writer.merge(library[role.key], new, function(take)
      return role.voice ~= nil and store.cached(role.voice, take) ~= nil
    end)
    store.save_library(library)
    cb(vim.tbl_count(new))
  end, { quiet = true })
end

return M
