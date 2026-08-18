---
name: web-attack-surface
description: Systematically enumerate and reason about the attack surface of a single authorized web application or API — endpoints, params, auth flows, roles, trust boundaries — and produce a prioritized test plan mapped to vulnerability classes. Use when focusing on one target and asking "how do I test this thoroughly". Planning and analysis only; the user runs the traffic.
---

# Web attack-surface analysis

Given one in-scope web app/API, build the map an experienced tester keeps in their head, then
turn it into an ordered test plan. This is analysis and planning — you don't send traffic.

## Scope guard

Work only on a target the user confirms is authorized (their asset or an active program's
in-scope host). If unclear, ask before producing an active-testing plan.

## Build the model

1. **Entry points.** Enumerate routes/endpoints, HTTP methods, params (query, body, header,
   cookie, path), file uploads, websockets, GraphQL operations.
2. **Identities & roles.** Anonymous, user, admin, service. Note how each authenticates and
   what each should and should not access.
3. **Trust boundaries.** Where user input crosses into: DB, filesystem, OS, template engine,
   outbound HTTP, other internal services, the browser DOM.
4. **State & flows.** Multi-step flows (checkout, password reset, invite, OAuth) — these hide
   logic bugs and race conditions.

## Map to test classes (prioritized)

For each surface element, list the classes worth testing and the *cheapest decisive check*:

| Surface | Test for | First check |
| --- | --- | --- |
| Object IDs in URL/body | IDOR / BOLA | swap ID to another user's, observe |
| Auth / session / JWT | fixation, alg confusion, expiry | decode token, tamper `alg`/claims |
| Redirects, URL params | open redirect, SSRF | point at controlled/interal host |
| Search, templating | XSS, SSTI | context-specific probe payloads |
| File upload / path | traversal, RCE, content-type bypass | boundary filenames, magic bytes |
| GraphQL | introspection, batching, authz | introspect, then per-field authz |
| Password reset / invite | token predictability, host header inj | inspect token, tamper Host |
| Multi-step flows | race conditions, step-skipping | parallel requests, reorder steps |

## Output

A prioritized checklist: surface element → class → concrete check → what a positive looks like.
Front-load high-impact, low-effort checks (authz/IDOR, exposed debug, auth logic). Note where
you'd need credentials or a second account to test properly.

## Discipline

- Business-logic and authorization bugs are usually higher value than reflected XSS — weight
  accordingly.
- Keep it decisive: each check should have a clear pass/fail signal, not "poke around".
