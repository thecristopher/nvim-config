local actions = require("core.trial.actions")

local function only(...)
  local present = {}
  for _, file in ipairs({ ... }) do
    present[file] = true
  end
  return function(file)
    return present[file] == true
  end
end

describe("detect", function()
  it("prefers the project's own test script", function()
    assert.same({ "./scripts/test.sh" }, actions.detect(only("scripts/test.sh", "Makefile")))
  end)

  it("runs npm test in Leon's frontend", function()
    assert.same({ "npm", "test", "--silent" }, actions.detect(only("package.json")))
  end)

  it("gives up when there is nothing to run", function()
    assert.is_nil(actions.detect(only()))
  end)
end)

describe("tail", function()
  it("keeps only the last lines where the verdict lives", function()
    assert.equal("Ada\nWesker", actions.tail("Jill\nClaire\nAda\nWesker\n", 2))
  end)
end)
