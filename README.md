# DeepSeek Harness — autonomous Proteus runner for bug bounty & cybersec

A self-contained [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`)
profile that runs [Proteus](https://github.com/mensonones/Proteus) continuous
vulnerability-research **on DeepSeek models** — for **authorized** testing only.

Type `/proteus <target>` and the single agent becomes the Proteus coordinator and drives the
whole campaign (Observe → Map → Hypothesize → Prioritize → Delegate → Validate → Kill/Promote →
Checkpoint → Replan), using the Proteus skills/agents and its `mcp__proteus__*` memory engine.

Everything lives in this repo — profile, command plugin, and harness state all sit under the
repo, so nothing leaks into your global `~/.dsh`.

## ⚠️ Reality check on "dsh security plugins"

Only `@deepseek-ai/dsh` and its scoped `@deepseek-ai/dsh-*` plugins are real. Packages like
`dsh-pentest`, `dsh-reverse-skill`, `helm-d`, `dsh-guardian`, `awesome-deepseek-harness` **do
not exist on npm** — don't `dsh plugin add` them. Security capability here comes the supported
way: one small command plugin + the real Proteus engine wired in by config.

## What's here

| Path | Purpose |
|---|---|
| `packages/dsh-command-proteus/` | **The one plugin**: registers the `/proteus <target>` autonomous-coordinator command. |
| `dsh-cybersec.sh` | Launcher: repo-local `DSH_HOME`, `tools/bin` on PATH, XDG dirs, `.env` loading. |
| `AGENTS.md` | Always-on persona: scope/ethics guardrails + tooling autonomy. |
| `tools/fetch-recon.sh` | Checksum-verified static-binary fetcher (httpx, naabu, nuclei, subfinder, dnsx, ffuf, gobuster). |
| `.dsh/profiles/web/cordis.patch.yml` | Profile wiring: the `/proteus` command + the opt-in Proteus integration. |
| `.env.example` | Template for `DEEPSEEK_API_KEY` and `PROTEUS_DIR`. |

## Setup

```bash
npm install                 # installs dsh + the local command plugin
cp .env.example .env         # then edit: add DEEPSEEK_API_KEY and PROTEUS_DIR
```

## Run

```bash
./dsh-cybersec.sh                 # web UI at http://127.0.0.1:3000
./dsh-cybersec.sh --port 8080     # custom port
./dsh-cybersec.sh headless "..."  # one-shot, prints the answer
```

Add your `DEEPSEEK_API_KEY` in `.env` or in the web UI under **Settings → Model**. The default
model is `deepseek-official / deepseek-v4-flash`; for real autonomous campaigns prefer a stronger
model (`deepseek-reasoner`) — long multi-round runs are token-heavy.

Then, in a session:

```
/proteus localhost:8096
```

## Proteus integration (opt-in)

The Proteus engine is wired in by **reusing the Proteus repo in place** (no duplication), and is
**off unless `PROTEUS_DIR` is set** in `.env`:

```bash
PROTEUS_DIR=/path/to/Proteus
```

| Proteus asset | How it's exposed in dsh |
|---|---|
| MCP engine (59 tools: memory, campaign, chimera, records, global learnings) | `@deepseek-ai/dsh-mcp-client` → `mcp__proteus__*` (zero-dep Node server, no install) |
| skills (recon, chaining, fuzzing, poc-exploit, waf-bypass, web-intel, …) | `@deepseek-ai/dsh-skill-filesystem` custom root → discovered as skills |
| agents (skeptic, janus, maverick, artificer, …) | custom root → loadable **role skills** the single agent adopts inline |
| templates + scripts | resolved in place, relative to each skill's dir |

When `PROTEUS_DIR` is unset, those three entries in `cordis.patch.yml` disable cleanly and the
harness boots standalone. Proteus is GPL-3.0 and referenced in place, never bundled — this repo
stays MIT.

**Caveat:** DeepSeek (especially `v4-flash`) won't follow Proteus's elaborate contracts as well
as Claude. Use `deepseek-reasoner` for serious campaigns. Chimera/opencode swarm expects
Claude/opencode infra and likely won't orchestrate; the memory/record/campaign tools work.

## Tooling autonomy

The agent may provision recon tools on demand — announced, checksum-verified, no sudo — into
`tools/bin` (already on PATH). `AGENTS.md` grants this; `tools/fetch-recon.sh` does the fetch:

```bash
tools/fetch-recon.sh httpx naabu nuclei ffuf   # subset
tools/fetch-recon.sh --clean                    # remove them
```

Recon tools' config/templates are redirected to `tools/.config` (XDG) so the workspace-write
sandbox doesn't deny `~/.config` writes.

## Local model (Ollama) & privacy

Point at an OpenAI-compatible endpoint in `.env` to use a local model:

```bash
DEEPSEEK_BASE_URL=http://localhost:11434/v1
DEEPSEEK_API_KEY=ollama
```

Telemetry defaults to **DISABLED** (`DSH_TELEMETRY_MODE`); credentials and sessions stay local
under `.dsh/` (gitignored).

## Scope & ethics

For **authorized** testing only. `AGENTS.md` makes the agent confirm scope before generating
traffic and refuse DoS, mass-targeting, and exploitation of systems you don't have permission to
test. Keep it that way.
