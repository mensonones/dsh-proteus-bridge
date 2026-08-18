# dsh ↔ Proteus — run local Proteus on DeepSeek

A minimal [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) profile
that wires your local [Proteus](https://github.com/mensonones/Proteus) checkout into dsh and
adds a `/proteus <target>` command to start an autonomous continuous-vulnerability-research
campaign — on DeepSeek models, for **authorized** testing only.

This repo is **only the integration bridge**: one small command plugin plus the config that
connects dsh to Proteus. Proteus itself (skills, agents, MCP memory engine) is reused in place —
never bundled.

## How it works

`/proteus <target>` steers a coordinator kickoff into the session, so the single agent becomes
the Proteus coordinator and drives the loop (Observe → Map → Hypothesize → Prioritize → Delegate
→ Validate → Kill/Promote → Checkpoint → Replan), using:

| Proteus asset | Wired into dsh as |
|---|---|
| MCP engine (59 tools: memory, campaign, records, global learnings) | `@deepseek-ai/dsh-mcp-client` → `mcp__proteus__*` (zero-dep Node server, no install) |
| skills (recon, chaining, fuzzing, poc-exploit, waf-bypass, web-intel, …) | `@deepseek-ai/dsh-skill-filesystem` custom root |
| agents (skeptic, janus, maverick, artificer, …) | custom root → loadable role skills the agent adopts inline |

All wiring is in `.dsh/profiles/web/cordis.patch.yml`, gated on `PROTEUS_DIR`.

## What's here

| Path | Purpose |
|---|---|
| `packages/dsh-command-proteus/` | The plugin: registers the `/proteus <target>` command. |
| `.dsh/profiles/web/cordis.patch.yml` | Wires `/proteus` + the Proteus skills/agents/MCP (opt-in via `PROTEUS_DIR`). |
| `dsh-cybersec.sh` | Launcher: repo-local `DSH_HOME`, loads `.env`, boots the web UI. |
| `.env.example` | Template for `DEEPSEEK_API_KEY` and `PROTEUS_DIR`. |

## Setup

```bash
npm install
cp .env.example .env
```

Edit `.env`:

```bash
DEEPSEEK_API_KEY=sk-...                    # or set it in the web UI (Settings → Model)
PROTEUS_DIR=/home/you/dev/Proteus          # your local Proteus checkout
```

`PROTEUS_DIR` must contain `plugins/proteus/dist/mcp.js`. When it's unset, the Proteus entries
in `cordis.patch.yml` disable cleanly and the harness still boots (with just the `/proteus`
command, which then has nothing to coordinate).

## Run

```bash
./dsh-cybersec.sh                 # web UI at http://127.0.0.1:3000
```

Then, in a session:

```
/proteus localhost:8096
```

The default model is `deepseek-official / deepseek-v4-flash`; for real autonomous campaigns
prefer `deepseek-reasoner` (Settings → Model) — long multi-round runs are token-heavy, and
DeepSeek follows Proteus's elaborate contracts less reliably than Claude. Chimera/opencode swarm
expects Claude/opencode infra and likely won't orchestrate; the memory/record/campaign tools work.

## Notes

- Proteus is GPL-3.0 and referenced in place, never bundled — this repo (the bridge) stays MIT.
- Scope/ethics are enforced by Proteus's own coordinator contracts.
- Telemetry defaults to **DISABLED**; credentials and sessions stay local under `.dsh/`
  (gitignored). Only run against authorized, in-scope targets.
