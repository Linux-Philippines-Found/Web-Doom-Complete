#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "== Freedoom Web preflight =="

python3 -m py_compile app.py
echo "PASS: Python syntax"

for f in static/index.html static/manifest.webmanifest static/sw.js; do
  test -s "$f" && echo "PASS: $f" || { echo "FAIL: $f"; exit 1; }
done

for f in static/websockets-doom.js static/websockets-doom.wasm static/default.cfg static/freedoom1.wad; do
  test -s "$f" && echo "PASS: $f" || { echo "FAIL: missing $f"; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
import struct
wasm=Path("static/websockets-doom.wasm").read_bytes()
assert wasm[:4] == b"\x00asm", "bad WASM magic"
assert struct.unpack("<I", wasm[4:8])[0] == 1, "unexpected WASM version"
wad=Path("static/freedoom1.wad").read_bytes()
assert wad[:4] == b"IWAD", "freedoom1.wad is not an IWAD"
print("PASS: WASM header")
print("PASS: Freedoom IWAD header")
PY

if command -v node >/dev/null 2>&1; then
  node --check static/websockets-doom.js
  echo "PASS: upstream engine JavaScript syntax"
fi

echo
echo "Optional current Freedoom WADs:"
for f in static/freedoom2.wad static/freedm.wad; do
  if [ -s "$f" ]; then echo "PASS: $f"; else echo "NOTE: $f not installed"; fi
done

echo
echo "Start test:"
echo "  gunicorn --workers 1 --bind 0.0.0.0:6060 app:app"
echo "Then open:"
echo "  http://127.0.0.1:6060"
echo "and select PHASE 1."
