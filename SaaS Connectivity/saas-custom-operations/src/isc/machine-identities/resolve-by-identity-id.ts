import { MachineIdentitiesApi } from 'sailpoint-api-client'
import { escapeODataString } from '../accounts'
import { listMachineIdentities } from './list-machine-identities'
import { MachineIdentityRecord } from './types'

/** Resolves invoke identityId by machine identity id, then cisIdentityId. Returns undefined when not found. */
export async function resolveMachineIdentityByIdentityId(
    machineIdentities: MachineIdentitiesApi,
    identityId: string
): Promise<MachineIdentityRecord | undefined> {
    const escaped = escapeODataString(identityId)
    const byId = await listMachineIdentities(machineIdentities, `id eq "${escaped}"`)
    if (byId[0]) {
        return byId[0]
    }

    const byCis = await listMachineIdentities(machineIdentities, `cisIdentityId eq "${escaped}"`)
    return byCis[0]
}
