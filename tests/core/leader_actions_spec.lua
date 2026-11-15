local actions = require("core.leader.actions")
local palette = require("core.palette.actions")

local function binding_keys()
  local keys = {}
  for _, binding in ipairs(actions.BINDINGS) do
    table.insert(keys, binding.key)
  end
  return keys
end

describe("BINDINGS", function()
  it("never binds the same key twice in the same mode", function()
    assert.same({}, actions.duplicates(actions.BINDINGS))
  end)

  it("never lets one key wait on the timeout for a longer one", function()
    assert.same({}, actions.waits(binding_keys()))
  end)

  it("gives every binding a description and exactly one way to run", function()
    for _, binding in ipairs(actions.BINDINGS) do
      assert.is_truthy(binding.desc ~= "", binding.key)
      assert.equal(1, #actions.kinds(binding), binding.key)
    end
  end)

  it("names a real module and function in every call", function()
    for _, binding in ipairs(actions.BINDINGS) do
      if binding.call then
        local module, fn = actions.parse_call(binding.call)
        assert.is_truthy(module and fn, binding.call)
      end
    end
  end)

  it("puts every key with two or more letters inside a group", function()
    for _, binding in ipairs(actions.BINDINGS) do
      if #binding.key > 1 and binding.key ~= "<leader>" then
        assert.is_truthy(actions.group_of(binding.key), binding.key)
      end
    end
  end)

  it("keeps plugin owned groups free of bindings made here", function()
    for _, binding in ipairs(actions.BINDINGS) do
      local group = actions.group_of(binding.key)
      assert.is_true(group == nil or group.owner ~= "plugins", binding.key)
    end
  end)
end)

describe("duplicates", function()
  it("catches Claire and Leon both claiming the same date", function()
    local bindings = { { key = "jh" }, { key = "jh" } }
    assert.same({ "n jh" }, actions.duplicates(bindings))
  end)

  it("lets the same key live in normal and visual mode", function()
    assert.same({}, actions.duplicates({ { key = "cp" }, { key = "cp", mode = "x" } }))
  end)
end)

describe("waits", function()
  it("spots a single key that would make a longer one wait", function()
    assert.same({ "g < gg" }, actions.waits({ "g", "gg" }))
  end)

  it("stays quiet when Malenia and Inde never share a prefix", function()
    assert.same({}, actions.waits({ "jh", "jm" }))
  end)
end)

describe("parse_call", function()
  it("splits the module from the function", function()
    local module, fn = actions.parse_call("core.hud:open")
    assert.equal("core.hud", module)
    assert.equal("open", fn)
  end)

  it("rejects a call without a function", function()
    assert.is_nil(actions.parse_call("core.hud"))
  end)
end)

describe("group_of", function()
  it("picks the longest prefix, hunks over git", function()
    assert.equal("hunks", actions.group_of("ghs").name)
  end)

  it("puts the HUD in the journey", function()
    assert.equal("journey", actions.group_of("jh").name)
  end)
end)

describe("knows", function()
  it("knows a key Eldentree binds", function()
    assert.is_true(actions.knows("<leader>jh"))
  end)

  it("trusts plugin groups with their own keys", function()
    assert.is_true(actions.knows("<leader>kk"))
  end)

  it("does not know a key nobody binds", function()
    assert.is_false(actions.knows("<leader>jz"))
  end)
end)

describe("the palette", function()
  it("only shows keys that are really bound", function()
    for _, entry in ipairs(palette.ENTRIES) do
      if entry.key and entry.key:find("^<leader>") then
        assert.is_true(actions.knows(entry.key), entry.key)
      end
    end
  end)
end)

describe("which_key_spec", function()
  it("lists every group with its name", function()
    local spec = actions.which_key_spec()
    local names = {}
    for _, item in ipairs(spec) do
      if item.group then
        names[item[1]] = item.group
      end
    end
    assert.equal("journey", names["<leader>j"])
    assert.equal("toggles", names["<leader>u"])
  end)

  it("adds the icons of keys bound elsewhere", function()
    local spec = actions.which_key_spec({ gg = { icon = "x", color = "red" } })
    assert.same({ "<leader>gg", icon = { icon = "x", color = "red" } }, spec[#spec])
  end)
end)
