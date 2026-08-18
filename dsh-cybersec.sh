#!/usr/bin/env bash
# Launch the DeepSeek Harness cybersec/bounty profile, self-contained in this repo.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

# Keep all harness state (profiles, credentials, sessions) inside the repo.
export DSH_HOME="$REPO/.dsh"

# Load API key / base URL / PROTEUS_DIR if a local .env exists (never commit it).
if [[ -f "$REPO/.env" ]]; then
  set -a; . "$REPO/.env"; set +a
fi

if [[ -z "${DEEPSEEK_API_KEY:-}" ]]; then
  echo "!! DEEPSEEK_API_KEY not set. Copy .env.example to .env and add your key," >&2
  echo "   or set it in the web UI under Settings -> Model after launch." >&2
fi

# Optional Proteus integration (opt-in). Set PROTEUS_DIR in .env to a Proteus
# checkout to enable its MCP engine + skills + agents; unset = cleanly disabled.
if [[ -n "${PROTEUS_DIR:-}" ]]; then
  if [[ -f "$PROTEUS_DIR/plugins/proteus/dist/mcp.js" ]]; then
    export PROTEUS_DIR
    echo "   Proteus integration: enabled ($PROTEUS_DIR)" >&2
  else
    echo "!! PROTEUS_DIR set but $PROTEUS_DIR/plugins/proteus/dist/mcp.js not found — Proteus disabled." >&2
    unset PROTEUS_DIR
  fi
fi

DSH="$REPO/node_modules/.bin/dsh"
[[ -x "$DSH" ]] || { echo "!! dsh not installed. Run: npm install" >&2; exit 1; }

# Default to the web UI. Flags (e.g. --port 8080) go to the web app; a bare
# subcommand (e.g. `headless "task"`) is passed straight to the launcher.
if [[ $# -eq 0 ]]; then
  exec "$DSH" web
elif [[ "$1" == -* ]]; then
  exec "$DSH" web "$@"
else
  exec "$DSH" "$@"
fi
