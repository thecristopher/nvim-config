local actions = require("core.resize.actions")

-- Claire's window: top left, 50 columns, 14 rows of text and no winbar
local claire = { winrow = 1, wincol = 1, winbar = 0, width = 50, height = 14 }
-- Malenia's window: same size with a winbar on top
local malenia = { winrow = 1, wincol = 1, winbar = 1, width = 50, height = 13 }

describe("edge_at", function()
  it("finds the border right of Claire's window", function()
    assert.equals("right", actions.edge_at({ wincol = 51, winrow = 6 }, claire))
  end)

  it("finds the border under Claire's window", function()
    assert.equals("bottom", actions.edge_at({ wincol = 11, winrow = 15 }, claire))
  end)

  it("counts Malenia's winbar before her bottom border", function()
    assert.equals("bottom", actions.edge_at({ wincol = 11, winrow = 15 }, malenia))
  end)

  it("ignores the mouse over Inde's text", function()
    assert.is_nil(actions.edge_at({ wincol = 21, winrow = 6 }, claire))
  end)
end)

describe("width_range", function()
  it("keeps the tree between TREE_MIN and TREE_MAX", function()
    local least, most = actions.width_range("neo-tree", 200)
    assert.equals(actions.TREE_MIN, least)
    assert.equals(actions.TREE_MAX, most)
  end)

  it("lets Leon's code go from one column to the whole editor", function()
    local least, most = actions.width_range("lua", 200)
    assert.equals(1, least)
    assert.equals(200, most)
  end)

  it("never asks the tree for more than a narrow editor has", function()
    local least, most = actions.width_range("neo-tree", 15)
    assert.equals(15, least)
    assert.equals(15, most)
  end)
end)

describe("stepped", function()
  it("grows Claire's window by the step", function()
    assert.equals(82, actions.stepped(80, 2, 1, 200))
  end)

  it("stops at the most", function()
    assert.equals(60, actions.stepped(58, 8, 20, 60))
  end)

  it("stops at the least", function()
    assert.equals(20, actions.stepped(22, -8, 20, 60))
  end)
end)

describe("fitted", function()
  it("pulls a tree dragged too wide back to its most", function()
    assert.equals(60, actions.fitted(90, 20, 60))
  end)

  it("pulls a tree dragged too thin back to its least", function()
    assert.equals(20, actions.fitted(5, 20, 60))
  end)

  it("leaves Inde's width alone when it fits", function()
    assert.is_nil(actions.fitted(34, 20, 60))
  end)
end)

describe("with_separator", function()
  it("swaps the separator and keeps Inde's other groups", function()
    local whl =
      actions.with_separator("Normal:EldenPanel,WinSeparator:WinSeparator", "EldenResizeHover")
    assert.equals("Normal:EldenPanel,WinSeparator:EldenResizeHover", whl)
  end)

  it("adds the separator to a window without groups", function()
    assert.equals("WinSeparator:EldenResizeHover", actions.with_separator("", "EldenResizeHover"))
  end)
end)

describe("handle_spot", function()
  it("puts the handle on Claire's right border at the mouse row", function()
    local row, col = actions.handle_spot("right", claire, 6)
    assert.equals(5, row)
    assert.equals(50, col)
  end)

  it("follows the border when Claire's window grows", function()
    local wider = vim.tbl_extend("force", claire, { width = 60 })
    local _, col = actions.handle_spot("right", wider, 6)
    assert.equals(60, col)
  end)

  it("puts the handle under Malenia's winbar and text", function()
    local row = actions.handle_spot("bottom", malenia, 11)
    assert.equals(14, row)
  end)

  it("keeps the handle on the border when the mouse runs past it", function()
    local _, col = actions.handle_spot("bottom", claire, 90)
    assert.equals(49, col)
  end)

  it("centers the handle without a mouse", function()
    local row = actions.handle_spot("right", claire, nil)
    assert.equals(7, row)
  end)
end)

describe("KEYS", function()
  it("moves Malenia's border faster with shift", function()
    assert.is_true(math.abs(actions.KEYS.L.steps) > math.abs(actions.KEYS.l.steps))
  end)
end)
