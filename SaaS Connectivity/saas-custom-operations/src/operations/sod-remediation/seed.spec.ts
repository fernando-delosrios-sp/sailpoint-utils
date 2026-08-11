import { describe, expect, it } from 'vitest'
import { resolve } from 'path'
import { buildCreateFormDefinitionPayload, loadFormSeed } from '../../isc/forms'

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

function findFormElementById(
    elements: Array<Record<string, unknown>>,
    id: string
): Record<string, unknown> | undefined {
    for (const element of elements) {
        if (element.id === id) {
            return element
        }
        const config = element.config as Record<string, unknown> | undefined
        const nested = (config?.formElements ?? config?.columns) as Array<Record<string, unknown>> | undefined
        if (Array.isArray(nested)) {
            const match = findFormElementById(nested, id)
            if (match) {
                return match
            }
        }
        if (Array.isArray(config?.columns)) {
            for (const column of config.columns as Array<Array<Record<string, unknown>>>) {
                const match = findFormElementById(column, id)
                if (match) {
                    return match
                }
            }
        }
    }
    return undefined
}

describe('sod-remediation seed', () => {
    it('loads seed with workflow-friendly user and hidden form keys', () => {
        const seed = loadFormSeed(seedPath)
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
        expect(keys).not.toContain('removeGroupAAccess')
        expect(keys).not.toContain('removeGroupBAccess')
        expect(keys).not.toContain('groupA')
        expect(keys).not.toContain('groupB')
        expect(seed.formInput?.some((input) => input.id === 'groupAContentsHtml' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'groupBContentsHtml' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'controlOptions' && input.type === 'ARRAY')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'hasControls' && input.type === 'STRING')).toBe(true)
    })

    it('renders group access paths as DESCRIPTION elements with HTML formInput interpolation', () => {
        const seed = loadFormSeed(seedPath)

        const groupA = findFormElementById(seed.formElements, 'group-a-contents')
        const groupB = findFormElementById(seed.formElements, 'group-b-contents')
        const toxic = findFormElementById(seed.formElements, 'toxic-column-set')

        expect(groupA?.elementType).toBe('DESCRIPTION')
        expect(groupB?.elementType).toBe('DESCRIPTION')
        expect((groupA?.config as { description?: string })?.description).toBe('{{$.form.input.groupAContentsHtml}}')
        expect((groupB?.config as { description?: string })?.description).toBe('{{$.form.input.groupBContentsHtml}}')
        expect((toxic?.config as { description?: string })?.description).toContain(
            'Removing access profile- or role-level access may affect other functions of the user.'
        )
        expect(findFormElementById(seed.formElements, 'group-a-warning')).toBeUndefined()
        expect(findFormElementById(seed.formElements, 'group-b-warning')).toBeUndefined()

        const conditionSources = (seed.formConditions ?? []).flatMap((condition) =>
            ((condition.rules as Array<{ source?: string }>) ?? []).map((rule) => rule.source)
        )
        expect(conditionSources).not.toContain('groupAContents')
        expect(conditionSources).not.toContain('groupBContents')
        expect(conditionSources).not.toContain('groupAWarning')
        expect(conditionSources).not.toContain('groupBWarning')
    })

    it('buildCreateFormDefinitionPayload applies runtime formName and watermarked description', () => {
        const seed = loadFormSeed(seedPath)
        const payload = buildCreateFormDefinitionPayload('My Tenant SOD Form', 'owner-abc', seed)

        expect(payload.name).toBe('My Tenant SOD Form')
        expect(payload.owner).toEqual({ type: 'IDENTITY', id: 'owner-abc' })
        expect(payload.formElements.length).toBeGreaterThan(0)
        expect(payload.description).toMatch(/^@form-seed-sha256:[a-f0-9]{64}\n/)
        expect(payload.description).toContain(String(seed.description))
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

