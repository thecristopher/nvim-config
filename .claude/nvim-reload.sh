#!/bin/bash
# Called by Claude Code's PostToolUse hook after Edit/Write.
# Clears the changed module from Lua's package cache, then re-sources init.lua
# in every running Neovim instance so edits take effect without a restart.

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo '{}')

# Extract file_path from the hook JSON payload
if command -v jq >/dev/null 2>&1; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
else
  FILE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")
fi

# Only act on .lua files inside the nvim config
[[ "$FILE" == *.lua ]] || exit 0

# Derive the Lua module name  (e.g. .../lua/plugins/snacks.lua -> plugins.snacks)
MODULE=$(echo "$FILE" | sed 's|.*/lua/||; s|\.lua$||; s|/|.|g')

# Locate all live Neovim sockets
SOCKS=$(find "${TMPDIR:-/tmp}" -maxdepth 6 -name "0" 2>/dev/null | grep -i nvim || true)
[[ -z "$SOCKS" ]] && exit 0

for sock in $SOCKS; do
  [[ -S "$sock" ]] || continue
  # Clear the module from Lua cache so the next require() picks up the new file
  nvim --server "$sock" \
    --remote-expr "luaeval(\"package.loaded['${MODULE}'] = nil\")" \
    2>/dev/null || true
  # Re-source init.lua to re-apply top-level config and lazy specs
  nvim --server "$sock" \
    --remote-send ':source $MYVIMRC<CR>' \
    2>/dev/null || true
done

exit 0
