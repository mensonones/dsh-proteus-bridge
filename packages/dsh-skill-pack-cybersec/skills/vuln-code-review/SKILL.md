---
name: vuln-code-review
description: LLM-assisted security review of source code, diffs, or snippets to find real, exploitable vulnerabilities (injection, authz/IDOR, SSRF, deserialization, path traversal, auth/crypto flaws, secrets, race conditions). Use when the user shares code or a diff and asks for a security review, threat model, or "where are the bugs". Reports only defensible findings with data-flow evidence, and writes remediation — not exploit weaponization against third parties.
---

# Vulnerability code review

Find security bugs a maintainer would fix, with enough evidence to act on. Optimize for
**true positives with a traced source→sink path**, not a checklist dump.

## Method

1. **Map the surface.** Identify trust boundaries: request handlers, deserializers, template
   rendering, DB access, file/OS access, outbound requests, authn/authz middleware.
2. **Follow tainted data.** For each candidate, trace: `source (user input) → transformations
   → sink (query/exec/render/fetch/path)`. A finding needs a plausible path; if a sanitizer
   or framework escaping breaks the chain, say so and drop it.
3. **Check the high-value classes:**
   - **Injection:** SQL/NoSQL, OS command, LDAP, template (SSTI), header/CRLF.
   - **AuthZ:** missing ownership checks (IDOR/BOLA), role checks after the fact, mass
     assignment, tenant isolation gaps.
   - **AuthN/session:** weak token generation, JWT `alg` confusion, missing expiry, fixation.
   - **SSRF / path traversal / open redirect**, especially where a URL or path is user-set.
   - **Deserialization / prototype pollution / unsafe reflection.**
   - **Crypto:** hardcoded keys, ECB, static IV, weak hashing for passwords, `Math.random`
     for secrets.
   - **Secrets in code**, debug endpoints, verbose errors leaking stack/PII.
   - **Race conditions / TOCTOU** on auth, balance, or file operations.

## Reporting each finding

```
[SEVERITY] Title
File:line
Source → Sink: <the traced path>
Why exploitable: <preconditions, who can trigger it>
PoC sketch: <minimal request/input that demonstrates it — defensive, against the user's own code>
Fix: <specific remediation, ideally a code diff>
Confidence: high | medium | low
```

Rank by real-world impact. Separate **confirmed** (path fully traced in the shown code) from
**needs-context** (depends on code not shown — say exactly what you'd need to confirm).

## Discipline

- No hand-waving. "User input reaches `eval`" must point at the lines.
- Don't invent framework behavior — if unsure whether an ORM parameterizes, say so.
- Remediation over exploitation. PoCs are minimal and scoped to validating the bug in the
  user's own codebase, not to attacking live third-party systems.
- If the diff is clean, say it's clean. A short "no material findings, here's what I checked"
  is a valid result.
