local progress = require("core.progress")

describe("progress task", function()
  local real_notify, shown

  before_each(function()
    shown = {}
    real_notify = vim.notify
    vim.notify = function(msg, level, opts)
      table.insert(shown, { msg = msg, level = level, opts = opts })
    end
  end)

  after_each(function()
    vim.notify = real_notify
  end)

  it("stays on screen while the work runs", function()
    local task = progress.start({ id = "claire_test", title = "Test", message = "Claire writes" })
    vim.wait(400, function()
      return #shown >= 2
    end)
    assert.is_false(shown[1].opts.timeout)
    assert.are.equal("claire_test", shown[1].opts.id)
    task:done("Written")
  end)

  it("ends with the final word under the same id, and stops redrawing", function()
    local task = progress.start({ id = "malenia_test", title = "Test", message = "Malenia waits" })
    vim.wait(200, function()
      return #shown >= 1
    end)
    task:done("Malenia is done")
    local last = shown[#shown]
    assert.is_truthy(last.msg:find("^Malenia is done"))
    assert.is_nil(last.opts.timeout)
    local count = #shown
    vim.wait(400)
    assert.are.equal(count, #shown)
  end)

  it("fails in red", function()
    local task = progress.start({ id = "wesker_test", title = "Test", message = "Wesker pushes" })
    task:fail("rejected")
    assert.are.equal(vim.log.levels.ERROR, shown[#shown].level)
  end)
end)
