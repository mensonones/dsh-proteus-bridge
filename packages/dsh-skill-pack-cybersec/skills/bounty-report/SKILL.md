---
name: bounty-report
description: Draft a professional bug-bounty / vulnerability disclosure report from a confirmed finding. Use when the user has a validated bug and wants a submission for HackerOne/Bugcrowd/Intigriti or a private program. Produces title, summary, steps to reproduce, impact, CVSS v3.1 vector, and remediation — grounded strictly in the evidence provided, with no inflated severity.
---

# Bounty report writer

Turn a confirmed finding into a report a triager can validate in minutes and rate fairly.

## Required inputs (ask for whatever is missing)

- Target/asset and the program it belongs to.
- Vulnerability class and the exact affected endpoint/parameter/component.
- Reproduction evidence: requests/responses, payloads, screenshots, or a script.
- Observed impact (what you actually achieved, not what's theoretically possible).

Do not write the report until repro steps are concrete. If severity is being stretched beyond
the evidence, push back — an honest medium beats a rejected "critical".

## Report structure

```markdown
# <Concise, specific title — class + asset + effect>

## Summary
2–3 sentences: what the bug is, where, and why it matters.

## Steps to Reproduce
1. Numbered, copy-pasteable. Exact URLs, headers, payloads.
2. Include the raw HTTP request/response where relevant.
3. State preconditions (account role, tokens) explicitly.

## Impact
What an attacker gains, who is affected, realistic worst case *supported by the evidence*.
Distinguish demonstrated impact from potential escalation.

## CVSS v3.1
Vector string + base score + one line justifying each metric.

## Proof of Concept
Minimal PoC (request, curl, or short script). Redact any real user data.

## Remediation
Specific, actionable fix. Reference the secure pattern or config.

## References
CWE id, relevant docs/CVEs.
```

## CVSS discipline

Compute the vector honestly from the demonstrated impact. Common anchors:
- Reflected XSS needing user interaction: often `AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N`.
- Unauthenticated IDOR exposing PII: `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N`.
Adjust to the actual case; never copy an anchor blindly.

## Tone

Factual, respectful, no drama. Give the triager everything to reproduce and nothing to
argue with. One quality finding per report.
