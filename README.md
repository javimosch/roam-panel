# roam-panel

**Approve your remote agents from your phone.**

`roam-panel` is the control-plane hub for [roam](https://github.com/javimosch/roam) — the
tool that dispatches an autonomous agent to a box and lets you walk away. When a roam agent
hits a destructive command it **parks** and waits for approval. Today that means being at a
terminal with ssh. `roam-panel` closes that gap: agents report into the hub, it **emails you
the moment one parks** with one-tap approve/deny links, and you can **approve / deny / steer
/ stop** any agent from a mobile web page.

One **self-hostable machin binary** — an HTTP hub + SQLite + a mobile web panel, no Python,
no runtime. (Built in [machin](https://github.com/javimosch/machin), like roam itself.)

```
 remote box                       roam-panel (your server)                 your phone
┌─────────────┐  POST /v1/report ┌────────────────────────┐   email    ┌──────────────┐
│ roam worker │ ────────────────▶│  agents + journal + UI │ ─────────▶ │ tap approve/ │
│  --hub URL  │◀── /v1/decision ─│  one-tap signed links  │◀───────────│ deny         │
└─────────────┘                  └────────────────────────┘  /a?...&t= └──────────────┘
```

## What it does

- **Live view of every agent** — status, goal, iteration count, and the recent journal, for
  all engines (anthropic / openai / debri).
- **Approve / deny parked commands** — when an agent parks on a destructive command, the
  exact command shows up with Approve / Deny buttons, and you get an email with the same
  as one-tap signed links.
- **Steer & stop** — send a steering note or stop any live agent.

### One limitation, stated plainly

Per-command **approve/deny works only for the `anthropic` / `openai` engines** (roam's own
LLM tool-loop, run with `--confirm`). **`debri` (Devin/SWE) jobs can't park** — devin owns
its own permissions internally, so roam can't intercept individual commands. For debri
agents the panel shows live status + journal and lets you **stop** them, but not approve
individual commands. Run the LLM engine with `--confirm` for the full approval flow.

## Build

Needs the [machin](https://github.com/javimosch/machin) compiler on your `PATH`.

```bash
./build.sh        # dynamic build -> ./roam-panel
make release      # fully-static roam-panel-x86_64-linux
```

## Run

```bash
cp .env.example .env      # fill in the token + secret + Resend
export $(grep -v '^#' .env | xargs)
roam-panel token --gen    # mint a worker token -> set it as ROAM_HUB_TOKEN
roam-panel serve --port 8099
```

Then point a roam agent at it (the agent needs outbound HTTPS to the hub):

```bash
roam send --to my-vm --provider anthropic --confirm \
  --hub https://panel.roam.intrane.fr --hub-token "$ROAM_HUB_TOKEN" \
  --goal "clone repo X, run its tests, then git push a branch"
```

The agent reports in, parks on `git push`, you get an email → tap **Approve** → it proceeds.
Watch it live at `https://panel.roam.intrane.fr/`.

## CLI (agent-first)

stdout = JSON, stderr = structured errors, semantic exit codes. `roam-panel help-json` is the
self-describing catalog.

| Command | What |
|---|---|
| `serve --port N` | run the hub daemon |
| `list` | agents as JSON |
| `token [--gen]` | print the worker token, or mint a fresh one |

## HTTP API

| Route | Auth | Purpose |
|---|---|---|
| `POST /v1/report` | Bearer worker token | agent posts status + journal delta; fires the email on a new park |
| `GET /v1/decision?job=<id>` | Bearer worker token | agent polls for an approve/deny/stop/steer decision (consumed once) |
| `GET /` | basic-auth (proxy) | mobile panel |
| `POST /api/decide` | basic-auth (proxy) | panel approve/deny/stop/steer |
| `GET /a?j=&d=&e=&t=` | HMAC-signed | one-tap link → a POST **confirmation** page |
| `POST /a` | HMAC-signed | apply the one-tap decision |
| `GET /_health` | — | `{"ok":true,"service":"roam-panel"}` |

## Security

- **Worker auth:** a shared `ROAM_HUB_TOKEN` bearer, compared by SHA-256 hash.
- **One-tap links:** HMAC-SHA256 over `job|decision|exp` with a 30-min expiry. Email
  security scanners follow GET links, so `/a` GET only renders a **POST confirmation** — the
  state change happens on POST, which scanners don't submit.
- **Panel browsing** is expected to sit behind basic-auth at the reverse proxy.
- Approve runs a destructive command — the worker still enforces its own `--max-denials`
  budget as a backstop.
- All secrets via env, never committed; TLS terminated at the proxy.

---

*Part of the [roam](https://github.com/javimosch/roam) project. One self-hosted binary,
built with [machin](https://github.com/javimosch/machin).*
