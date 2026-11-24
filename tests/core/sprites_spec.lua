-- Every region of every franchise pops a sprite, and every sprite paints with its own palette
local lores = vim.tbl_map(function(path)
  return vim.fs.basename(path)
end, vim.fn.glob("lua/core/franchise/lore/*", false, true))

local function each_sprite(fn)
  for _, name in ipairs(lores) do
    local lore = require("core.franchise.lore." .. name)
    for _, region in ipairs(lore.regions) do
      fn(name .. "/" .. region.name, (lore.pixels or {})[region.name], region)
    end
  end
end

describe("sprites", function()
  it("gives every region, Claire's and Malenia's included, a sprite to pop", function()
    each_sprite(function(where, sprite)
      assert.is_table(sprite, where)
    end)
  end)

  it("keeps every frame of Inde's favorite sprites the same size", function()
    each_sprite(function(where, sprite)
      local first = sprite.frames[1]
      for index, frame in ipairs(sprite.frames) do
        assert.equals(#first, #frame, where .. " frame " .. index)
        for _, row in ipairs(frame) do
          assert.equals(#first[1], #row, where .. " frame " .. index)
        end
      end
    end)
  end)

  it("paints only with slots the region's palette has", function()
    each_sprite(function(where, sprite, region)
      for _, frame in ipairs(sprite.frames) do
        for _, row in ipairs(frame) do
          for letter in row:gmatch("[^.]") do
            local slot = sprite.colors[letter]
            assert.is_string(slot, where .. " letter " .. letter)
            assert.is_string(region.palette[slot], where .. " slot " .. slot)
          end
        end
      end
    end)
  end)
end)
