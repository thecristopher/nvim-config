#!/usr/bin/env bash
# Tries Eldentree without touching your own Neovim: the config lives under its own NVIM_APPNAME,
# so its plugins, state and cache stay apart from ~/.config/nvim and go away with --clean.
#   curl -fsSL https://raw.githubusercontent.com/thecristopher/nvim-config/main/scripts/try.sh | bash
#   ./scripts/try.sh            runs this clone
#   ./scripts/try.sh --clean    removes everything the trial left behind
set -euo pipefail

app="eldentree-try"
config="${XDG_CONFIG_HOME:-$HOME/.config}/$app"
url="https://github.com/thecristopher/nvim-config.git"

if [ "${1:-}" = "--clean" ]; then
  rm -rf "$config" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/$app" \
    "${XDG_STATE_HOME:-$HOME/.local/state}/$app" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/$app"
  echo "Eldentree trial removed"
  exit 0
fi

if ! command -v nvim >/dev/null 2>&1; then
  echo "Eldentree needs Neovim 0.11 or newer on your PATH" >&2
  exit 1
fi

# run from a clone, the trial points at it, piped through curl it keeps its own shallow clone
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd || true)"
if [ ! -e "$config" ]; then
  mkdir -p "$(dirname "$config")"
  if [ -n "$here" ] && [ -f "$here/init.lua" ] && [ -d "$here/lua/core" ]; then
    ln -s "$here" "$config"
  else
    git clone --depth 1 "$url" "$config"
  fi
fi

echo "Opening Eldentree, the first start installs the plugins"
NVIM_APPNAME="$app" exec nvim "$@"
