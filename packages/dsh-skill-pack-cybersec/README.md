# dsh-skill-pack-cybersec

A [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) plugin that
bundles a pack of **bug-bounty / cybersecurity Skills** and registers them as an isolated
filesystem skill provider. For **authorized** security testing only.

It does not reimplement discovery — it mounts `@deepseek-ai/dsh-skill-filesystem` pointed at
this package's bundled `skills/` directory, with default roots off, under the provider name
`cybersec-skills`.

## Skills

| Skill | Purpose |
|---|---|
| `recon-triage` | Rank recon output (nmap/httpx/nuclei/Burp) by exploitability; propose next probes. |
| `vuln-code-review` | Find exploitable bugs in code/diffs with traced source→sink evidence. |
| `web-attack-surface` | Map one app/API into a prioritized, decisive test plan. |
| `http-recon-runner` | Agentic: run read-only, rate-limited recon on in-scope targets. |
| `bounty-report` | Draft a triager-ready disclosure report with honest CVSS. |

## Install

```bash
# into a dsh profile (forwards to pnpm in the profile dir)
dsh plugin --profile web add dsh-skill-pack-cybersec
```

Then insert it into that profile's `cordis.patch.yml`:

```yaml
- insert:
    - id: skill-pack-cybersec
      name: dsh-skill-pack-cybersec
```

Config (all optional):

```yaml
- insert:
    - id: skill-pack-cybersec
      name: dsh-skill-pack-cybersec
      config:
        providerName: cybersec-skills   # provider name on ctx.skills
        watch: true                     # watch bundled skills for edits
```

## Peer dependencies

`@deepseek-ai/dsh-skill-filesystem`, `@deepseek-ai/dsh-skill`, `@deepseek-ai/cordis` — all
provided by a standard `dsh` installation.

## Test

```bash
node test-load.mjs   # mounts the registry + this plugin, asserts all 5 skills load
```

## License

MIT. Assists authorized testing only; the skills refuse DoS, mass-targeting, and exploitation
of systems you don't have permission to test.
