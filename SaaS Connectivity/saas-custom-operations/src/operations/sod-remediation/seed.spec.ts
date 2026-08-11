import { describe, expect, it } from 'vitest'
import { resolve } from 'path'
import { buildCreateFormDefinitionPayload, loadFormSeed } from '../../isc/forms/seed-loader'

const seedPath = resolve(__dirname, 'seed/sod-violation-remediation.seed.json')

function collectFormElementKeys(elements: Array<Record<string, unknown>>): string[] {
    const keys: string[] = []
    for (const element of elements) {
        if (typeof element.key === 'string' && element.key.length > 0) {
            keys.push(element.key)
        }
        const config = element.config as Record<string, unknown> | undefined
        const nested = (config?.formElements ?? config?.columns) as Array<Record<string, unknown>> | undefined
        if (Array.isArray(nested)) {
            keys.push(...collectFormElementKeys(nested))
        }
        if (Array.isArray(config?.columns)) {
            for (const column of config.columns as Array<Array<Record<string, unknown>>>) {
                keys.push(...collectFormElementKeys(column))
            }
        }
    }
    return keys
}

describe('sod-remediation seed', () => {
    it('loads seed with workflow-friendly user and hidden form keys', () => {
        const seed = loadFormSeed(seedPath)
        const keys = collectFormElementKeys(seed.formElements)

        expect(keys).toEqual(
            expect.arrayContaining([
                'action',
                'remediationSide',
                'groupA',
                'groupB',
                'policyControl',
                'comments',
                'violationId',
                'targetIdentityId',
                'groupARevokePayload',
                'groupBRevokePayload',
            ])
        )
        expect(keys).not.toContain('removeGroupAAccess')
        expect(keys).not.toContain('removeGroupBAccess')
        expect(seed.formInput?.some((input) => input.id === 'groupAContents' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'groupBContents' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'controlOptions' && input.type === 'ARRAY')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'hasControls' && input.type === 'STRING')).toBe(true)
    })

    it('buildCreateFormDefinitionPayload applies runtime formName on create payload', () => {
        const seed = loadFormSeed(seedPath)
        const payload = buildCreateFormDefinitionPayload('My Tenant SOD Form', 'owner-abc', seed)

        expect(payload.name).toBe('My Tenant SOD Form')
        expect(payload.owner).toEqual({ type: 'IDENTITY', id: 'owner-abc' })
        expect(payload.formElements.length).toBeGreaterThan(0)
    })

    it('seed formConditions use supported ISC effect types only', () => {
        const seed = loadFormSeed(seedPath)
        const effectTypes = (seed.formConditions ?? []).flatMap((condition) =>
            ((condition.effects as Array<{ effectType?: string }>) ?? []).map((effect) => effect.effectType)
        )

        expect(effectTypes).not.toContain('SET_OPTION')
        expect(effectTypes.every((type) => ['SHOW', 'HIDE', 'SET_DEFAULT_VALUE', 'DISABLE'].includes(String(type)))).toBe(true)
        expect(effectTypes.filter((type) => type === 'SET_DEFAULT_VALUE').length).toBeGreaterThanOrEqual(4)
    })
})
