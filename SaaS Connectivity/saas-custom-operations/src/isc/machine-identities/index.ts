/** Gets one machine identity by id, including `userEntitlements`. */
export { getMachineIdentity } from './get-machine-identity'
/** Paginates `listMachineIdentitiesV1` with the experimental header. */
export { listMachineIdentities, MACHINE_IDENTITY_PAGE_SIZE } from './list-machine-identities'
/** Canned machine identities for offline invokes. */
export {
    getMachineIdentityOffline,
    listMachineIdentitiesOffline,
    OFFLINE_MACHINE_IDENTITIES,
    resolveMachineIdentityByIdentityIdOffline,
} from './offline-data'
/** Replaces `userEntitlements` via JSON Patch, and unions refs before the write. */
export { patchUserEntitlements, unionUserEntitlements } from './patch-user-entitlements'
/** Resolves invoke `identityId` by `id` then `cisIdentityId`. */
export { resolveMachineIdentityByIdentityId } from './resolve-by-identity-id'
export type { MachineIdentityRecord, UserEntitlementRef } from './types'
