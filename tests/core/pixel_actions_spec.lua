local actions = require("core.pixel.actions")

local pixels = {
  westview = {
    colors = { a = "yellow", r = "red" },
    frames = { { "a.", ".r" }, { "aa", "aa" } },
  },
}

describe("sprite_for", function()
  it("finds the hex Wanda pops when Claire saves her love letter", function()
    local sprite = actions.sprite_for(pixels, "westview") or {}
    assert.equals(2, #sprite.frames)
    assert.equals("yellow", sprite.colors.a)
  end)

  it("stays quiet for a role without sprites, like Malenia's for now", function()
    assert.is_nil(actions.sprite_for(pixels, "haligtree"))
    assert.is_nil(actions.sprite_for(nil, "westview"))
  end)
end)

describe("pops", function()
  it("pops on only some of Inde's saves", function()
    assert.is_true(actions.pops("saved", 0.1))
    assert.is_false(actions.pops("saved", 0.9))
  end)

  it("always pops when Malenia fells a boss", function()
    assert.is_true(actions.pops("felled", 0.99))
  end)
end)

describe("cell", function()
  it("leaves a cell with no pixels transparent", function()
    assert.same({ " " }, { actions.cell(nil, nil) })
  end)

  it("paints half a cell over the background", function()
    assert.same({ "▀", "yellow", "base" }, { actions.cell("yellow", nil) })
    assert.same({ "▄", "red", "base" }, { actions.cell(nil, "red") })
  end)

  it("fills a cell whose two pixels match", function()
    assert.same({ "█", "yellow", "yellow" }, { actions.cell("yellow", "yellow") })
  end)

  it("splits a cell between two colors", function()
    assert.same({ "▀", "yellow", "red" }, { actions.cell("yellow", "red") })
  end)
end)

describe("rows", function()
  it("folds two pixel rows into one row of cells for Claire's anniversary hex", function()
    local rows = actions.rows({ "a.", ".r" }, { a = "yellow", r = "red" })
    assert.equals(1, #rows)
    assert.equals("▀▄", rows[1].text)
    assert.same({ start = 0, finish = 3, fg = "yellow", bg = "base" }, rows[1].marks[1])
    assert.same({ start = 3, finish = 6, fg = "red", bg = "base" }, rows[1].marks[2])
  end)

  it("treats a missing last pixel row as transparent", function()
    local rows = actions.rows({ "a" }, { a = "yellow" })
    assert.equals("▀", rows[1].text)
  end)

  it("marks no transparent cell", function()
    local rows = actions.rows({ "..", ".." }, {})
    assert.equals("  ", rows[1].text)
    assert.equals(0, #rows[1].marks)
  end)
end)

describe("frame_at", function()
  it("steps through the frames and ends after the last", function()
    assert.equals(1, actions.frame_at(0, 3))
    assert.equals(2, actions.frame_at(actions.FRAME_MS, 3))
    assert.is_nil(actions.frame_at(actions.FRAME_MS * 3, 3))
  end)
end)

describe("place", function()
  local info = { winrow = 2, wincol = 31, width = 80, height = 30 }

  it("sits in the window's top right corner, clear of its edges", function()
    assert.same({ row = 2, col = 98, width = 10, height = 4 }, actions.place(info, 10, 4))
  end)

  it("gives up when the window is too small for Inde's sprite", function()
    assert.is_nil(actions.place({ winrow = 1, wincol = 1, width = 12, height = 30 }, 10, 4))
    assert.is_nil(actions.place({ winrow = 1, wincol = 1, width = 80, height = 5 }, 10, 4))
  end)
end)
