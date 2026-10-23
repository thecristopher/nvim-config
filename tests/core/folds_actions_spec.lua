local actions = require("core.folds.actions")

local function cut(text, width) return vim.fn.strcharpart(text, 0, width) end

describe("suffix", function()
  it("counts the lines a fold hides", function()
    assert.equal("  󰁂 12 lines ", actions.suffix(12))
  end)

  it("speaks in singular for one line", function()
    assert.equal("  󰁂 1 line ", actions.suffix(1))
  end)
end)

describe("fold_chunks", function()
  local first_line = { { "function ", "Keyword" }, { "write_to_inde()", "Function" } }

  it("keeps the whole first line when it fits and adds the tally", function()
    local chunks = actions.fold_chunks(first_line, 8, 80, cut)
    assert.same({ "function ", "Keyword" }, chunks[1])
    assert.same({ "write_to_inde()", "Function" }, chunks[2])
    assert.same({ actions.suffix(8), "UfoFoldedEllipsis" }, chunks[3])
  end)

  it("cuts Malenia's long line so the tally still fits", function()
    local suffix_width = vim.fn.strdisplaywidth(actions.suffix(8))
    local chunks = actions.fold_chunks(first_line, 8, suffix_width + 12, cut)
    assert.same({ "wri", "Function" }, chunks[2])
    assert.equal(3, #chunks)
  end)
end)
