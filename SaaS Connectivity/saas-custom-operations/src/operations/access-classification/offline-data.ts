import type { SodPolicySummary } from '../../isc/sod-policies'
import type { TaggedObjectRef } from '../../isc/tagged-objects'
import type { AccessProfileCatalogItem, EntitlementCatalogItem, RoleCatalogItem } from './catalog'

function risk(value: string): unknown {
    return {
        attributes: [{ key: 'iscRisk', name: 'Risk', values: [{ value, name: value }] }],
    }
}

export const OFFLINE_ENTITLEMENTS: EntitlementCatalogItem[] = [
    { id: 'ent-high', privilegeLevel: { effective: 'HIGH' }, metadata: undefined },
    { id: 'ent-medium', privilegeLevel: { effective: 'MEDIUM' }, metadata: risk('low') },
    { id: 'ent-low', privilegeLevel: { effective: 'LOW' }, metadata: undefined },
    { id: 'ent-sod-a', privilegeLevel: { effective: 'LOW' }, metadata: undefined },
    { id: 'ent-sod-b', privilegeLevel: { effective: 'LOW' }, metadata: undefined },
]

export const OFFLINE_ACCESS_PROFILES: AccessProfileCatalogItem[] = [
    { id: 'ap-priv', entitlementIds: ['ent-low', 'ent-high', 'ent-medium'], metadata: undefined },
    { id: 'ap-risk', entitlementIds: ['ent-low'], metadata: risk('medium') },
    { id: 'ap-sod', entitlementIds: ['ent-sod-a'], metadata: undefined },
    { id: 'ap-plain', entitlementIds: ['ent-low'], metadata: undefined },
]

export const OFFLINE_ROLES: RoleCatalogItem[] = [
    {
        id: 'role-priv',
        accessProfileIds: ['ap-plain', 'ap-priv'],
        entitlementIds: ['ent-low'],
        metadata: undefined,
    },
    {
        id: 'role-sod',
        accessProfileIds: ['ap-sod'],
        entitlementIds: ['ent-sod-b'],
        metadata: undefined,
    },
    {
        id: 'role-plain',
        accessProfileIds: ['ap-plain'],
        entitlementIds: [],
        metadata: undefined,
    },
]

export const OFFLINE_SOD_POLICIES: SodPolicySummary[] = [
    {
        id: 'pol-1',
        name: 'Finance SOD',
        state: 'ENFORCED',
        tags: ['SOD_FINANCE'],
        conflictingAccessCriteria: {
            leftCriteria: { criteriaList: [{ id: 'ent-sod-a', type: 'ENTITLEMENT' }] },
            rightCriteria: { criteriaList: [{ id: 'ent-sod-b', type: 'ENTITLEMENT' }] },
        },
    },
    {
        id: 'pol-empty',
        name: 'Untagged',
        state: 'ENFORCED',
        tags: [],
        conflictingAccessCriteria: {
            leftCriteria: { criteriaList: [{ id: 'ent-low', type: 'ENTITLEMENT' }] },
            rightCriteria: { criteriaList: [{ id: 'ent-high', type: 'ENTITLEMENT' }] },
        },
    },
]

export const OFFLINE_VIOLATING_IDENTITIES: Record<string, string[]> = {
    'pol-1': ['ident-violator', 'ident-other'],
}

/** Current holders before reconcile — privileged missing on ap-priv, extra risk on role-plain. */
export const OFFLINE_CURRENT_BY_TAG: Record<string, TaggedObjectRef[]> = {
    privileged: [
        { type: 'ENTITLEMENT', id: 'ent-high' },
        { type: 'ENTITLEMENT', id: 'ent-medium' },
        // ap-priv and role-priv missing → should be added
    ],
    risk: [
        { type: 'ENTITLEMENT', id: 'ent-medium' },
        { type: 'ACCESS_PROFILE', id: 'ap-risk' },
        { type: 'ROLE', id: 'role-plain' }, // stale → should be removed
    ],
    SOD_FINANCE: [
        { type: 'ENTITLEMENT', id: 'ent-sod-a' },
        // others missing including identities
    ],
}
