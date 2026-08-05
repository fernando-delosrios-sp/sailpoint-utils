import * as fs from 'fs'
import * as os from 'os'
import * as path from 'path'
import { afterEach, describe, expect, it } from 'vitest'
import { generateTemplates } from './generate-templates'

describe('generateTemplates integration', () => {
    let outputDir: string

    afterEach(() => {
        if (outputDir && fs.existsSync(outputDir)) {
            fs.rmSync(outputDir, { recursive: true, force: true })
        }
    })

    it('writes account-schema.json, access-token.md, and workflow-invocation.md', () => {
        outputDir = fs.mkdtempSync(path.join(os.tmpdir(), 'templates-gen-'))
        const projectRoot = path.resolve(__dirname, '..')
        const indexPath = path.join(projectRoot, 'src/operations/index.ts')

        generateTemplates({ outputDir, indexPath })

        expect(fs.existsSync(path.join(outputDir, 'account-schema.json'))).toBe(true)
        expect(fs.existsSync(path.join(outputDir, 'access-token.md'))).toBe(true)
        expect(fs.existsSync(path.join(outputDir, 'workflow-invocation.md'))).toBe(true)

        const schema = JSON.parse(fs.readFileSync(path.join(outputDir, 'account-schema.json'), 'utf-8'))
        expect(schema.name).toBe('account')
        expect(schema.identityAttribute).toBe('id')
        expect(schema.attributes.map((a: { name: string }) => a.name)).toContain('summary')

        const workflow = fs.readFileSync(path.join(outputDir, 'workflow-invocation.md'), 'utf-8')
        expect(workflow).toContain('custom:example')
    })
})
