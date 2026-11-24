-- Guards what keeps startup fast, since the specs never start the real config
local later = require("core.later.actions")

local function read(path)
  return table.concat(vim.fn.readfile(path), "\n")
end

local function plugin_specs()
  local text = {}
  for _, path in ipairs(vim.fn.glob("lua/plugins/*.lua", false, true)) do
    table.insert(text, read(path))
  end
  return table.concat(text, "\n")
end

-- the plugin that owns each VeryLazy event: the closest spec name written above it
local function very_lazy_owners(text)
  local owners = {}
  for before in text:gmatch('(.-)event = "VeryLazy"') do
    local last
    for name in before:gmatch('\n%s*"[%w_.-]+/([%w_.-]+)",') do
      last = name
    end
    table.insert(owners, last)
  end
  return owners
end

describe("startup", function()
  it("turns on the bytecode cache before Claire's first require", function()
    local init = read("init.lua")
    local loader = init:find("vim.loader.enable()", 1, true)
    assert.is_not_nil(loader)
    assert.is_true(loader < init:find("require(", 1, true))
  end)

  it("keeps VeryLazy for what Malenia sees in the first frame", function()
    assert.same({ "lualine.nvim", "bufferline.nvim" }, very_lazy_owners(plugin_specs()))
  end)

  it("queues only plugins Inde actually has a spec for", function()
    local text = plugin_specs()
    for _, name in ipairs(later.PLUGINS) do
      local found = text:find("/" .. name .. '"', 1, true)
        or text:find('name = "' .. name .. '"', 1, true)
      assert.is_truthy(found, name)
    end
  end)
end)
