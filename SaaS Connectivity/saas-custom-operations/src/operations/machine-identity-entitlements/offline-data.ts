import { SchemaPayload } from '../../isc/sources'
import { OFFLINE_MACHINE_IDENTITIES } from '../../isc/machine-identities'

export { listMachineIdentitiesOffline, resolveMachineIdentityByIdentityIdOffline } from '../../isc/machine-identities'
export { listEntitlementsByValueOffline } from '../../isc/entitlements'

export interface OfflineUnderlyingAccount {
    identityKey: string
    sourceId: string
    attributes: Record<string, unknown>
}

/** Canned underlying accounts for offline evaluation (correlated by cisIdentityId then id). */
export const OFFLINE_UNDERLYING_ACCOUNTS: OfflineUnderlyingAccount[] = [
    {
        identityKey: 'cis-offline-1',
        sourceId: 'src-offline-1',
        attributes: { appRole: 'CN=Admins' },
    },
    {
        identityKey: 'cis-offline-1',
        sourceId: 'src-offline-2',
        attributes: { groups: ['CN=A', ' ', 'CN=B'] },
    },
    {
        identityKey: 'cis-offline-2',
        sourceId: 'src-offline-1',
        attributes: { appRole: 'CN=Admins' },
    },
    {
        identityKey: 'cis-offline-2',
        sourceId: 'src-offline-skip',
        attributes: { leftover: 'CN=Ignored' },
    },
    {
        identityKey: 'cis-offline-2',
        sourceId: 'src-offline-unknown-attr',
        attributes: { other: 'CN=Ignored' },
    },
]

export const OFFLINE_ACCOUNT_SCHEMAS: Record<string, SchemaPayload> = {
    'src-offline-1': {
        name: 'account',
        configuration: { inboundEntitlements: 'appRole' },
        attributes: [{ name: 'appRole', type: 'STRING', isMulti: false }],
    },
    'src-offline-2': {
        name: 'account',
        configuration: { inboundEntitlements: 'groups' },
        attributes: [{ name: 'groups', type: 'STRING', isMulti: true }],
    },
    'src-offline-skip': {
        name: 'account',
        attributes: [{ name: 'leftover', type: 'STRING' }],
    },
    'src-offline-unknown-attr': {
        name: 'account',
        configuration: { inboundEntitlements: 'groups' },
        attributes: [{ name: 'other', type: 'STRING' }],
    },
}

export function listOfflineUnderlyingAccounts(identityKey: string): OfflineUnderlyingAccount[] {
    return OFFLINE_UNDERLYING_ACCOUNTS.filter((account) => account.identityKey === identityKey)
}

export function getOfflineAccountSchema(sourceId: string): SchemaPayload | undefined {
    return OFFLINE_ACCOUNT_SCHEMAS[sourceId]
}

export function identityCorrelationKey(identity: { id: string; cisIdentityId?: string }): string {
    return identity.cisIdentityId ?? identity.id
}

export { OFFLINE_MACHINE_IDENTITIES }
