-- Every program Eldentree calls outside of nvim, what it unlocks and where it comes from. The
-- health check reads it and the Brewfile installs the ones Homebrew has.
local M = {}

---@class EldentreeTool
---@field bin string|string[] the executable, or the ones that can stand in for each other
---@field gives string what it unlocks, in a few words
---@field brew? string the Homebrew formula, nil when it comes from somewhere else
---@field from? string where to get it when Homebrew has no formula
---@field required? boolean the editor barely works without it
---@field os? string only checked on this platform ("mac")

---@type EldentreeTool[]
M.TOOLS = {
  { bin = "git", gives = "every git feature, the repo scanner", brew = "git", required = true },
  { bin = "rg", gives = "grep pickers and :grep", brew = "ripgrep", required = true },
  { bin = "fd", gives = "the file picker and a fast repo scan", brew = "fd" },
  { bin = "node", gives = "most LSP servers mason installs, Copilot", brew = "node" },
  { bin = "tree-sitter", gives = "building treesitter parsers", brew = "tree-sitter-cli" },
  {
    bin = "gh",
    gives = "CI in the statusline, review threads, :Review, PRs, the desk",
    brew = "gh",
  },
  { bin = "lazygit", gives = "<leader>gg", brew = "lazygit" },
  { bin = "curl", gives = "album covers and lyrics", brew = "curl" },
  { bin = "chafa", gives = "portraits in terminals without images", brew = "chafa" },
  {
    bin = { "magick", "convert" },
    gives = "portraits as real images, the song's tint",
    brew = "imagemagick",
  },
  { bin = "rsvg-convert", gives = ":Snapshot", brew = "librsvg" },
  { bin = "ffmpeg", gives = "rebuilding sounds with scripts/sounds.py", brew = "ffmpeg" },
  {
    bin = "claude",
    gives = "commit and PR drafts, :Review, the Claude panel",
    from = "https://claude.com/claude-code",
  },
  {
    bin = "swiftc",
    gives = "the instant sound player, afplay is slower",
    from = "xcode-select --install",
    os = "mac",
  },
}

--- The tools this platform should have, in list order.
---@param tools EldentreeTool[]
---@param on_mac boolean
---@return EldentreeTool[]
function M.for_platform(tools, on_mac)
  return vim.tbl_filter(function(tool)
    return tool.os ~= "mac" or on_mac
  end, tools)
end

--- Whether any of the tool's executables is on PATH.
---@param tool EldentreeTool
---@param executable fun(bin: string): boolean
---@return boolean
function M.present(tool, executable)
  for _, bin in ipairs(type(tool.bin) == "table" and tool.bin or { tool.bin }) do
    if executable(bin) then
      return true
    end
  end
  return false
end

--- How to install a missing tool, in one short line.
---@param tool EldentreeTool
---@return string
function M.how_to_install(tool)
  if tool.brew then
    return "`brew install " .. tool.brew .. "`"
  end
  return tool.from or "see its docs"
end

--- The name to show for a tool, the first of its executables.
---@param tool EldentreeTool
---@return string
function M.name(tool)
  return type(tool.bin) == "table" and tool.bin[1] or tool.bin
end

return M
