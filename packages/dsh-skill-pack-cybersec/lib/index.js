// @deepseek-ai-compatible Cordis plugin: bundles a pack of cybersec/bounty
// Skills and registers them as an isolated filesystem skill provider.
//
// It does not reimplement discovery — it mounts `@deepseek-ai/dsh-skill-filesystem`
// pointed at this package's bundled `skills/` directory, with default roots off so
// this provider serves only the packaged skills under a unique provider name.
import { fileURLToPath } from 'node:url'
import * as fsSkill from '@deepseek-ai/dsh-skill-filesystem'

// Absolute path to the bundled skills, resolved from this module's location so it
// works whether installed from npm or linked locally.
const bundledSkillsDir = fileURLToPath(new URL('../skills', import.meta.url))

export const name = 'skill-pack-cybersec'
export const inject = ['skills']

// Re-expose the child provider as a distinct, uniquely-named plugin so it can
// coexist with the host's default `filesystem` provider.
const BundledSkillProvider = {
  name: 'skill-pack-cybersec-fs',
  inject: fsSkill.inject,
  Config: fsSkill.Config,
  apply: fsSkill.apply,
}

export function apply(ctx, config = {}) {
  ctx.plugin(BundledSkillProvider, {
    providerName: config.providerName || 'cybersec-skills',
    includeDefaultRoots: false,
    customSkillDirs: [bundledSkillsDir],
    watch: config.watch !== undefined ? config.watch : true,
  })
}

export default { name, inject, apply }
