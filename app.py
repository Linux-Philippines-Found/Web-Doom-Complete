#!/usr/bin/env python3
import os
from flask import Flask, send_from_directory, jsonify, make_response

BASE = os.path.dirname(os.path.abspath(__file__))
STATIC = os.path.join(BASE, "static")

app = Flask(__name__, static_folder=STATIC, static_url_path="/static")

@app.after_request
def headers(resp):
    # Useful for WebAssembly and cross-origin isolation when this app is served directly.
    # These are intentionally not COOP/COEP because some browser deployments/tunnels
    # and third-party assets can break under strict cross-origin isolation.
    resp.headers["Cache-Control"] = "public, max-age=3600"
    return resp

@app.get("/")
def index():
    return send_from_directory(STATIC, "index.html")

@app.get("/api/status")
def status():
    assets = {}
    for name in ("chocolate-doom.js", "chocolate-doom.wasm", "freedoom1.wad", "freedoom2.wad", "freedm.wad"):
        p = os.path.join(STATIC, name)
        assets[name] = {"present": os.path.isfile(p), "bytes": os.path.getsize(p) if os.path.isfile(p) else 0}
    return jsonify({
        "ok": True,
        "server": "Freedoom Web ARM32 Edition",
        "engine": "Chocolate Doom WebAssembly",
        "assets": assets
    })

@app.get("/healthz")
def healthz():
    return "ok\n"

@app.get("/assets/<path:name>")
def assets(name):
    return send_from_directory(STATIC, name)

@app.get("/freedoom/levels/<path:filename>")
def serve_levels(filename):
    # This points directly to the 'freedoom/levels' folder relative to app.py
    levels_dir = os.path.join(BASE, "freedoom", "levels")
    return send_from_directory(levels_dir, filename)
    
@app.get("/static/freedoom1.wad")
def serve_large_wad():
    response = make_response(send_from_directory(STATIC, "freedoom1.wad"))
    # Tell the browser it's a raw binary data stream
    response.headers["Content-Type"] = "application/octet-stream"
    response.headers["Accept-Ranges"] = "bytes"
    return response

@app.get("/static/<path:filename>")
def force_serve_static(filename):
    return send_from_directory(STATIC, filename)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
