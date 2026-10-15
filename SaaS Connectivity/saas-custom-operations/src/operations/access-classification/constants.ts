import type { TaggedObjectType } from '../../isc/tagged-objects'

export const PRIVILEGED_TAG = 'privileged'
export const RISK_TAG = 'risk'

export const ACCESS_ITEM_TYPES: ReadonlySet<TaggedObjectType> = new Set([
    'ENTITLEMENT',
    'ACCESS_PROFILE',
    'ROLE',
])

export const SOD_RECONCILE_TYPES: ReadonlySet<TaggedObjectType> = new Set([
    'ENTITLEMENT',
    'ACCESS_PROFILE',
    'ROLE',
    'IDENTITY',
])
