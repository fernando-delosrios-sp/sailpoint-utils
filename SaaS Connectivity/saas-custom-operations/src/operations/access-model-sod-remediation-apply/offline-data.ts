import { NormalizedFormInstance } from '../../isc/forms/get-form-instance'
import { CatalogAccessItem } from '../../isc/roles/list-enabled-roles'
import {
    ExpandedAccessItemEntitlements,
    NestedAccessProfileBundle,
} from '../access-model-sod-remediation/expand-access-item-entitlements'
import { CorrectionPlan } from './build-correction-plan'

interface OfflineRoleState {
    directEntitlementIds: string[]
    accessProfileIds: string[]
    description: string
}

interface OfflineAccessProfileState {
    entitlementIds: string[]
    description: string
}

const ENTITLEMENT_NAMES: Record<string, string> = {
    'ent-a': 'Accounts Receivable',
    'ent-c': 'Accounts Payable',
}

const ACCESS_PROFILE_NAMES: Record<string, string> = {
    'ap-offline-1': 'SAP Suite',
}

const INITIAL_ROLE_STATE: Record<string, OfflineRoleState> = {
    'role-offline-1': {
        directEntitlementIds: ['ent-a'],
        accessProfileIds: ['ap-offline-1'],
        description: 'Finance Role',
    },
}

const INITIAL_ACCESS_PROFILE_STATE: Record<string, OfflineAccessProfileState> = {
    'ap-offline-1': {
        entitlementIds: ['ent-c'],
        description: 'SAP Suite',
    },
    'ap-offline-2': {
        entitlementIds: ['ent-x', 'ent-y'],
        description: 'Standalone AP',
    },
}

let offlineRoleState = structuredClone(INITIAL_ROLE_STATE)
let offlineAccessProfileState = structuredClone(INITIAL_ACCESS_PROFILE_STATE)

/** Resets mutable offline catalog fixtures between tests. */
export function resetOfflineCatalogState(): void {
    offlineRoleState = structuredClone(INITIAL_ROLE_STATE)
    offlineAccessProfileState = structuredClone(INITIAL_ACCESS_PROFILE_STATE)
}

const BASE_FORM_INPUT = {
    accessItemId: 'role-offline-1',
    accessItemType: 'ROLE',
    policyId: 'policy-offline-1',
    policyName: 'Finance vs AP',
    groupAIds: '["ent-a"]',
    groupBIds: '["ent-c"]',
}

/** Offline form instances keyed by formInstanceId. */
export const OFFLINE_FORM_INSTANCES: Record<string, NormalizedFormInstance> = {
    'fi-role-group-a-direct': {
        id: 'fi-role-group-a-direct',
        state: 'COMPLETED',
        formInput: { ...BASE_FORM_INPUT },
        formData: { remediationSide: 'groupA' },
        submitterId: 'owner-offline-1',
    },
    'fi-role-group-b-nested': {
        id: 'fi-role-group-b-nested',
        state: 'COMPLETED',
        formInput: { ...BASE_FORM_INPUT },
        formData: { remediationSide: 'groupB', comments: 'Remove AP side' },
        submitterId: 'owner-offline-1',
    },
    'fi-role-already-clean': {
        id: 'fi-role-already-clean',
        state: 'COMPLETED',
        formInput: { ...BASE_FORM_INPUT },
        formData: { remediationSide: 'groupA' },
    },
    'fi-ap-group-a': {
        id: 'fi-ap-group-a',
        state: 'COMPLETED',
        formInput: {
            accessItemId: 'ap-offline-2',
            accessItemType: 'ACCESS_PROFILE',
            policyId: 'policy-offline-2',
            policyName: 'AP conflict',
            groupAIds: '["ent-x"]',
            groupBIds: '["ent-y"]',
        },
        formData: { remediationSide: 'groupA' },
    },
    'fi-in-progress': {
        id: 'fi-in-progress',
        state: 'IN_PROGRESS',
        formInput: { ...BASE_FORM_INPUT },
        formData: {},
    },
}

/** Returns an offline form instance fixture or throws when unknown. */
export function getFormInstanceByIdOffline(formInstanceId: string): NormalizedFormInstance {
    const instance = OFFLINE_FORM_INSTANCES[formInstanceId]
    if (!instance) {
        throw new Error(`Offline form instance "${formInstanceId}" not found`)
    }
    return structuredClone(instance)
}

function buildNestedProfiles(accessProfileIds: string[]): NestedAccessProfileBundle[] {
    return accessProfileIds.flatMap((profileId) => {
        const profileState = offlineAccessProfileState[profileId]
        if (!profileState) {
            return []
        }
        return [
            {
                id: profileId,
                name: ACCESS_PROFILE_NAMES[profileId] ?? profileId,
                entitlements: profileState.entitlementIds.map((id) => ({
                    id,
                    name: ENTITLEMENT_NAMES[id],
                })),
            },
        ]
    })
}

/** Expands entitlements from mutable offline catalog state. */
export function expandAccessItemEntitlementsFromOfflineState(
    item: CatalogAccessItem
): ExpandedAccessItemEntitlements {
    if (item.type === 'ACCESS_PROFILE') {
        const profileState = offlineAccessProfileState[item.id] ?? { entitlementIds: [], description: '' }
        const entitlementIds = new Set(profileState.entitlementIds)
        const entitlements = profileState.entitlementIds.map((id) => ({ id, name: ENTITLEMENT_NAMES[id] }))
        return { entitlementIds, entitlements, nestedProfiles: [] }
    }

    const roleState = offlineRoleState[item.id] ?? { directEntitlementIds: [], accessProfileIds: [], description: '' }
    const entitlementIds = new Set<string>()
    const entitlements: ExpandedAccessItemEntitlements['entitlements'] = []
    const nestedProfiles = buildNestedProfiles(roleState.accessProfileIds)

    for (const id of roleState.directEntitlementIds) {
        entitlementIds.add(id)
        entitlements.push({ id, name: ENTITLEMENT_NAMES[id] })
    }

    for (const profile of nestedProfiles) {
        for (const entitlement of profile.entitlements) {
            entitlementIds.add(entitlement.id)
            entitlements.push(entitlement)
        }
    }

    return { entitlementIds, entitlements, nestedProfiles }
}

/** Simulates catalog PATCH for offline invoke. */
export function applyCorrectionOffline(plan: CorrectionPlan, auditLine: string): void {
    if (plan.accessItemType === 'ACCESS_PROFILE') {
        const profileState = offlineAccessProfileState[plan.accessItemId]
        if (!profileState) {
            return
        }
        const removeSet = new Set(plan.removedEntitlementIds)
        profileState.entitlementIds = profileState.entitlementIds.filter((id) => !removeSet.has(id))
        profileState.description = profileState.description ? `${profileState.description}\n${auditLine}` : auditLine
        return
    }

    const roleState = offlineRoleState[plan.accessItemId]
    if (!roleState) {
        return
    }

    const detachSet = new Set(plan.detachedAccessProfileIds)
    roleState.accessProfileIds = roleState.accessProfileIds.filter((id) => !detachSet.has(id))

    const removeSet = new Set(plan.removedEntitlementIds)
    roleState.directEntitlementIds = roleState.directEntitlementIds.filter((id) => !removeSet.has(id))
    roleState.description = roleState.description ? `${roleState.description}\n${auditLine}` : auditLine
}

/** Pre-applies offline catalog corrections so a second invoke yields skipped-already-clean. */
export function markOfflineRoleAlreadyClean(roleId: string): void {
    const roleState = offlineRoleState[roleId]
    if (!roleState) {
        return
    }
    roleState.directEntitlementIds = []
    roleState.accessProfileIds = []
}
