import { describe, expect, it } from 'vitest'
import { buildFormDefinitionFromSeed, loadSodRemediationSeed } from './form-seed-loader'

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

describe('form-seed-loader', () => {
    it('loads seed with workflow-friendly user and hidden form keys', () => {
        const seed = loadSodRemediationSeed()
        const keys = collectFormElementKeys(seed.formElements)

        expect(keys).toEqual(
            expect.arrayContaining([
                'action',
                'remediationSide',
                'policyControl',
                'comments',
                'violationId',
                'targetIdentityId',
                'groupARevokePayload',
                'groupBRevokePayload',
            ])
        )
        expect(seed.formInput?.some((input) => input.id === 'hasControls' && input.type === 'STRING')).toBe(true)
    })

    it('buildFormDefinitionFromSeed applies runtime formName on create payload', () => {
        const payload = buildFormDefinitionFromSeed('My Tenant SOD Form', 'owner-abc')

        expect(payload.name).toBe('My Tenant SOD Form')
        expect(payload.owner).toEqual({ type: 'IDENTITY', id: 'owner-abc' })
        expect(payload.formElements.length).toBeGreaterThan(0)
    })

    it('seed formConditions use supported ISC effect types only', () => {
        const seed = loadSodRemediationSeed()
        const effectTypes = (seed.formConditions ?? []).flatMap((condition) =>
            ((condition.effects as Array<{ effectType?: string }>) ?? []).map((effect) => effect.effectType)
        )

        expect(effectTypes).not.toContain('SET_OPTION')
        expect(effectTypes.every((type) => ['SHOW', 'HIDE'].includes(String(type)))).toBe(true)
    })
})

