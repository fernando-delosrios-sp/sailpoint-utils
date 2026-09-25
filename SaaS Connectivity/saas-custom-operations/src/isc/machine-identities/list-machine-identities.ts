import { MachineIdentitiesApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { mapMachineIdentity } from './map-machine-identity'
import { MachineIdentityRecord } from './types'

export const MACHINE_IDENTITY_PAGE_SIZE = 250
const EXPERIMENTAL_HEADER = 'true'

/** Lists machine identities with optional ISC filter, paginating until pages are exhausted. */
export async function listMachineIdentities(
    machineIdentities: MachineIdentitiesApi,
    filters?: string
): Promise<MachineIdentityRecord[]> {
    const records: MachineIdentityRecord[] = []
    let offset = 0

    logIscDebug('listMachineIdentities start', { filters: filters ?? null })

    try {
        while (true) {
            const request = {
                offset,
                limit: MACHINE_IDENTITY_PAGE_SIZE,
                xSailPointExperimental: EXPERIMENTAL_HEADER,
                ...(filters ? { filters } : {}),
            }
            logIscDebug('listMachineIdentities listMachineIdentitiesV1 request', request)

            const response = await machineIdentities.listMachineIdentitiesV1(request)
            const page = response.data ?? []
            logIscDebug('listMachineIdentities listMachineIdentitiesV1 response', {
                offset,
                pageSize: page.length,
                totalCollected: records.length,
            })

            for (const raw of page) {
                const mapped = mapMachineIdentity(raw)
                if (mapped) {
                    records.push(mapped)
                }
            }

            if (page.length < MACHINE_IDENTITY_PAGE_SIZE) {
                break
            }

            offset += MACHINE_IDENTITY_PAGE_SIZE
        }

        logIscDebug('listMachineIdentities complete', { count: records.length })
        return records
    } catch (error) {
        logIscRequestFailure('listMachineIdentities listMachineIdentitiesV1', error)
        throw toConnectorError(error, 'Failed to list machine identities')
    }
}
