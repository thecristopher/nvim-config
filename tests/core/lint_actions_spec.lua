local actions = require("core.lint.actions")

local function always(value) return function() return value end end
local function only(installed) return function(name) return installed[name] == true end end

describe("runnable", function()
  it("keeps linters that are installed", function()
    assert.same({ "shellcheck" }, actions.runnable({ "shellcheck" }, always(true), always(false)))
  end)

  it("drops linters that are not installed", function()
    assert.same({}, actions.runnable({ "hadolint" }, always(false), always(true)))
  end)

  it("drops selene when Malenia's project has no selene.toml", function()
    assert.same({}, actions.runnable({ "selene" }, always(true), always(false)))
  end)

  it("keeps selene when Rennala's project has a selene.toml", function()
    assert.same({ "selene" }, actions.runnable({ "selene" }, always(true), always(true)))
  end)

  it("keeps the installed ones out of a mixed list", function()
    local installed = only({ shellcheck = true, yamllint = true })
    assert.same({ "shellcheck", "yamllint" }, actions.runnable({ "shellcheck", "hadolint", "yamllint" }, installed, always(true)))
  end)
end)
