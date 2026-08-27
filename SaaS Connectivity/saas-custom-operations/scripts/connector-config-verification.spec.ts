import { describe, expect, it } from 'vitest'
import { existsSync, readFileSync } from 'fs'
import { join } from 'path'

const root = process.cwd()
const repoRoot = join(root, '../..')

function readText(relativePath: string): string {
    return readFileSync(join(root, relativePath), 'utf-8')
}

describe('connector-config verification baseline', () => {
    it('CI runs canonical verification commands', () => {
        const workflowPath = join(repoRoot, '.github/workflows/saas-custom-operations-ci.yml')
        expect(existsSync(workflowPath)).toBe(true)

        const workflow = readFileSync(workflowPath, 'utf-8')
        expect(workflow).toMatch(/SaaS Connectivity\/saas-custom-operations/)
        expect(workflow).toMatch(/npm ci/)
        expect(workflow).toMatch(/npm run typecheck/)
        expect(workflow).toMatch(/npm test/)
        expect(workflow).toMatch(/npm run build/)
    })

    it('Typecheck script exists', () => {
        const pkg = JSON.parse(readText('package.json'))
        expect(pkg.scripts.typecheck).toBe(
            'tsc --noEmit -p tsconfig.json && tsc --noEmit -p tsconfig.scripts.json'
        )
        expect(existsSync(join(root, 'tsconfig.scripts.json'))).toBe(true)
    })

    it('dev compile chain refreshes .dev-dist from source', () => {
        const pkg = JSON.parse(readText('package.json'))
        expect(pkg.scripts['compile:dev']).toMatch(/codegen:schemas/)
        expect(pkg.scripts['compile:dev']).toMatch(/tsc -p tsconfig\.json/)
        expect(pkg.scripts.predev).toBe('npm run compile:dev')
        expect(pkg.scripts.predebug).toBe('npm run compile:dev')
    })
})

describe('connector-config auto-provisioning documentation', () => {
    it('Auto-provision prerequisites documented', () => {
        const readme = readText('README.md')
        expect(readme).toMatch(/sourceName/)
        expect(readme).toMatch(/DelimitedFile/)
        expect(readme).toMatch(/automatically|auto-provision/i)
        expect(readme).toMatch(/sp:manage:source/)
        expect(readme).toMatch(/schema/)
        expect(readme).toMatch(/Reconciles the account schema|reconcil/i)
    })

    it('ISC_TOKEN documented for local invoke', () => {
        const readme = readText('README.md')
        const envExample = readText('.env.example')

        expect(readme).toMatch(/ISC_TOKEN/)
        expect(readme).toMatch(/placeholder|__SET_VIA_ISC_TOKEN_ENV__|<access-token>/i)
        expect(readme).toMatch(/\.env\.example/)

        expect(envExample).toMatch(/ISC_TOKEN/)
        expect(envExample).toMatch(/__SET_VIA_ISC_TOKEN_ENV__/)
    })
})

describe('connector-config agent guidance accuracy', () => {
    it('AGENTS.md matches custom operations reality', () => {
        const agents = readText('AGENTS.md')
        expect(agents).toMatch(/auto-registry/)
        expect(agents).toMatch(/connector-spec\.json/)
        expect(agents).toMatch(/custom:example/)
        expect(agents).not.toMatch(/std:test-connection/)
        expect(agents).not.toMatch(/std:account:list/)
        expect(agents).not.toMatch(/std:account:read/)
        expect(agents).not.toMatch(/my-client\.ts/)
    })

    it('OpenSpec config context matches architecture', () => {
        const config = readText('openspec/config.yaml')
        expect(config).toMatch(/custom operations/)
        expect(config).toMatch(/auto-registry/)
        expect(config).toMatch(/ISC loopback|ctx\.sdk/)
        expect(config).not.toMatch(/std-command scaffold/)
        expect(config).not.toMatch(/my-client\.ts/)
    })
})
