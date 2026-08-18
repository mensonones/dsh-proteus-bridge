---
name: http-recon-runner
description: Agentic helper that actually runs read-only reconnaissance commands (curl, httpx, dig, whatweb, nuclei in safe modes) against an authorized target using the bash tool, then feeds results into recon-triage. Use only when the user explicitly asks you to run recon and has confirmed scope. Refuses intrusive/exploitation commands and out-of-scope targets.
---

# HTTP recon runner (agentic)

This skill lets the agent execute recon itself via the `bash` tool, instead of only advising.
It is deliberately conservative: **read-only, low-rate, in-scope only.**

## Preconditions — do not skip

1. The user has named a target and **explicitly confirmed it is authorized** (their asset or
   an active bug-bounty scope). No confirmation → do not run anything; ask first.
2. The target host is what you run against — not its third-party dependencies, CDNs, or
   linked domains.

If either fails, stop and explain rather than proceeding.

## Tooling Policy — provision what the job needs

**You are not limited to pre-installed tools.** Reach for the right instrument for the task
and, when it is missing but materially useful, **install it yourself** — you have a writable
workspace, `/tmp`, and network access. Do not settle for hand-rolled `curl`/`dig` loops when
a purpose-built tool does the job better. Do not silently install: **announce which tool and
why in one line**, then proceed.

Prefer these when present (install on demand otherwise):

- **HTTP / fingerprint:** `httpx`, `whatweb`, `wafw00f`
- **Ports:** `naabu` (`-s connect`, no root) or `nmap`
- **Templated checks / CVE / exposure:** `nuclei`
- **DNS / subdomains:** `dnsx`, `subfinder`, `dig`, `host`
- **Content / fuzzing (read-only, rate-limited):** `ffuf`, `gobuster`, `feroxbuster`
- **TLS:** `openssl s_client`, `testssl.sh`, `tlsx`
- **Glue:** `curl`, `jq`, `unzip`

### How to install temporarily (prefer no-sudo, cleanable)

1. **The fetcher — first choice for any GitHub-released binary.** Handles the
   ProjectDiscovery set (`httpx`, `naabu`, `nuclei`, `subfinder`, `dnsx`, `tlsx`, `katana`)
   **and** common non-PD tools (`ffuf`, `gobuster`, `feroxbuster`). Static binaries,
   checksum-verified, into `tools/bin/` (already on PATH):
   ```bash
   command -v ffuf >/dev/null 2>&1 || "${DSH_SKILL_PACK_DIR:?}/tools/fetch-recon.sh" ffuf
   ```
2. **Go tools not covered above** — `GOBIN="$PWD/.tools" go install <module>@latest` (Go is
   available); then add `.tools` to PATH for the run.
3. **Python tools** — `pipx install <tool>` (isolated, no sudo).
4. **Distro packages** (`nmap`, `whatweb`, `wafw00f`, `jq`) — `sudo apt-get install -y <pkg>`
   **only if sudo is available**; if not, say so and fall back to a static binary or an
   available alternative (e.g. `naabu` instead of `nmap`).
5. **Anything else** — download the official release binary (verify the published checksum)
   into `./.tools/` or `tools/bin/`, `chmod +x`, run from there.

**Trusted sources only** (official project releases, distro repos, language package managers),
**verify integrity** when a checksum is published, and treat installs as **ephemeral**: note
what you added and clean up afterwards (`"${DSH_SKILL_PACK_DIR}/tools/fetch-recon.sh" --clean`,
`rm -rf ./.tools`). If an install fails or needs sudo you lack, continue with what is available
and **mark the gap** in your findings rather than going silent.

## A typical read-only pass

```bash
# 1) ports first — what is even listening (connect scan, no root)
naabu -host TARGET -p 1-10000 -s connect -silent -rate 200      # or: nmap -sT -Pn TARGET

# 2) HTTP fingerprint on the open web ports
echo https://TARGET | httpx -silent -title -tech-detect -status-code -web-server -tls-grab

# 3) DNS / subdomains (real domains, not localhost)
dnsx -silent -a -aaaa -cname -txt -resp -d TARGET
subfinder -silent -d TARGET

# 4) safe templated checks
nuclei -u https://TARGET -tags exposure,misconfig,cve -severity medium,high,critical -rl 20 -timeout 10

# 5) manual verification where a tool lacks nuance
dig +short TARGET ; curl -sS -D - -o /dev/null --max-time 15 https://TARGET/
```

Rate-limit everything (`-rl`), cap timeouts, and prefer a single pass. Save raw output to a
file in the workspace, then hand it to the **recon-triage** skill for ranking.

## Forbidden — refuse these

- Exploitation payloads, brute force, credential stuffing, password spraying.
- DoS, high-rate scans, or fuzzing that generates heavy traffic.
- SQLi/XSS/command-injection payload delivery against live third-party targets.
- Anything against a host the user has not confirmed is in scope.
- Downloading and executing remote scripts from untrusted sources.

For those, explain that they're out of this skill's remit and, if legitimate for the user's
own lab, tell them how to do it themselves in an environment they own.

## Flow

1. Confirm scope. 2. Run the read-only set, tee output to `./recon-<target>-<date>.txt`.
3. Summarize what responded. 4. Invoke recon-triage on the saved output for a ranked plan.
