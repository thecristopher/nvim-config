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

describe("failed_excerpt", function()
  local log = table.concat({
    "build\tSet up job\t2026-11-16T10:00:00.0000000Z Preparing Claire's runner",
    "build\tRun tests\t2026-11-16T10:00:01.0000000Z \27[31mFAIL\27[0m love_letter_spec.lua",
    "build\tRun tests\t2026-11-16T10:00:02.0000000Z expected Inde, got Wesker",
    "lint\tstylua\t2026-11-16T10:00:03.0000000Z diff in malenia.lua",
  }, "\n")

  it("names the job and the step that failed first", function()
    assert.equal("build › Set up job", actions.failed_excerpt(log).title)
  end)

  it("keeps only the first failing step, without timestamps or colors", function()
    local only_tests = log:gsub("^[^\n]*\n", "")
    local excerpt = actions.failed_excerpt(only_tests)
    assert.equal("build › Run tests", excerpt.title)
    assert.same({ "FAIL love_letter_spec.lua", "expected Inde, got Wesker" }, excerpt.lines)
  end)

  it("keeps the last lines of a long step, where the error lands", function()
    local only_tests = log:gsub("^[^\n]*\n", "")
    assert.same({ "expected Inde, got Wesker" }, actions.failed_excerpt(only_tests, 1).lines)
  end)

  it("has nothing to show for an empty log", function()
    assert.is_nil(actions.failed_excerpt("").title)
  end)
end)

describe("parse id", function()
  it("keeps the run's id so its failed log can be asked for", function()
    local stdout =
      vim.json.encode({ { status = "completed", conclusion = "failure", databaseId = 42 } })
    assert.equal(42, actions.parse(stdout).id)
  end)
end)

describe("failed_excerpt cleanup", function()
  it("drops the byte order mark and the runner's markers from Leon's log", function()
    local log = table.concat({
      "format\tUNKNOWN STEP\t\239\187\1912026-10-28T08:08:14.1268533Z Current runner version",
      "format\tUNKNOWN STEP\t2026-10-28T08:08:15.0000000Z ##[endgroup]",
      "format\tUNKNOWN STEP\t2026-10-28T08:08:16.0000000Z ##[error]Process completed with exit code 1.",
    }, "\n")
    assert.same(
      { "Current runner version", "error: Process completed with exit code 1." },
      actions.failed_excerpt(log).lines
    )
  end)
end)

describe("failed_excerpt ending", function()
  local log = table.concat({
    "lint\tUNKNOWN STEP\t2026-10-28T08:08:14.0000000Z Diff in claire.lua",
    "lint\tUNKNOWN STEP\t2026-10-28T08:08:15.0000000Z ##[error]stylua failed with exit code 1",
    "lint\tUNKNOWN STEP\t2026-10-28T08:08:16.0000000Z Post job cleanup.",
  }, "\n")

  it("stops at Malenia's error, leaving the cleanup out", function()
    assert.same(
      { "Diff in claire.lua", "error: stylua failed with exit code 1" },
      actions.failed_excerpt(log).lines
    )
  end)

  it("names only the job when gh cannot tell the step", function()
    assert.equal("lint", actions.failed_excerpt(log).title)
  end)
end)
