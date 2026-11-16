-- snacks sizes an image by the DPI in its header, so a portrait with a bogus one draws tiny
local folder = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  .. "/images/portraits"

local function density(path)
  local image = assert(io.open(path, "rb"))
  local header = image:read(18)
  image:close()
  return header:sub(7, 11), header:byte(14), header:byte(15) * 256 + header:byte(16)
end

describe("portraits", function()
  it("keeps Ada at the screen density so she fills her STATUS panel", function()
    local files = vim.fn.glob(folder .. "/*.jpg", false, true)
    assert.is_true(#files > 0)
    for _, file in ipairs(files) do
      local marker, units, dpi = density(file)
      assert.are.same({ "JFIF\0", 1, 72 }, { marker, units, dpi }, file)
    end
  end)
end)
