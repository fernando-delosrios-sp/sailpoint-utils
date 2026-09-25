import { MachineAccountRecord } from '../../isc/machine-accounts'
import { OFFLINE_MACHINE_IDENTITIES } from '../../isc/machine-identities'
import { SourcePayload } from '../../isc/sources'

export { resolveMachineIdentityByIdentityIdOffline } from '../../isc/machine-identities'
export { listEntitlementsByValueOffline } from '../../isc/entitlements'

/** Canned machine accounts with the same machineIdentity link and connectorAttributes as the live API. */
export const OFFLINE_MACHINE_ACCOUNTS: MachineAccountRecord[] = [
    {
        id: 'ma-offline-1',
        machineIdentity: { id: 'mi-offline-1' },
        source: { id: 'src-offline-1' },
        connectorAttributes: { appRole: ['CN=Admins', 'CN=A'] },
    },
    {
        id: 'ma-offline-2',
        machineIdentity: { id: 'mi-offline-1' },
        source: { id: 'src-offline-2' },
        connectorAttributes: { groups: [' ', 'CN=B'] },
    },
    {
        id: 'ma-offline-3',
        machineIdentity: { id: 'mi-offline-2' },
        source: { id: 'src-offline-1' },
        connectorAttributes: { appRole: ['CN=Admins', 'CN=Already'] },
    },
    {
        id: 'ma-offline-skip',
        machineIdentity: { id: 'mi-offline-2' },
        source: { id: 'src-offline-skip' },
        connectorAttributes: { leftover: 'CN=Ignored' },
    },
]

export const OFFLINE_SOURCES: Record<string, Pick<SourcePayload, 'connectorAttributes'>> = {
    'src-offline-1': {
        connectorAttributes: { userEntitlements: 'appRole' },
    },
    'src-offline-2': {
        connectorAttributes: { userEntitlements: 'groups' },
    },
    'src-offline-skip': { connectorAttributes: {} },
}

export function listMachineAccountsOffline(): MachineAccountRecord[] {
    return OFFLINE_MACHINE_ACCOUNTS
}

export function getOfflineSource(sourceId: string): SourcePayload | undefined {
    const source = OFFLINE_SOURCES[sourceId]
    return source ? (source as SourcePayload) : undefined
}

export { OFFLINE_MACHINE_IDENTITIES }
