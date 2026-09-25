import { describe, expect, it } from 'vitest'
import { entitlementsToAdd, extractInboundValues, inboundAttributeName } from './evaluate'

describe('machine-identity-entitlements evaluation helpers', () => {
    it('Schema without inboundEntitlements is skipped', () => {
        expect(
            inboundAttributeName({
                name: 'account',
                attributes: [{ name: 'groups' }],
            })
        ).toBeUndefined()
    })

    it('Unknown attribute name is skipped', () => {
        expect(
            inboundAttributeName({
                name: 'account',
                configuration: { inboundEntitlements: 'groups' },
                attributes: [{ name: 'appRole' }],
            })
        ).toBeUndefined()
    })

    it('Single-valued inbound attribute is read', () => {
        expect(extractInboundValues('CN=Admins')).toEqual(['CN=Admins'])
    })

    it('Multi-valued inbound attribute drops blanks', () => {
        expect(extractInboundValues(['CN=A', ' ', 'CN=B'])).toEqual(['CN=A', 'CN=B'])
    })

    it('Value matches catalog entitlement', () => {
        const toAdd = entitlementsToAdd([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }], [])
        expect(toAdd).toEqual([{ id: 'ent-1', sourceId: 'src-1', value: 'CN=Admins' }])
    })

    it('Already assigned entitlement omitted', () => {
        const toAdd = entitlementsToAdd(
            [{ id: 'ent-1', sourceId: 'src-1' }],
            [{ sourceId: 'src-1', entitlementId: 'ent-1' }]
        )
        expect(toAdd.map((ref) => ref.id)).not.toContain('ent-1')
    })

    it('Duplicate values collapse', () => {
        const toAdd = entitlementsToAdd(
            [
                { id: 'ent-1', sourceId: 'src-1' },
                { id: 'ent-1', sourceId: 'src-1' },
            ],
            []
        )
        expect(toAdd.map((ref) => ref.id)).toEqual(['ent-1'])
    })
})
