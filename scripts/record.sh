#!/usr/bin/env bash
# Records the README demos in images/demo with vhs, inside a sandbox of made up repos so no real
# project, branch or recent file ever shows up. Pass tape names to record only those:
#   ./scripts/record.sh            every tape in docs/tapes
#   ./scripts/record.sh music hud  just those two
set -euo pipefail

cd "$(dirname "$0")/.."

command -v vhs >/dev/null || {
  echo "vhs is missing, install it with: brew install vhs"
  exit 1
}

# the real path, macOS hands out /var which is a symlink to /private/var
sandbox=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$sandbox"' EXIT

make_repo() {
  local dir="$sandbox/repos/$1"
  mkdir -p "$dir/lua"
  printf -- '-- %s\nlocal M = {}\n\n-- TODO: %s\nfunction M.setup() end\n\nreturn M\n' "$1" "$2" >"$dir/lua/init.lua"
  printf '# %s\n' "$1" >"$dir/README.md"
  git -C "$dir" init -q -b main
  git -C "$dir" add .
  git -C "$dir" -c user.name="Malenia" -c user.email="malenia@haligtree.co" commit -q -m "Plant the first seed"
}

make_repo haligtree "write Inde a love note before the anniversary"
make_repo raccoon-city "Claire still needs the shared playlist"
make_repo stormveil "find a better gate than the front one"
make_repo spencer-mansion "file the crest keys by room"
make_repo leyndell "polish the golden tree"

export DEMO_ROOTS="$sandbox/repos"
export DEMO_REPO="$sandbox/repos/haligtree"
export DEMO_LUA="$PWD/docs/tapes/demo.lua"
mkdir -p images/demo

if [ $# -eq 0 ]; then
  set -- $(ls docs/tapes/*.tape | xargs -n1 basename | sed 's/\.tape$//' | grep -v '^settings$')
fi

for tape in "$@"; do
  # a fresh state per take, so the title screen and first visits happen every time
  export XDG_STATE_HOME="$sandbox/state/$tape"
  echo "Recording $tape"
  vhs "docs/tapes/$tape.tape"
done
