local actions = require("core.find.actions")

describe("other_scope", function()
  it("flips Claire from her repo to everywhere", function()
    assert.equal("all", actions.other_scope("repo"))
  end)

  it("brings Malenia back to the repo", function()
    assert.equal("repo", actions.other_scope("all"))
  end)
end)

describe("recent_title", function()
  it("names the scope and the key that flips it", function()
    assert.equal("Recent in this repo  <C-a> all", actions.recent_title("repo"))
  end)
end)
