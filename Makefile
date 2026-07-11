# roam-panel — build targets. Requires the `machin` compiler + zig (for --target wasm).
VERSION ?= 0.2.0
SRCS = src/machweb.src src/flags.src src/view.src src/server.src src/main.src

.PHONY: build release clean

# Dynamic build (wasm client + native binary that links host libsqlite3 + OpenSSL).
build:
	./build.sh

# Release: the wasm dashboard + a fully-static native binary (bundles SQLite + OpenSSL
# + a CA store; runs FROM scratch on any x86-64 Linux). Deploy BOTH files together —
# the daemon serves app.wasm from its working directory.
release:
	mkdir -p build
	machin encode src/view.src src/client.src > build/client.mfl
	machin build build/client.mfl --target wasm -o app.wasm
	machin encode $(SRCS) > build/roam-panel.mfl
	machin build --static build/roam-panel.mfl -o roam-panel-x86_64-linux
	sha256sum roam-panel-x86_64-linux app.wasm > roam-panel-x86_64-linux.sha256
	@echo "built roam-panel-x86_64-linux ($$(du -h roam-panel-x86_64-linux | cut -f1), static) + app.wasm ($$(du -h app.wasm | cut -f1))"

clean:
	rm -f roam-panel roam-panel-x86_64-linux roam-panel-x86_64-linux.sha256 app.wasm build/*.mfl
