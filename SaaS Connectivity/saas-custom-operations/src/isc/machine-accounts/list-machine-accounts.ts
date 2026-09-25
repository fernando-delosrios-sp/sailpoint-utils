import { MachineAccountsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { MachineAccountRecord } from './types'

export const MACHINE_ACCOUNT_PAGE_SIZE = 250
const EXPERIMENTAL_HEADER = 'true'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function mapMachineAccount(raw: unknown): MachineAccountRecord | undefined {
    if (!isRecord(raw) || typeof raw.id !== 'string') {
        return undefined
    }
    const machineIdentity = isRecord(raw.machineIdentity) ? raw.machineIdentity : undefined
    const source = isRecord(raw.source) ? raw.source : undefined
    if (typeof machineIdentity?.id !== 'string' || typeof source?.id !== 'string') {
        return undefined
    }
    return {
        id: raw.id,
        machineIdentity: {
            id: machineIdentity.id,
            ...(typeof machineIdentity.name === 'string' ? { name: machineIdentity.name } : {}),
        },
        source: {
            id: source.id,
            ...(typeof source.name === 'string' ? { name: source.name } : {}),
        },
        connectorAttributes: isRecord(raw.connectorAttributes) ? raw.connectorAttributes : {},
    }
}

/** Lists machine accounts with their authoritative machineIdentity link and connector attributes. */
export async function listMachineAccounts(machineAccounts: MachineAccountsApi): Promise<MachineAccountRecord[]> {
    const records: MachineAccountRecord[] = []
    let offset = 0

    try {
        while (true) {
            const request = {
                offset,
                limit: MACHINE_ACCOUNT_PAGE_SIZE,
                xSailPointExperimental: EXPERIMENTAL_HEADER,
            }
            logIscDebug('listMachineAccounts listMachineAccountsV1 request', request)
            const response = await machineAccounts.listMachineAccountsV1(request)
            const page = response.data ?? []
            for (const raw of page) {
                const mapped = mapMachineAccount(raw)
                if (mapped) {
                    records.push(mapped)
                }
            }
            if (page.length < MACHINE_ACCOUNT_PAGE_SIZE) {
                break
            }
            offset += MACHINE_ACCOUNT_PAGE_SIZE
        }
        return records
    } catch (error) {
        logIscRequestFailure('listMachineAccounts listMachineAccountsV1', error)
        throw toConnectorError(error, 'Failed to list machine accounts')
    }
}
