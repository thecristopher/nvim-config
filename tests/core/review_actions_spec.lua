local actions = require("core.review.actions")

local leon_pr = {
  number = 7,
  title = "Escort Ashley out of the village",
  body = "Rescue mission, no detours.",
  author = { login = "leon" },
  headRefName = "feature/escort",
  baseRefName = "main",
  additions = 12,
  deletions = 3,
  changedFiles = 2,
  url = "https://github.com/raccoon/rpd/pull/7",
}

describe("parse_number", function()
  it("reads a bare number", function()
    assert.equals(42, actions.parse_number("42"))
  end)

  it("reads a number with a hash", function()
    assert.equals(42, actions.parse_number("#42"))
  end)

  it("reads the number out of a PR url", function()
    assert.equals(7, actions.parse_number("https://github.com/raccoon/rpd/pull/7/files"))
  end)

  it("rejects a branch name Wesker typed by mistake", function()
    assert.is_nil(actions.parse_number("feature/uroboros"))
  end)
end)

describe("picker_items", function()
  it("shows number, title, author and branch", function()
    local items = actions.picker_items({ leon_pr })
    assert.equals("#7  Escort Ashley out of the village  (leon, feature/escort)", items[1].text)
  end)

  it("keeps the PR number for the confirm step", function()
    assert.equals(7, actions.picker_items({ leon_pr })[1].number)
  end)

  it("returns nothing when gh gave nothing", function()
    assert.same({}, actions.picker_items(nil))
  end)
end)

describe("trim_diff", function()
  it("leaves a small diff alone", function()
    assert.equals("+ ada", actions.trim_diff("+ ada", 100))
  end)

  it("cuts a big diff and says how much was dropped", function()
    local trimmed = actions.trim_diff(string.rep("x", 50), 10)
    assert.truthy(trimmed:find("showing 10 of 50 characters", 1, true))
  end)
end)

describe("build_prompt", function()
  it("defaults the analysis to Spanish", function()
    assert.truthy(actions.build_prompt(leon_pr, "+ jill"):find("in Spanish", 1, true))
  end)

  it("honors another language when Claire asks for one", function()
    assert.truthy(actions.build_prompt(leon_pr, "+ jill", "English"):find("in English", 1, true))
  end)

  it("includes the diff", function()
    assert.truthy(
      actions.build_prompt(leon_pr, "+ rebecca chambers"):find("+ rebecca chambers", 1, true)
    )
  end)

  it("says so when the PR has no description", function()
    local quiet = vim.tbl_extend("force", leon_pr, { body = "" })
    assert.truthy(actions.build_prompt(quiet, "+ hunk"):find("(no description)", 1, true))
  end)
end)

describe("report_lines", function()
  it("opens with the PR number and title", function()
    assert.equals(
      "# #7 Escort Ashley out of the village",
      actions.report_lines(leon_pr, "## Resumen")[1]
    )
  end)

  it("ends with Claude's analysis", function()
    local lines = actions.report_lines(leon_pr, "## Resumen\nAshley is safe")
    assert.equals("Ashley is safe", lines[#lines])
  end)
end)
