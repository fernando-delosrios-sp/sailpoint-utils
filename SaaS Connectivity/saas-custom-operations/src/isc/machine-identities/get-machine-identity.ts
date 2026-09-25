import { MachineIdentitiesApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { mapMachineIdentity } from './map-machine-identity'
import { MachineIdentityRecord } from './types'

const EXPERIMENTAL_HEADER = 'true'

/** Gets one machine identity by id, including userEntitlements. */
export async function getMachineIdentity(
    machineIdentities: MachineIdentitiesApi,
    id: string
): Promise<MachineIdentityRecord> {
    logIscDebug('getMachineIdentity start', { id })

    try {
        const request = { id, xSailPointExperimental: EXPERIMENTAL_HEADER }
        logIscDebug('getMachineIdentity getMachineIdentityV1 request', request)
        const response = await machineIdentities.getMachineIdentityV1(request)
        const mapped = mapMachineIdentity(response.data)
        if (!mapped) {
            throw toConnectorError(
                new Error('Machine identity response missing id'),
                `Failed to get machine identity ${id}`
            )
        }
        return mapped
    } catch (error) {
        logIscRequestFailure('getMachineIdentity getMachineIdentityV1', error)
        throw toConnectorError(error, `Failed to get machine identity ${id}`)
    }
}
