# Freedoom Web — Self-Hosted Browser Edition

A self-hosted browser game using:
- Flask + Gunicorn
- HTML/CSS/JavaScript
- Chocolate Doom compiled to WebAssembly
- Freedoom free/open game data
- Optional PWA/offline caching
- No id Software proprietary IWADs

## ARM32 Termux

Your ARM32 Termux server does **not** need to execute WebAssembly. The server only sends:
- HTML
- JavaScript
- WASM
- WAD files

The visitor's browser executes the WASM. This means the server architecture is suitable for ARM32.

Do NOT try to compile the WASM engine on the ARM32 Termux machine unless you specifically want to experiment with that. `setup.sh` uses a prebuilt browser engine.

## 1. Clone Freedoom on the server

```bash
git clone https://github.com/freedoom/freedoom.git
```

Then place the clone beside this project, or tell the setup script where it is:

```bash
export FREEDOOM_DIR="$HOME/SerSD/Web_Doom_Server/freedoom"
```

The setup script can obtain release WADs when generated WAD files are not available in the clone.

## 2. Install Python packages

```bash
python3 -m pip install -r requirements.txt
```

If Termux blocks a global pip install, use a venv:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

## 3. Install browser engine + Freedoom data

```bash
bash scripts/setup_assets.sh
```

The script:
1. Uses the Freedoom repository you cloned.
2. Retrieves the official Freedoom release WADs when necessary.
3. Retrieves the published Chocolate Doom WebAssembly browser artifacts.
4. Copies only the required local runtime assets into `static/`.

No Doom/Ultimate Doom/Doom II proprietary IWAD is included.

## 4. Run

Development:

```bash
python3 app.py
```

Production:

```bash
gunicorn --workers 1 --bind 0.0.0.0:8080 app:app
```

Use one worker first on ARM32. The actual game runs in the visitor's browser.

## 5. Cloudflare temporary URL

With `cloudflared` installed:

```bash
cloudflared tunnel --url http://127.0.0.1:8080
```

Cloudflare will print a temporary `trycloudflare.com` URL.

## Features

- Doom-style frontend
- Freedoom Phase 1
- Freedoom Phase 2
- FreeDM
- Keyboard controls
- Touch controls
- Fullscreen
- Pointer lock where supported
- Local browser caching
- PWA install metadata
- Offline service worker after first successful cache
- Save/load buttons via browser-local storage helpers
- Engine status diagnostics
- Server `/api/status`
- No remote runtime dependency after assets are installed
- Mobile-friendly layout
- Accessible UI controls
- License/credits section

## Important licensing note

The engine and game data have separate licenses. Keep the included license/attribution files with the deployment.

This project intentionally does not ship:
`doom.wad`, `doom1.wad`, `doom2.wad`, or other proprietary id Software game data.

No project can guarantee immunity from erroneous platform takedowns, but this distribution is designed around the documented free/open components and preserves their license notices.

## Directory

```text
freedoom-web-arm32/
├── app.py
├── requirements.txt
├── README.md
├── static/
│   ├── index.html
│   ├── manifest.webmanifest
│   ├── sw.js
│   └── assets installed by setup_assets.sh
├── scripts/
│   └── setup_assets.sh
└── licenses/
    └── THIRD-PARTY-NOTICES.txt
```


## Why the launcher is structured this way

The launcher follows the sequence used by the published `danborden1/doom-web`
browser build: `noInitialRun`, preload the IWAD/config in `preRun`, wait for
`onRuntimeInitialized`, then call `callMain()` with `-iwad` and the config.
This avoids the WASM race/fetch failure caused by trying to start the engine
before its virtual filesystem and runtime are ready.

The engine files are deliberately kept under their upstream names:
`websockets-doom.js` and `websockets-doom.wasm`.

`default.cfg` is also installed because the reference launch command uses it.
