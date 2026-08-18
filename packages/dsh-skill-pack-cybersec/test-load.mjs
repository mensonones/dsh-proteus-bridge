// Real end-to-end check: mount the skill registry + this plugin in a Cordis
// context and assert the bundled skills are discovered. No LLM / API key needed.
import { Context } from '@deepseek-ai/cordis'
import skillRegistry from '@deepseek-ai/dsh-skill'
import skillPack from './lib/index.js'

const ctx = new Context()
ctx.plugin(skillRegistry)
ctx.plugin(skillPack)

// Give the async provider factory + discovery a moment.
await ctx.start?.()
await new Promise((r) => setTimeout(r, 500))

const { skills, complete } = await ctx.skills.snapshot({ cwd: process.cwd() })
const names = skills.map((s) => s.name).sort()
console.log('discovery complete:', complete)
console.log('skills found:', names.length)
for (const s of skills.sort((a, b) => a.name.localeCompare(b.name))) {
  console.log(`  - ${s.name}: ${String(s.description).slice(0, 60)}...`)
}

const expected = ['bounty-report', 'http-recon-runner', 'recon-triage', 'vuln-code-review', 'web-attack-surface']
const ok = expected.every((n) => names.includes(n))
console.log(ok ? '\nPASS: all 5 bundled skills registered via the plugin.' : '\nFAIL: missing skills.')
await ctx.stop?.()
process.exit(ok ? 0 : 1)
