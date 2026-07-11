#!/usr/bin/env bash
# Build roam-panel: one native binary = agent-first CLI + the `serve` hub daemon
# (machweb HTTP + SQLite + mobile SSR panel). M0 has no wasm client (SSR-only);
# the reactive-wasm dashboard lands in M1. Needs the machin compiler on PATH.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
command -v "$MACHIN" >/dev/null 2>&1 || { echo "error: '$MACHIN' not found (set MACHIN=/path/to/machin)"; exit 1; }
mkdir -p build
"$MACHIN" encode src/machweb.src src/flags.src src/server.src src/main.src > build/roam-panel.mfl
"$MACHIN" build build/roam-panel.mfl -o roam-panel
echo "built ./roam-panel"
echo "  cli:    ./roam-panel help-json"
echo "  daemon: ROAM_HUB_TOKEN=… ./roam-panel serve --port 8099"
