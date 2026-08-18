---
name: recon-triage
description: Triage and prioritize reconnaissance output (nmap, httpx, subfinder, nuclei, dnsx, ffuf, Burp export) for an authorized bug-bounty or pentest engagement. Use when the user pastes scan output, a list of hosts/ports/endpoints, or asks "what should I look at first". Ranks attack surface by exploitability and impact, proposes concrete next probes, and never fabricates findings not present in the data.
---

# Recon triage

Turn raw recon into a ranked, actionable target list. You reason over the data the user
provides — you do not invent hosts, ports, or vulnerabilities that are not in it.

## Scope guard (always first)

Before suggesting any active probe, confirm the target is in an **authorized** scope
(bug-bounty program, signed engagement, or the user's own asset). If scope is unstated,
ask one question: "Confirma que esses alvos estão no escopo autorizado do programa?"
Passive analysis of already-collected data is fine; new active traffic needs that yes.

## Workflow

1. **Normalize.** Parse the input into a table: `host | port | service | tech/version | url | evidence`.
   Keep only facts present in the data. Mark anything inferred as `(inferred)`.
2. **Cluster.** Group by asset type: web apps, APIs, auth surfaces, admin panels, dev/staging,
   object storage, mail, VPN/edge, and third-party SaaS.
3. **Rank.** Score each cluster by `likelihood × impact`. Bump priority for:
   - Auth/session surfaces, password reset, SSO, OAuth callbacks.
   - Admin/debug/actuator/`.git`/`.env`/swagger/graphql introspection.
   - Outdated versions with public CVEs (name the CVE only if the version is shown).
   - Staging/dev hosts, wildcard subdomains, orphaned/forgotten services.
   - Anything with user-controllable IDs (IDOR/BOLA candidates).
4. **Next probes.** For the top targets, give 3–6 concrete, low-noise checks. Prefer
   read-only verification first (headers, error pages, auth requirements) before anything
   intrusive. Give exact commands the user can run themselves.
5. **Output.** A ranked list, each item: *why it matters*, *what to check*, *the command*.

## What not to do

- Don't claim a vulnerability exists from a version banner alone — call it a *candidate*.
- Don't suggest DoS, mass-scanning of out-of-scope ranges, or exploitation of third-party
  infrastructure the program doesn't own.
- Don't pad the list — 8 sharp targets beat 50 noisy ones.

## Handy verification commands (read-only first)

```bash
# tech + headers without hammering the host
httpx -silent -title -tech-detect -status-code -web-server -l hosts.txt

# check a single endpoint's auth posture
curl -sS -D - -o /dev/null 'https://TARGET/admin'

# nuclei with only safe, high-signal templates on an in-scope host
nuclei -u https://TARGET -tags exposure,misconfig,cve -severity medium,high,critical -rl 20
```
