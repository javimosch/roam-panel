# roam-panel — build targets. Requires the `machin` compiler (github.com/javimosch/machin).
VERSION ?= 0.1.0
SRCS = src/machweb.src src/flags.src src/server.src src/main.src

.PHONY: build release clean

# Dynamic build (links libsqlite3 + OpenSSL from the host).
build:
	./build.sh

# Fully-static release binary (bundles SQLite + OpenSSL + a CA store; runs FROM scratch
# on any x86-64 Linux). This is the artifact attached to releases / deployed to dk1.
release:
	mkdir -p build
	machin encode $(SRCS) > build/roam-panel.mfl
	machin build --static build/roam-panel.mfl -o roam-panel-x86_64-linux
	sha256sum roam-panel-x86_64-linux > roam-panel-x86_64-linux.sha256
	@echo "built roam-panel-x86_64-linux ($$(du -h roam-panel-x86_64-linux | cut -f1), static)"

clean:
	rm -f roam-panel roam-panel-x86_64-linux roam-panel-x86_64-linux.sha256 build/*.mfl
