import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

/**
 * The Access Request Pre-Check workflow invokes `custom:evaluate-access-request` with evaluateSod
 * true. Standalone preventive-sod-check remains for non-request callers. This file keeps a thin
 * regression that the pre-check no longer calls the standalone SoD command.
 */
const WORKFLOW_FILE = 'Access Request Pre-Check - Risk analysis and SOD.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

describe(WORKFLOW_FILE, () => {
    it('no longer invokes standalone custom:preventive-sod-check', () => {
        const parsed = JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as {
            definition: { steps: Record<string, { attributes?: { jsonRequestBody?: { type?: string } } }> }
        }
        const types = Object.values(parsed.definition.steps)
            .map((step) => step.attributes?.jsonRequestBody?.type)
            .filter(Boolean)

        expect(types).toContain('custom:evaluate-access-request')
        expect(types).not.toContain('custom:preventive-sod-check')
        expect(types).not.toContain('custom:access-request-precheck')
        expect(types).not.toContain('custom:evaluate-access-request-risk')
    })
})
