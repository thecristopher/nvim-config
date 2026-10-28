local actions = require("core.progress.actions")

local re = { done = "▰", head = "▶", left = "▱" }

local function cells(bar)
  return vim.fn.strchars(bar)
end

describe("progress bar", function()
  it("fills up to the fraction it knows", function()
    assert.are.equal("▰▰▶▱", actions.bar(0.5, 0, re, 4))
  end)

  it("is full once the work is done", function()
    assert.are.equal("▰▰▰▰", actions.bar(1, 0, re, 4))
  end)

  it("sweeps while the end is unknown, and keeps moving", function()
    local first = actions.bar(nil, 0, re)
    local later = actions.bar(nil, actions.FRAME_MS * 3, re)
    assert.are_not.equal(first, later)
    assert.are.equal(actions.WIDTH, cells(first))
    assert.are.equal(actions.WIDTH, cells(later))
  end)

  it("bounces back from the far end instead of running off", function()
    local travel = actions.WIDTH - actions.SWEEP
    for frame = 0, travel * 4 do
      assert.are.equal(actions.WIDTH, cells(actions.bar(nil, frame * actions.FRAME_MS, re)))
    end
  end)

  it("wears the franchise's music bar, a plain one without a skin", function()
    assert.are.same(re, actions.style({ music = { bar = re } }))
    assert.is_string(actions.style(nil).done)
  end)
end)

describe("progress text", function()
  it("reads elapsed time the way people say it", function()
    assert.are.equal("7s", actions.elapsed(7400))
    assert.are.equal("1m 05s", actions.elapsed(65000))
  end)

  it("puts the bar and the time under what Claire is doing", function()
    local text = actions.text("Drafting Inde's love note…", nil, 3000, re)
    local lines = vim.split(text, "\n")
    assert.are.equal("Drafting Inde's love note…", lines[1])
    assert.is_truthy(lines[2]:find("3s$"))
  end)

  it("shows the percentage when it is known", function()
    assert.is_truthy(actions.text("Malenia pushes", 0.25, 0, re):find("25%%"))
  end)
end)

describe("progress wrapping", function()
  it("wraps a long message on spaces so nothing runs off the notification", function()
    local text = actions.wrap("Claude está forjando un ejercicio para Claire e Inde", 20)
    for _, line in ipairs(vim.split(text, "\n")) do
      assert.is_true(vim.fn.strdisplaywidth(line) <= 20)
    end
    assert.are.equal("Claude está forjando un ejercicio para Claire e Inde", text:gsub("\n", " "))
  end)

  it("splits a word too long for any line, like a PR url", function()
    local url = "https://github.com/thecristopher/back-to-basics/pull/12345"
    for _, line in ipairs(vim.split(actions.wrap(url, 20), "\n")) do
      assert.is_true(vim.fn.strdisplaywidth(line) <= 20)
    end
  end)

  it("keeps the message's own line breaks, like a failing test tail", function()
    assert.are.equal("Leon falló\nAda también", actions.wrap("Leon falló\nAda también", 40))
  end)

  it("never lets the bar line wrap", function()
    local width = actions.text_width(80)
    assert.is_true(vim.fn.strdisplaywidth(actions.bar(nil, 0, re)) + 10 <= width)
  end)

  it("stays readable on a tiny editor and does not sprawl on a huge one", function()
    assert.are.equal(36, actions.text_width(40))
    assert.are.equal(72, actions.text_width(400))
  end)
end)
