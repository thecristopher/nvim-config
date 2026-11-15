local actions = require("core.desk.actions")

local cfg = actions.merge_config({
  artifact_url = "https://claude.ai/artifact/claire-and-inde",
  sync = { every_minutes = 10, work_hours = { 9, 18 } },
})

local paths = {
  state = "/state/desk",
  skills = "/home/claire/.claude/skills",
  repos = "/home/claire/repos",
}

local function has(list, value)
  return vim.tbl_contains(list, value)
end

describe("merge_config", function()
  it("keeps Claire's values and fills the rest from the defaults", function()
    assert.equal(10, cfg.sync.every_minutes)
    assert.equal("haiku", cfg.sync.check_model)
    assert.equal("~/Documents/GitHub", cfg.repos_dir)
  end)

  it("works with no file at all", function()
    assert.equal(15, actions.merge_config(nil).sync.every_minutes)
  end)
end)

describe("in_work_hours", function()
  it("lets Malenia check in on a Tuesday morning", function()
    assert.is_true(actions.in_work_hours({ hour = 9, wday = 3 }, cfg))
  end)

  it("stops at the closing hour", function()
    assert.is_false(actions.in_work_hours({ hour = 18, wday = 3 }, cfg))
  end)

  it("leaves Sunday for Inde's anniversary date", function()
    assert.is_false(actions.in_work_hours({ hour = 10, wday = 1 }, cfg))
  end)

  it("works weekends when weekdays_only is off", function()
    local weekend = actions.merge_config({ sync = { weekdays_only = false } })
    assert.is_true(actions.in_work_hours({ hour = 10, wday = 7 }, weekend))
  end)
end)

describe("parse_session_id", function()
  it("reads the id from the stop hint", function()
    local out = "  claude attach 597b0f91    open in this terminal\n"
      .. "  claude stop 597b0f91      stop this session\n"
    assert.equal("597b0f91", actions.parse_session_id(out))
  end)

  it("returns nil when Wesker's output has no id", function()
    assert.is_nil(actions.parse_session_id("Workspace not trusted."))
  end)
end)

describe("build_check_argv", function()
  local argv = actions.build_check_argv(cfg, paths, "abc123")

  it("starts a cheap background session that never asks", function()
    assert.same({ "claude", "--bg", "--model", "haiku" }, vim.list_slice(argv, 1, 4))
    assert.is_true(has(argv, "dontAsk"))
  end)

  it("only lets it write into the state folder and read the clock", function()
    local tools = argv[#argv - 2]
    assert.truthy(tools:find("Edit(//state/desk/**)", 1, true))
    assert.truthy(tools:find("Bash(date *)", 1, true))
    assert.falsy(tools:find("Bash(git", 1, true))
  end)

  it("keeps the prompt apart from the variadic flags", function()
    assert.equal("--", argv[#argv - 1])
  end)

  it("passes the state folder and the hash to the skill", function()
    assert.equal("/desk-sync check state_dir=/state/desk inputs_hash=abc123", argv[#argv])
  end)
end)

describe("build_work_argv", function()
  local argv = actions.build_work_argv(cfg, paths)

  it("runs the bigger model with the repos in reach", function()
    assert.equal("opus", argv[4])
    assert.is_true(has(argv, "/home/claire/repos"))
  end)

  it("reads git but cannot write to Jira", function()
    local tools = argv[#argv - 2]
    assert.truthy(tools:find("Bash(git *)", 1, true))
    assert.falsy(tools:find("editJiraIssue", 1, true))
    assert.falsy(tools:find("addOrEditJiraIssueComment", 1, true))
  end)
end)

describe("implement_target", function()
  local function only(dir)
    return function(p)
      return p == dir
    end
  end

  it("opens the repo when Claire's clone is there", function()
    local dir =
      actions.implement_target({ key = "TS-1", repo = "terrasave" }, "/r", only("/r/terrasave"))
    assert.equal("/r/terrasave", dir)
  end)

  it("falls back to the repos folder when the clone is missing", function()
    local dir = actions.implement_target({ key = "TS-2", repo = "umbrella" }, "/r", only("/r/x"))
    assert.equal("/r", dir)
  end)

  it("falls back when no repo was named", function()
    assert.equal("/r", actions.implement_target({ key = "TS-3" }, "/r", only("/r")))
  end)
end)

describe("work_summary", function()
  it("lists the tickets that are ready", function()
    local msg, ok = actions.work_summary({ done = { "LOVE-1", "LOVE-2" }, failed = {} })
    assert.equal("Ready: LOVE-1, LOVE-2", msg)
    assert.is_true(ok)
  end)

  it("reports what failed", function()
    local msg, ok =
      actions.work_summary({ done = {}, failed = { { key = "HALIG-7", reason = "no clone" } } })
    assert.equal("HALIG-7 failed: no clone", msg)
    assert.is_false(ok)
  end)

  it("fails when the session left nothing", function()
    local _, ok = actions.work_summary(nil)
    assert.is_false(ok)
  end)
end)

describe("hash_input", function()
  it("skips missing files without losing the ones after them", function()
    assert.equal("love note\n\0\nplaylist", actions.hash_input({ "love note", nil, "playlist" }, 3))
  end)
end)

describe("minutes_left", function()
  it("is due right away before the first check", function()
    assert.equal(0, actions.minutes_left(nil, 1000, 15))
  end)

  it("counts down from the last check", function()
    assert.equal(10, actions.minutes_left(0, 5 * 60000, 15))
  end)
end)

describe("pr_search_argv", function()
  it("looks for Claire's open PRs that mention the ticket in the org", function()
    local argv = actions.pr_search_argv("SPLT-1", "terrasave")
    assert.same(
      { "gh", "search", "prs", "SPLT-1", "--owner", "terrasave" },
      vim.list_slice(argv, 1, 6)
    )
    assert.is_true(vim.tbl_contains(argv, "open"))
  end)
end)

describe("review_targets", function()
  local prs = {
    {
      number = 7,
      title = "Anniversary playlist for Inde",
      url = "u7",
      repository = { name = "love-notes" },
    },
    { number = 9, title = "Malenia's letter", url = "u9", repository = { name = "haligtree" } },
  }
  local targets = actions.review_targets(prs, "/repos", function(p)
    return p == "/repos/love-notes"
  end)

  it("runs from the local clone when there is one", function()
    assert.equal("/repos/love-notes", targets[1].dir)
    assert.equal(7, targets[1].number)
  end)

  it("leaves dir empty when the repo is not cloned", function()
    assert.is_nil(targets[2].dir)
    assert.equal("haligtree", targets[2].repo)
  end)
end)
