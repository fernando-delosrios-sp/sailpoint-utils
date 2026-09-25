import { EntitlementsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { escapeODataString } from '../accounts'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { EntitlementRef } from './types'

const PAGE_SIZE = 250

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function mapEntitlement(raw: unknown): EntitlementRef | undefined {
    if (!isRecord(raw) || typeof raw.id !== 'string' || !raw.id) {
        return undefined
    }
    const source = isRecord(raw.source) ? raw.source : undefined
    const sourceId = typeof source?.id === 'string' ? source.id : undefined
    if (!sourceId) {
        return undefined
    }
    return {
        id: raw.id,
        sourceId,
        ...(typeof raw.value === 'string' ? { value: raw.value } : {}),
    }
}

/** Lists entitlements whose value equals the caller-supplied string. */
export async function listEntitlementsByValue(entitlements: EntitlementsApi, value: string): Promise<EntitlementRef[]> {
    const escaped = escapeODataString(value)
    const filters = `value eq "${escaped}"`
    const matches: EntitlementRef[] = []
    let offset = 0

    logIscDebug('listEntitlementsByValue start', { value, filters })

    try {
        while (true) {
            const request = { filters, offset, limit: PAGE_SIZE }
            logIscDebug('listEntitlementsByValue listEntitlementsV1 request', request)
            const response = await entitlements.listEntitlementsV1(request)
            const page = response.data ?? []
            for (const raw of page) {
                const mapped = mapEntitlement(raw)
                if (mapped) {
                    matches.push(mapped)
                }
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            offset += PAGE_SIZE
        }
        return matches
    } catch (error) {
        logIscRequestFailure('listEntitlementsByValue listEntitlementsV1', error)
        throw toConnectorError(error, 'Failed to list entitlements by value')
    }
}
