// `/proteus <target>` — one-shot entry point that turns the single dsh agent into
// the Proteus coordinator and starts an autonomous continuous-vuln-research run.
// It mirrors the Claude Code `/proteus` command: the handler steers a coordinator
// kickoff prompt into the session, and the model drives the loop from there using
// the Proteus skills (discovered) and the mcp__proteus__* memory tools (connected).
import { createUserMessage } from '@deepseek-ai/dsh-llm'

export const name = 'command-proteus'
export const inject = ['commands']

const kickoff = (target) => `Act as the **Proteus coordinator** and run an autonomous continuous vulnerability-research campaign now.

Target / scope: ${target}

Follow this exactly:
1. Load and follow the \`proteus\` skill (it routes to \`continuous-vuln-research\`). Treat it as your operating contract.
2. Use the Proteus MCP tools for all state: \`proteus_status\` → \`proteus_init\` (if needed) → \`proteus_observe\` / \`proteus_ingest\` existing artifacts → \`proteus_plan_round\` → record surfaces/hypotheses/evidence/decisions → \`proteus_campaign_checkpoint\`. The tools are exposed as mcp__proteus__* (short names like proteus_init also work).
3. Run the full loop end to end WITHOUT stopping to ask for confirmation on read-only recon of an authorized target: Observe → Map → Hypothesize → Prioritize → Delegate → Validate → Kill/Promote → Checkpoint → Replan. Keep chaining rounds until fronts are exhausted or a genuine stop condition (needs credentials you lack, out-of-scope, or an action requiring my approval).
4. There are no host subagents here, so run each bounded front INLINE by loading the matching role skill and adopting it (proteus-generalist, proteus-janus for authz/IDOR, proteus-maverick for logic/0-day, proteus-chaos for fuzzing, proteus-cicada for exploit dev, proteus-skeptic to refute/promote candidates to report-grade, proteus-libris to verify claims). Record each front's role codename in the objective, as the contract says.
5. Provision any recon tool you need (httpx, naabu, nuclei, ffuf, ...) per the tooling policy — announce, install, use.
6. Only act on authorized, in-scope targets. Do not run intrusive exploitation, DoS, brute force, or anything requiring my explicit approval — flag those and continue with what is allowed.

Begin with proteus_status, then proceed through the loop autonomously. Report progress as you go; do not wait for me between steps.`

export function apply(ctx) {
  ctx.inject(['commands'], (commandCtx) => {
    commandCtx.commands.register({
      name: 'proteus',
      description: 'Run the Proteus coordinator autonomously on a target',
      input: { hint: '<target/scope, e.g. localhost:8096>' },
      recordInput: false,
      handler: ({ agent, rawInput }) => {
        const target = (rawInput || '').trim() || 'the current workspace target'
        agent.steer(createUserMessage({
          content: [{ type: 'text', text: kickoff(target) }],
          source: { kind: 'user' },
        }))
        return { kind: 'success', text: `Proteus coordinator started on: ${target}` }
      },
    })
  })
}

export default { name, inject, apply }
