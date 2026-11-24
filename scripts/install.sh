#!/usr/bin/env bash
# Gets a new machine ready: the programs Eldentree calls, ~/.config/nvim pointing at this clone,
# and every plugin at the version lazy-lock.json pins.
#   ./scripts/install.sh
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

if command -v brew >/dev/null 2>&1; then
  echo "Installing the tools in Brewfile"
  brew bundle --file "$repo/Brewfile"
else
  echo "No Homebrew here, install these with your package manager:"
  nvim --clean --headless -l <(cat <<LUA
package.path = "$repo/lua/?.lua;" .. package.path
local tools = require("eldentree.tools")
for _, tool in ipairs(tools.for_platform(tools.TOOLS, false)) do
  if not tools.present(tool, function(bin) return vim.fn.executable(bin) == 1 end) then
    io.stdout:write(("  %-14s %s\n"):format(tools.name(tool), tool.gives))
  end
end
LUA
  )
fi

if [ -e "$config" ] && [ "$(cd "$config" && pwd -P)" != "$repo" ]; then
  echo "$config already exists and is not this clone, leaving it alone"
elif [ ! -e "$config" ]; then
  mkdir -p "$(dirname "$config")"
  ln -s "$repo" "$config"
  echo "Linked $config to $repo"
fi

echo "Installing plugins at their locked versions"
nvim --headless "+Lazy! restore" +qa
echo "Done. Open nvim and run :checkhealth eldentree to see what is left"
