import { describe, expect, it, vi } from 'vitest'
import {
    EXPERIMENTAL_HEADER,
    getViolationV1,
    listControlsV1,
    normalizeViolationV1Response,
} from './experimental-client'

describe('experimental-client', () => {
    it('getViolationV1 calls GET /violations/v1/{id} with experimental header', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({
                id: 'vio-1',
                owner: { id: 'owner-1' },
                identity: { id: 'ident-1', name: 'Alice' },
                leftSide: { entitlements: [{ id: 'ent-a', name: 'Ent A' }] },
                rightSide: { entitlements: [{ id: 'ent-b', name: 'Ent B' }] },
            }),
        })

        const violation = await getViolationV1(
            { apiUrl: 'https://tenant.api.identitynow.com', token: 'tok', fetchFn },
            'vio-1'
        )

        expect(fetchFn).toHaveBeenCalledWith(
            'https://tenant.api.identitynow.com/violations/v1/vio-1',
            expect.objectContaining({
                headers: expect.objectContaining({
                    Authorization: 'Bearer tok',
                    [EXPERIMENTAL_HEADER]: 'true',
                }),
            })
        )
        expect(violation.id).toBe('vio-1')
    })

    it('normalizeViolationV1Response maps target and conflictingAccessCriteria from live API shape', () => {
        const violation = normalizeViolationV1Response({
            id: 'vio-live',
            owner: { id: 'owner-1', name: 'Owner', type: 'IDENTITY' },
            target: { id: 'ident-1', name: 'Alice', type: 'IDENTITY' },
            policy: { id: 'pol-1', name: 'Buyer / Payments SOD Policy', type: 'SOD' },
            conflictingAccessCriteria: {
                leftCriteria: {
                    name: 'Buyer',
                    criteriaList: [
                        { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true },
                        { type: 'ENTITLEMENT', id: 'ent-x', name: 'Ent X', existing: false },
                    ],
                },
                rightCriteria: {
                    name: 'Payments',
                    criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true }],
                },
            },
        })

        expect(violation.identity).toEqual({ id: 'ident-1', name: 'Alice' })
        expect(violation.leftSide?.entitlements).toEqual([{ id: 'ent-a', name: 'Ent A', type: 'ENTITLEMENT' }])
        expect(violation.rightSide?.entitlements).toEqual([{ id: 'ent-b', name: 'Ent B', type: 'ENTITLEMENT' }])
    })

    it('normalizeViolationV1Response maps conflictingCriteria from live API shape', () => {
        const violation = normalizeViolationV1Response({
            id: 'vio-live',
            owner: { id: 'owner-1', name: 'Owner', type: 'IDENTITY' },
            target: { id: 'ident-1', name: 'Alice', type: 'IDENTITY' },
            policy: { id: 'pol-1', name: 'Buyer / Payments SOD Policy', type: 'SOD' },
            conflictingCriteria: {
                leftCriteria: {
                    name: 'Buyer',
                    criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true }],
                },
                rightCriteria: {
                    name: 'Payments',
                    criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true }],
                },
            },
        })

        expect(violation.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(violation.rightSide?.entitlements?.[0]?.id).toBe('ent-b')
    })

    it('normalizeViolationV1Response maps conflictingCriteria array from live API shape', () => {
        const violation = normalizeViolationV1Response({
            id: 'vio-live',
            owner: { id: 'owner-1', name: 'Owner', type: 'IDENTITY' },
            target: { id: 'ident-1', name: 'Alice', type: 'IDENTITY' },
            policy: { id: 'pol-1', name: 'Buyer / Payments SOD Policy', type: 'SOD' },
            conflictingCriteria: [
                {
                    criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true }],
                },
                {
                    criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true }],
                },
            ],
        })

        expect(violation.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(violation.rightSide?.entitlements?.[0]?.id).toBe('ent-b')
    })

    it('normalizeViolationV1Response maps conflictingCriteria array of single access items', () => {
        const violation = normalizeViolationV1Response({
            id: 'vio-live',
            owner: { id: 'owner-1' },
            target: { id: 'ident-1', name: 'Alice' },
            conflictingCriteria: [
                { type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true },
                { type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true },
            ],
        })

        expect(violation.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(violation.rightSide?.entitlements?.[0]?.id).toBe('ent-b')
    })

    it('normalizeViolationV1Response maps conflictingCriteria array with conflictingItems', () => {
        const violation = normalizeViolationV1Response({
            id: 'vio-live',
            owner: { id: 'owner-1' },
            target: { id: 'ident-1', name: 'Alice' },
            conflictingCriteria: [
                {
                    name: 'Buyer',
                    conflictingItems: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true }],
                },
                {
                    name: 'Payments',
                    conflictingItems: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true }],
                },
            ],
        })

        expect(violation.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(violation.rightSide?.entitlements?.[0]?.id).toBe('ent-b')
    })

    it('getViolationV1 normalizes target/conflictingAccessCriteria responses', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => ({
                id: 'vio-1',
                owner: { id: 'owner-1', type: 'IDENTITY' },
                target: { id: 'ident-1', name: 'Alice', type: 'IDENTITY' },
                policy: { id: 'pol-1', name: 'AP vs AP', type: 'SOD' },
                conflictingAccessCriteria: {
                    leftCriteria: {
                        criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-a', name: 'Ent A', existing: true }],
                    },
                    rightCriteria: {
                        criteriaList: [{ type: 'ENTITLEMENT', id: 'ent-b', name: 'Ent B', existing: true }],
                    },
                },
            }),
        })

        const violation = await getViolationV1(
            { apiUrl: 'https://tenant.api.identitynow.com', token: 'tok', fetchFn },
            'vio-1'
        )

        expect(violation.identity.id).toBe('ident-1')
        expect(violation.leftSide?.entitlements?.[0]?.id).toBe('ent-a')
        expect(violation.rightSide?.entitlements?.[0]?.id).toBe('ent-b')
    })

    it('listControlsV1 calls GET /controls/v1 with experimental header', async () => {
        const fetchFn = vi.fn().mockResolvedValue({
            ok: true,
            json: async () => [{ id: 'ctrl-1', name: 'Control 1' }],
        })

        const controls = await listControlsV1({
            apiUrl: 'https://tenant.api.identitynow.com/',
            token: 'tok',
            fetchFn,
        })

        expect(fetchFn).toHaveBeenCalledWith(
            'https://tenant.api.identitynow.com/controls/v1',
            expect.objectContaining({
                headers: expect.objectContaining({
                    [EXPERIMENTAL_HEADER]: 'true',
                }),
            })
        )
        expect(controls).toHaveLength(1)
    })

    it('surfaces ConnectorError on HTTP failure', async () => {
        const fetchFn = vi.fn().mockResolvedValue({ ok: false, status: 404 })

        await expect(
            getViolationV1({ apiUrl: 'https://tenant.api.identitynow.com', token: 'tok', fetchFn }, 'missing')
        ).rejects.toThrow(/404/)
    })
})

