# DeepSeek Harness — Bug Bounty & Cybersec profile

A self-contained [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`)
setup tuned for **authorized** bug-bounty and security research: recon triage, vulnerability
code review, attack-surface mapping, and disclosure reports.

Everything lives in this repo — profile, skills, and harness state all sit under `.dsh/`, so
nothing leaks into your global `~/.dsh`.

## ⚠️ Reality check on "security plugins"

If you were pointed at packages like `dsh-pentest`, `dsh-reverse-skill`, `dsh-skill-pack-security`,
`helm-d`, `dsh-guardian`, `dsh-plugin-gate`, or an `awesome-deepseek-harness` list — **those do
not exist on npm** (checked). Only `@deepseek-ai/dsh` and its scoped `@deepseek-ai/dsh-*` plugins
are real. Running `dsh plugin add dsh-pentest` will fail, and blindly installing unverified
"security plugins" is exactly the supply-chain risk to avoid. This repo instead adds security
capability the real, supported way: **Skills** (`SKILL.md` files) plus a workspace persona
(`AGENTS.md`) — no third-party plugins required.

## What's here

| Path | Purpose |
|---|---|
| `AGENTS.md` | Always-on persona + ethics/scope guardrails (auto-loaded every session). |
| `packages/dsh-skill-pack-cybersec/` | **The skills, packaged as a real, publishable `dsh` plugin** (source of truth). |
| `skills/` | Convenience symlink → the plugin's `skills/` for easy editing. |
| `.dsh/profiles/web/cordis.patch.yml` | Wires the plugin into the `web` profile (the standard insert). |
| `dsh-cybersec.sh` | Launcher: pins `DSH_HOME` to this repo, loads `.env`, boots the web UI. |
| `.env.example` | Template for `DEEPSEEK_API_KEY` / `DEEPSEEK_BASE_URL`. |

The skills run **locally through the plugin** — the exact same code path a `dsh plugin add`
consumer gets. They're already packaged; publishing is one command away (see below).

### Skills

- **recon-triage** — rank nmap/httpx/nuclei/Burp output by exploitability; propose next probes.
- **vuln-code-review** — find exploitable bugs in code/diffs with traced source→sink evidence.
- **web-attack-surface** — map one app/API into a prioritized, decisive test plan.
- **http-recon-runner** — *agentic*: run read-only, rate-limited recon on in-scope targets.
- **bounty-report** — draft a triager-ready report with honest CVSS and remediation.

## Setup

```bash
# 1. install the real harness (already done if node_modules/ exists)
npm install

# 2. add your DeepSeek API key
cp .env.example .env    # then edit .env
```

## Run

```bash
./dsh-cybersec.sh                 # boot the web UI (http://localhost:3000 by default)
./dsh-cybersec.sh --port 8080     # custom port
./dsh-cybersec.sh headless "triage this nmap output: ..."   # one-shot, prints the answer
```

No API key in `.env`? You can also set it in the web UI under **Settings → Model**. The default
model is `deepseek-official / deepseek-v4-flash`; switch models there too.

### Use a local model (Ollama) instead

Ollama exposes an OpenAI-compatible API, so point the base URL at it in `.env`:

```bash
DEEPSEEK_BASE_URL=http://localhost:11434/v1
DEEPSEEK_API_KEY=ollama
```

## Privacy note

The bundled OpenTelemetry plugin defaults to **`DISABLED`** (`DSH_TELEMETRY_MODE`), so no session
data is sent anywhere unless you explicitly opt in. Credentials and sessions are stored locally
under `.dsh/` (gitignored).

## Adding your own skill

Drop a new `packages/dsh-skill-pack-cybersec/skills/<kebab-name>/SKILL.md`:

```markdown
---
name: my-skill
description: One or two sentences the model uses to decide when to load this skill.
---

# Title
...instructions...
```

It's picked up automatically (the plugin watches its bundled skills root) — no restart needed.
`name` must be kebab-case. Verify with `node packages/dsh-skill-pack-cybersec/test-load.mjs`.

## Turning this into a published plugin

The skills already live in a proper plugin package (`packages/dsh-skill-pack-cybersec/`), wired
into the profile the standard way. To share it:

```bash
cd packages/dsh-skill-pack-cybersec
npm publish            # or: pnpm publish  (rename the package to your own npm scope first)
```

A consumer then installs it exactly like any dsh plugin:

```bash
dsh plugin --profile web add dsh-skill-pack-cybersec
# then add to that profile's cordis.patch.yml:
#   - insert:
#       - id: skill-pack-cybersec
#         name: dsh-skill-pack-cybersec
```

That's the same insert already in this repo's `.dsh/profiles/web/cordis.patch.yml`.

## Proteus integration (ported in place)

The full [Proteus](https://github.com/mensonones/Proteus) capability set is wired into this
profile by **reusing the Proteus repo in place** (no duplication), via
`.dsh/profiles/web/cordis.patch.yml`:

| Proteus asset | How it's exposed in dsh | Verified |
|---|---|---|
| MCP engine (59 tools: memory, campaign, chimera, records, global learnings) | `dsh-mcp-client` → `mcp__proteus__*` (zero-dep Node server, no install) | connects, child process spawns |
| 18 skills (recon, chaining, fuzzing, poc-exploit, waf-bypass, web-intel, …) | `dsh-skill-filesystem` custom root → discovered as skills | 18 discovered |
| 11 agents (skeptic, janus, maverick, artificer, …) | custom root → loadable **role skills** the single agent adopts inline | 11 discovered |
| templates + scripts (mobile_toolchain.py, extract_mobile_artifacts.py, tor) | resolved in place, relative to each skill's dir | in-place |

**Opt-in.** The integration is off by default and enabled per-machine by setting `PROTEUS_DIR`
in your `.env` to a [Proteus](https://github.com/mensonones/Proteus) checkout:

```bash
PROTEUS_DIR=/path/to/Proteus
```

When unset, the three Proteus entries in `.dsh/profiles/web/cordis.patch.yml` are cleanly
disabled and the harness runs standalone (the local cybersec pack only). Proteus is GPL-3.0 and
is referenced in place, never bundled — this repo stays MIT.

**Autonomous entry point.** `packages/dsh-command-proteus` registers a `/proteus <target>`
slash command (mirrors Claude Code's `/proteus`): it steers a coordinator kickoff prompt into
the session so the single agent becomes the Proteus coordinator and runs the loop
(Observe→Map→Hypothesize→Prioritize→Delegate→Validate→Kill/Promote→Checkpoint→Replan) on its own,
using the `mcp__proteus__*` memory tools and adopting role skills inline for each front. Calling
a raw tool like `proteus_init` does one step; `/proteus` starts the whole campaign.

**Honest caveats.** Loading is proven; *execution fidelity* depends on the model. DeepSeek
(especially `v4-flash`) may not follow Proteus's elaborate multi-round / adversarial / chimera
contracts as well as Claude — use a stronger model (`deepseek-reasoner`) for real campaigns.
Proteus skills call tools by short name (`proteus_init`); dsh exposes them as
`mcp__proteus__proteus_init` — if the model reports a tool as missing, that mapping is the thing
to check. Chimera/opencode swarm expects Claude/opencode infra and likely won't orchestrate; the
memory/record/campaign tools (plain SQLite) should work.

## Scope & ethics

This profile assists **authorized** testing only. `AGENTS.md` makes the agent confirm scope
before generating traffic and refuse DoS, mass-targeting, and exploitation of systems you don't
have permission to test. Keep it that way.
