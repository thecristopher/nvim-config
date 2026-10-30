local actions = require("core.ci.actions")

local words = { running = "Radio static", passed = "All clear", failed = "Mayday" }

local function gh(status, conclusion, sha)
  return vim.json.encode({
    {
      status = status,
      conclusion = conclusion,
      workflowName = "CI",
      url = "https://github.com/claire/terrasave/actions/runs/1",
      headSha = sha or "a1",
    },
  })
end

describe("parse", function()
  it("reads a run that is still going", function()
    assert.equal("running", actions.parse(gh("in_progress", "")).state)
  end)

  it("reads Claire's passing run and Leon's failing one", function()
    assert.equal("passed", actions.parse(gh("completed", "success")).state)
    assert.equal("failed", actions.parse(gh("completed", "failure")).state)
    assert.equal("failed", actions.parse(gh("completed", "cancelled")).state)
  end)

  it("finds no run on a branch that never pushed, or on garbage", function()
    assert.is_nil(actions.parse("[]"))
    assert.is_nil(actions.parse("not json"))
    assert.is_nil(actions.parse(nil))
  end)
end)

describe("label", function()
  it("names the run in the franchise's words", function()
    assert.equal("󰑮 Radio static", actions.label({ state = "running" }, words))
    assert.equal("󰅖 Mayday", actions.label({ state = "failed" }, words))
  end)

  it("says nothing without a run", function()
    assert.equal("", actions.label(nil, words))
  end)
end)

describe("finished", function()
  it("announces the verdict when the run Inde watched finishes", function()
    local before = { state = "running", sha = "a1" }
    assert.equal("passed", actions.finished(before, { state = "passed", sha = "a1" }))
    assert.equal("failed", actions.finished(before, { state = "failed", sha = "a1" }))
  end)

  it("stays quiet about a run that was already over when nvim saw it", function()
    assert.is_nil(actions.finished(nil, { state = "failed", sha = "a1" }))
    assert.is_nil(
      actions.finished({ state = "passed", sha = "a1" }, { state = "passed", sha = "a1" })
    )
  end)

  it("stays quiet while the new run is still going or belongs to another commit", function()
    assert.is_nil(
      actions.finished({ state = "running", sha = "a1" }, { state = "running", sha = "a1" })
    )
    assert.is_nil(
      actions.finished({ state = "running", sha = "a1" }, { state = "passed", sha = "b2" })
    )
  end)
end)

describe("poll_ms", function()
  it("asks more often while Malenia's run is going", function()
    assert.equal(actions.RUNNING_POLL_MS, actions.poll_ms({ state = "running" }))
    assert.equal(actions.IDLE_POLL_MS, actions.poll_ms({ state = "passed" }))
    assert.equal(actions.IDLE_POLL_MS, actions.poll_ms(nil))
  end)
end)
