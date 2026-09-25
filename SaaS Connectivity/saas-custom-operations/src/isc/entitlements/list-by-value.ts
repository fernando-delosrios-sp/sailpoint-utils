import { EntitlementsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { escapeODataString } from '../accounts'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { EntitlementRef } from './types'

const PAGE_SIZE = 250
const VALUES_PER_FILTER = 50

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

async function listEntitlementsByFilter(entitlements: EntitlementsApi, filters: string): Promise<EntitlementRef[]> {
    const matches: EntitlementRef[] = []
    let offset = 0

    while (true) {
        const request = { filters, offset, limit: PAGE_SIZE }
        logIscDebug('listEntitlements listEntitlementsV1 request', request)
        const response = await entitlements.listEntitlementsV1(request)
        const page = response.data ?? []
        for (const raw of page) {
            const mapped = mapEntitlement(raw)
            if (mapped) {
                matches.push(mapped)
            }
        }
        if (page.length < PAGE_SIZE) {
            return matches
        }
        offset += PAGE_SIZE
    }
}

/** Lists entitlements whose value equals the caller-supplied string. */
export async function listEntitlementsByValue(entitlements: EntitlementsApi, value: string): Promise<EntitlementRef[]> {
    const escaped = escapeODataString(value)
    const filters = `value eq "${escaped}"`

    logIscDebug('listEntitlementsByValue start', { value, filters })

    try {
        return await listEntitlementsByFilter(entitlements, filters)
    } catch (error) {
        logIscRequestFailure('listEntitlementsByValue listEntitlementsV1', error)
        throw toConnectorError(error, 'Failed to list entitlements by value')
    }
}

/** Lists entitlements matching any supplied value, batching filters to bound request size. */
export async function listEntitlementsByValues(
    entitlements: EntitlementsApi,
    values: readonly string[]
): Promise<EntitlementRef[]> {
    const uniqueValues = [...new Set(values)]
    const matches: EntitlementRef[] = []

    try {
        for (let index = 0; index < uniqueValues.length; index += VALUES_PER_FILTER) {
            const filterValues = uniqueValues
                .slice(index, index + VALUES_PER_FILTER)
                .map((value) => `"${escapeODataString(value)}"`)
                .join(',')
            matches.push(...(await listEntitlementsByFilter(entitlements, `value in (${filterValues})`)))
        }
        return matches
    } catch (error) {
        logIscRequestFailure('listEntitlementsByValues listEntitlementsV1', error)
        throw toConnectorError(error, 'Failed to list entitlements by values')
    }
}
