#!/usr/bin/env bash
# Build roam-panel: a wasm client (the live dashboard, from view.src) + one native
# binary that is the agent-first CLI + the `serve` hub daemon which serves that wasm.
# The client and the SSR server render byte-identically (shared view.src). Needs the
# machin compiler + zig (for --target wasm).
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
command -v "$MACHIN" >/dev/null 2>&1 || { echo "error: '$MACHIN' not found (set MACHIN=/path/to/machin)"; exit 1; }
mkdir -p build

# 1. wasm client: shared view + the client entry.
"$MACHIN" encode src/view.src src/client.src > build/client.mfl
"$MACHIN" build build/client.mfl --target wasm -o app.wasm
echo "built ./app.wasm ($(wc -c < app.wasm) bytes)"

# 2. native binary: frameworks + shared view + server + CLI.
"$MACHIN" encode src/machweb.src src/flags.src src/view.src src/accounts.src src/server.src src/main.src > build/roam-panel.mfl
"$MACHIN" build build/roam-panel.mfl -o roam-panel
echo "built ./roam-panel"
echo "  cli:    ./roam-panel help-json"
echo "  daemon: ROAM_HUB_TOKEN=… ./roam-panel serve --port 8099"
