import { describe, expect, it } from 'vitest'
import { resolve } from 'path'
import { buildCreateFormDefinitionPayload, loadFormSeed } from '../../isc/forms'
import { ELEVATED_WARNING } from './access-path-resolver'

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
    it('loads seed with user form element keys and launch-only formInput workflow keys', () => {
        const seed = loadFormSeed(seedPath)
        const keys = collectFormElementKeys(seed.formElements)

        expect(keys).toEqual(
            expect.arrayContaining([
                'action',
                'remediationSide',
                'control',
                'comments',
            ])
        )
        expect(keys).not.toContain('violationId')
        expect(keys).not.toContain('targetIdentityId')
        expect(keys).not.toContain('groupAAccessSearch')
        expect(keys).not.toContain('groupBAccessSearch')
        expect(seed.formInput?.some((input) => input.id === 'violationId')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'groupAAccessSearch')).toBe(true)
        expect(keys).not.toContain('removeGroupAAccess')
        expect(keys).not.toContain('removeGroupBAccess')
        expect(keys).not.toContain('groupA')
        expect(keys).not.toContain('groupB')
        expect(seed.formInput?.some((input) => input.id === 'groupColumnsHtmlWhenGroupARemoved' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'groupColumnsHtmlWhenGroupBRemoved' && input.type === 'STRING')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'controlOptions' && input.type === 'ARRAY')).toBe(true)
        expect(seed.formInput?.some((input) => input.id === 'hasControls' && input.type === 'STRING')).toBe(true)
    })

    it('Single ctx-summary element interpolates situationSummaryHtml without ctx-identity', () => {
        const seed = loadFormSeed(seedPath)
        const ctxSummary = findFormElementById(seed.formElements, 'ctx-summary')
        const ctxSection = findFormElementById(seed.formElements, 'ctx-section')

        expect(findFormElementById(seed.formElements, 'ctx-identity')).toBeUndefined()
        expect((ctxSummary?.config as { description?: string })?.description).toBe(
            '{{$.form.input.situationSummaryHtml}}'
        )
        expect((ctxSection?.config as { label?: string })?.label).not.toContain('policy violation detection')
    })

    it('swaps column previews via ELEMENT SHOW conditions on remediationSide', () => {
        const seed = loadFormSeed(seedPath)

        expect(findFormElementById(seed.formElements, 'group-columns-plain')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-when-a-removed')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-when-b-removed')?.elementType).toBe('DESCRIPTION')
        expect(findFormElementById(seed.formElements, 'group-columns-preview')).toBeUndefined()
        expect(findFormElementById(seed.formElements, 'column-preview-section')?.elementType).toBe('SECTION')

        const toxicHeader = findFormElementById(seed.formElements, 'toxic-combination-header')
        expect(toxicHeader?.elementType).toBe('DESCRIPTION')
        expect((toxicHeader?.config as { description?: string })?.description).toContain(ELEVATED_WARNING)

        const intro = findFormElementById(seed.formElements, 'group-columns-preview-intro')
        expect((intro?.config as { description?: string })?.description).toContain('Select a side above to preview outcomes')

        const columnConditions = (seed.formConditions ?? []).filter((condition) =>
            ((condition.effects as Array<{ config?: { element?: string } }>) ?? []).some((effect) =>
                String(effect.config?.element).includes('group-columns')
            )
        )
        expect(columnConditions).toHaveLength(3)

        for (const condition of columnConditions) {
            const rules = (condition.rules as Array<Record<string, unknown>>) ?? []
            expect(rules.some((rule) => rule.sourceType === 'ELEMENT' && rule.source === 'action' && rule.value === 'Correct')).toBe(true)
            expect(rules.some((rule) => rule.sourceType === 'ELEMENT' && rule.source === 'remediationSide')).toBe(true)
            const effects = (condition.effects as Array<Record<string, unknown>>) ?? []
            expect(effects.every((effect) => effect.effectType === 'SHOW')).toBe(true)
        }

        const showTargets = columnConditions.flatMap((condition) =>
            ((condition.effects as Array<{ config?: { element?: string } }>) ?? []).map((effect) => effect.config?.element)
        )
        expect(showTargets).toEqual([
            'group-columns-plain',
            'group-columns-when-a-removed',
            'group-columns-when-b-removed',
        ])

        const eqValues = columnConditions.flatMap((condition) =>
            ((condition.rules as Array<{ operator?: string; value?: string }>) ?? [])
                .filter((rule) => rule.operator === 'EQ' && rule.source === 'remediationSide')
                .map((rule) => rule.value)
        )
        expect(eqValues).toEqual(['Group A', 'Group B'])
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
        const hideTargets = (seed.formConditions ?? []).flatMap((condition) =>
            ((condition.effects as Array<{ effectType?: string; config?: { element?: string } }>) ?? [])
                .filter((effect) => effect.effectType === 'HIDE')
                .map((effect) => effect.config?.element)
        )

        expect(effectTypes).not.toContain('SET_OPTION')
        expect(effectTypes.every((type) => ['SHOW', 'HIDE', 'SET_DEFAULT_VALUE', 'DISABLE'].includes(String(type)))).toBe(true)
        expect(effectTypes.filter((type) => type === 'SET_DEFAULT_VALUE').length).toBe(0)
        expect(hideTargets).not.toContain('hidden-section')
    })

    it('does not define hidden pass-through form elements for workflow keys', () => {
        const seed = loadFormSeed(seedPath)

        expect(findFormElementById(seed.formElements, 'hidden-section')).toBeUndefined()
        expect(findFormElementById(seed.formElements, 'hidden-violation-id')).toBeUndefined()
    })
})

