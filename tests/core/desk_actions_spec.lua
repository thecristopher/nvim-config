local actions = require("core.desk.actions")

describe("merge_config", function()
  local cfg = actions.merge_config({
    artifact_url = "https://claude.ai/artifact/claire-and-inde",
    sync = { work_model = "sonnet" },
  })

  it("keeps Claire's values and fills the rest from the defaults", function()
    assert.equal("sonnet", cfg.sync.work_model)
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
  local base = { installed = true, inbox = 0 }
  local function with(extra)
    return actions.status_lines(vim.tbl_extend("force", base, extra))
  end

  it("asks Leon to install the agent when it is missing", function()
    local lines = actions.status_lines({ installed = false, inbox = 0 })
    assert.equal(1, #lines)
    assert.truthy(lines[1]:find("install.sh", 1, true))
  end)

  it("says when Claire's last work session finished", function()
    assert.same(
      { "Work: idle, last finished 2026-02-14T20:00:00Z" },
      with({ work_finished_at = "2026-02-14T20:00:00Z" })
    )
  end)

  it("says when nothing ever ran", function()
    assert.same({ "Work: idle, last finished never" }, with({}))
  end)

  it("shows a running work session and what waits in the inbox", function()
    local lines = with({ work_age_min = 7, inbox = 2 })
    assert.equal("Work: running for 7 min", lines[1])
    assert.equal("Inbox: 2 waiting to open", lines[2])
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

describe("open_argv", function()
  local cfg = actions.merge_config({ artifact_url = "https://claude.ai/artifact/inde-desk" })

  it("opens Claire's installed Desk app", function()
    local argv = actions.open_argv(cfg, function()
      return true
    end)
    assert.equal("open", argv[1])
    assert.truthy(argv[2]:find("Claude Apps/KTLO Desk.app", 1, true))
  end)

  it("falls back to the artifact in the browser when the app is missing", function()
    assert.same(
      { "open", "https://claude.ai/artifact/inde-desk" },
      actions.open_argv(cfg, function()
        return false
      end)
    )
  end)
end)

describe("branch_hits", function()
  local stdout = table.concat({
    "love-notes\tbugfix/LOVE-4-anniversary-playlist",
    "love-notes\torigin/bugfix/LOVE-4-anniversary-playlist",
    "haligtree\torigin/feature/LOVE-4-malenia-letter",
    "haligtree\torigin",
  }, "\n")
  local hits = actions.branch_hits(stdout)

  it("keeps one hit per repo and branch, remote name dropped", function()
    assert.same({
      { repo = "love-notes", branch = "bugfix/LOVE-4-anniversary-playlist" },
      { repo = "haligtree", branch = "feature/LOVE-4-malenia-letter" },
    }, hits)
  end)

  it("finds nothing in empty output", function()
    assert.same({}, actions.branch_hits(""))
  end)
end)

describe("pr_by_branch_argv", function()
  it("asks gh for the open PR of Malenia's branch in its repo", function()
    local argv = actions.pr_by_branch_argv(
      "haligtree-org",
      { repo = "haligtree", branch = "feature/LOVE-4-letter" }
    )
    assert.same(
      { "gh", "pr", "list", "-R", "haligtree-org/haligtree", "--head", "feature/LOVE-4-letter" },
      vim.list_slice(argv, 1, 7)
    )
  end)
end)

describe("with_repo", function()
  it("tags gh pr list results with their repo so review_targets reads them", function()
    local prs = actions.with_repo({ { number = 3, title = "Inde's date night" } }, "love-notes")
    assert.equal("love-notes", prs[1].repository.name)
    assert.equal(3, prs[1].number)
  end)
end)

describe("inbox_item queue id", function()
  it("drops a queue id that could walk out of the outbox, like Wesker's", function()
    local item = actions.inbox_item({ kind = "review", key = "RE-1", queue_id = "../wesker" })
    assert.is_nil(item.queue_id)
  end)
end)
