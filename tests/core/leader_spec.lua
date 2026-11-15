local actions = require("core.leader.actions")
local leader = require("core.leader")

describe("HANDLERS", function()
  it("has a handler for every binding that names one", function()
    for _, binding in ipairs(actions.BINDINGS) do
      if binding.handler then
        assert.is_function(leader.HANDLERS[binding.handler], binding.handler)
      end
    end
  end)
end)
