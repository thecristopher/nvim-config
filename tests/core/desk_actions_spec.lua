local actions = require("core.desk.actions")

describe("merge_config", function()
  local cfg = actions.merge_config({
    artifact_url = "https://claude.ai/artifact/claire-and-inde",
    sync = { work_model = "sonnet" },
  })

  it("keeps Claire's values and fills the rest from the defaults", function()
    assert.equal("sonnet", cfg.sync.work_model)
    assert.equal("haiku", cfg.sync.listen_model)
    assert.equal("~/Documents/GitHub", cfg.repos_dir)
  end)

  it("works with no file at all", function()
    local empty = actions.merge_config(nil)
    assert.equal("", empty.state_dir)
    assert.equal("opus", empty.sync.work_model)
  end)
end)

describe("inbox_item", function()
  it("reads Claire's implement request with its repo", function()
    assert.same(
      { kind = "implement", key = "LOVE-1", repo = "love-notes", queue_id = "q1" },
      actions.inbox_item({
        kind = "implement",
        key = "LOVE-1",
        repo = "love-notes",
        queue_id = "q1",
      })
    )
  end)

  it("drops an empty repo so Malenia's review runs from the repos folder", function()
    local item = actions.inbox_item({ kind = "review", key = "HALIG-7", repo = "" })
    assert.is_nil(item.repo)
    assert.equal("review", item.kind)
  end)

  it("ignores kinds nvim does not open, like Inde's analysis", function()
    assert.is_nil(actions.inbox_item({ kind = "analyze", key = "LOVE-2" }))
  end)

  it("ignores a request with no key or a broken file", function()
    assert.is_nil(actions.inbox_item({ kind = "implement", key = "" }))
    assert.is_nil(actions.inbox_item(nil))
    assert.is_nil(actions.inbox_item("love letter"))
  end)
end)

describe("status_lines", function()
  local base = { installed = true, paused = false, inbox = 0 }
  local function with(extra)
    return actions.status_lines(vim.tbl_extend("force", base, extra))
  end

  it("asks Leon to install the agents when they are missing", function()
    local lines = actions.status_lines({ installed = false, inbox = 0 })
    assert.equal(1, #lines)
    assert.truthy(lines[1]:find("install.sh", 1, true))
  end)

  it("says the listener is up and the work session idle", function()
    local lines = with({
      listener_age_min = 12,
      listener_quiet_min = 0,
      work_finished_at = "2026-02-14T20:00:00Z",
    })
    assert.equal(
      "Listener: up for 12 min, checking the queue every minute while the desk is open",
      lines[1]
    )
    assert.equal("Work: idle, last finished 2026-02-14T20:00:00Z", lines[2])
  end)

  it("notices a listener that went silent", function()
    assert.truthy(
      with({ listener_age_min = 40, listener_quiet_min = 9 })[1]:find("silent for 9 min", 1, true)
    )
  end)

  it("says when Malenia paused it, even with a session file left", function()
    assert.truthy(with({ paused = true, listener_age_min = 3 })[1]:find("paused", 1, true))
  end)

  it("says when nothing listens yet", function()
    assert.truthy(with({})[1]:find("not running", 1, true))
  end)

  it("shows a running work session and what waits in the inbox", function()
    local lines = with({ listener_age_min = 5, work_age_min = 7, inbox = 2 })
    assert.equal("Work: running for 7 min", lines[2])
    assert.equal("Inbox: 2 waiting to open", lines[3])
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

describe("implement_cmd", function()
  it("runs ticket-implement for Inde's ticket", function()
    assert.same({ "claude", "/ticket-implement LOVE-3" }, actions.implement_cmd("LOVE-3"))
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
