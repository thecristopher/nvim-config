local actions = require("core.threads.actions")

local function answer(nodes)
  return vim.json.encode({
    data = { repository = { pullRequest = { reviewThreads = { nodes = nodes } } } },
  })
end

local function node(fields)
  return vim.tbl_extend("force", {
    id = "T1",
    isResolved = false,
    isOutdated = false,
    path = "notes/love_letter.lua",
    line = 12,
    originalLine = 10,
    comments = {
      nodes = {
        { author = { login = "claire" }, body = "Inde deserves a longer letter\nmaybe two pages" },
        { author = { login = "leon" }, body = "agreed" },
      },
    },
  }, fields or {})
end

describe("parse", function()
  it("reads Claire's open thread with who wrote it and the replies", function()
    local thread = actions.parse(answer({ node() }))[1]
    assert.equal("T1", thread.id)
    assert.equal(12, thread.line)
    assert.equal("claire", thread.author)
    assert.equal(1, thread.replies)
  end)

  it("leaves resolved threads out", function()
    assert.same({}, actions.parse(answer({ node({ isResolved = true }) })))
  end)

  it("falls back to the original line when the thread is outdated", function()
    local thread = actions.parse(answer({ node({ line = vim.NIL, isOutdated = true }) }))[1]
    assert.equal(10, thread.line)
    assert.is_true(thread.outdated)
  end)

  it("sorts the threads by file then line", function()
    local threads = actions.parse(answer({
      node({ id = "B", path = "z.lua", line = 1 }),
      node({ id = "C", path = "a.lua", line = 9 }),
      node({ id = "A", path = "a.lua", line = 2 }),
    }))
    assert.same(
      { "A", "C", "B" },
      vim.tbl_map(function(t)
        return t.id
      end, threads)
    )
  end)

  it("finds nothing in a branch without a PR or in garbage", function()
    assert.same(
      {},
      actions.parse(vim.json.encode({ data = { repository = { pullRequest = vim.NIL } } }))
    )
    assert.same({}, actions.parse("nope"))
  end)

  it("names a deleted account ghost, the way GitHub does", function()
    local thread = actions.parse(answer({
      node({ comments = { nodes = { { author = vim.NIL, body = "hi" } } } }),
    }))[1]
    assert.equal("ghost", thread.author)
  end)
end)

describe("preview", function()
  it("shows the author, the first line and how many replied", function()
    local thread = { author = "claire", body = "Inde deserves more\nsecond line", replies = 2 }
    assert.equal("claire: Inde deserves more (+2)", actions.preview(thread))
  end)

  it("cuts a long thread so the line stays readable", function()
    local thread = { author = "malenia", body = ("rot "):rep(40), replies = 0 }
    assert.equal(actions.PREVIEW_WIDTH, vim.api.nvim_strwidth(actions.preview(thread)))
  end)
end)

describe("conversation", function()
  it("lays out every comment under its author", function()
    local thread =
      { comments = { { author = "claire", body = "a\nb" }, { author = "leon", body = "c" } } }
    assert.same({ "**claire**", "a", "b", "", "**leon**", "c" }, actions.conversation(thread))
  end)
end)

describe("at", function()
  it("finds the thread on Malenia's line and nothing elsewhere", function()
    local threads = { { id = "T1", path = "rot.lua", line = 4 } }
    assert.equal("T1", actions.at(threads, "rot.lua", 4).id)
    assert.is_nil(actions.at(threads, "rot.lua", 5))
  end)
end)

describe("split_repo", function()
  it("splits the owner from the name", function()
    local owner, name = actions.split_repo("claire/terrasave\n")
    assert.equal("claire", owner)
    assert.equal("terrasave", name)
  end)

  it("gives nothing for an answer it cannot read", function()
    assert.is_nil(actions.split_repo(""))
  end)
end)
