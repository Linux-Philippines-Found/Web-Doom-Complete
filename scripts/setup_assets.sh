#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATIC="$ROOT/static"
mkdir -p "$STATIC" "$ROOT/.vendor"

# Your actual server layout:
FREEDOOM_DIR="${FREEDOOM_DIR:-$HOME/SerSD/Web_Doom_Server/freedoom}"
DOOMWEB_DIR="${DOOMWEB_DIR:-$ROOT/.vendor/doom-web}"

echo "== Freedoom Web asset installer =="
echo "Freedoom source: $FREEDOOM_DIR"
echo

if [ ! -d "$FREEDOOM_DIR/.git" ]; then
  echo "ERROR: Freedoom repository was not found:"
  echo "  $FREEDOOM_DIR"
  echo
  echo "Clone it with:"
  echo "  git clone https://github.com/freedoom/freedoom.git \"$FREEDOOM_DIR\""
  exit 1
fi

echo "[1/4] Updating browser engine reference"
if [ ! -d "$DOOMWEB_DIR/.git" ]; then
  git clone --depth 1 https://github.com/danborden1/doom-web.git "$DOOMWEB_DIR"
else
  git -C "$DOOMWEB_DIR" pull --ff-only
fi

for f in websockets-doom.js websockets-doom.wasm default.cfg freedoom1.wad; do
  test -f "$DOOMWEB_DIR/$f" || {
    echo "ERROR: expected upstream asset missing: $DOOMWEB_DIR/$f"
    exit 1
  }
done

echo "[2/4] Installing exact published browser engine assets"
# Keep the original filenames expected by the Emscripten loader.
cp "$DOOMWEB_DIR/websockets-doom.js" "$STATIC/websockets-doom.js"
cp "$DOOMWEB_DIR/websockets-doom.wasm" "$STATIC/websockets-doom.wasm"
cp "$DOOMWEB_DIR/default.cfg" "$STATIC/default.cfg"

# Compatibility copy for anyone expecting the old friendly name.
cp "$DOOMWEB_DIR/websockets-doom.js" "$STATIC/chocolate-doom.js"
cp "$DOOMWEB_DIR/websockets-doom.wasm" "$STATIC/chocolate-doom.wasm"

echo "[3/4] Installing Freedoom WADs"
copy_wad() {
  local name="$1"
  local candidates=(
    "$FREEDOOM_DIR/wads/$name"
    "$FREEDOOM_DIR/$name"
    "$FREEDOOM_DIR/build/$name"
  )
  for p in "${candidates[@]}"; do
    if [ -f "$p" ]; then
      cp "$p" "$STATIC/$name"
      echo "  copied $p -> static/$name"
      return 0
    fi
  done
  return 1
}

# Prefer the user's current Freedoom checkout. The web project also contains
# a known-good Freedoom 1 asset, used only as a fallback for Phase 1.
for wad in freedoom1.wad freedoom2.wad freedm.wad; do
  if [ -f "$STATIC/$wad" ]; then
    echo "  already present: $wad"
  elif ! copy_wad "$wad"; then
    if [ "$wad" = "freedoom1.wad" ]; then
      cp "$DOOMWEB_DIR/freedoom1.wad" "$STATIC/freedoom1.wad"
      echo "  fallback: copied published Freedoom 1 asset"
    else
      echo "  WARNING: $wad was not found/generated."
      echo "           Build the current Freedoom checkout with its documented build system."
    fi
  fi
done

echo "[4/4] Installing licenses and credits"
for f in COPYING FREEDOOM-COPYING.txt FREEDOOM-CREDITS.txt; do
  if [ -f "$DOOMWEB_DIR/$f" ]; then
    cp "$DOOMWEB_DIR/$f" "$ROOT/licenses/$f"
  fi
done
if [ -f "$FREEDOOM_DIR/COPYING" ]; then
  cp "$FREEDOOM_DIR/COPYING" "$ROOT/licenses/FREEDOOM-COPYING-CURRENT.txt"
fi

echo
echo "== Installed assets =="
ls -lh "$STATIC"/*.js "$STATIC"/*.wasm "$STATIC"/*.wad "$STATIC/default.cfg" 2>/dev/null || true
echo
echo "Run: bash scripts/check.sh"
