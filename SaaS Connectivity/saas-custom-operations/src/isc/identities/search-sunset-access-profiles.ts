import { SearchApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { extractManagerId } from './resolve-manager-id'
import type { IdentityWithSunsetAccessProfiles, SunsetAccessProfileAssignment } from './types'

const SEARCH_PAGE_SIZE = 250
const SUNSET_ACCESS_QUERY = '@access(type:ACCESS_PROFILE AND removeDate:*)'

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function readString(value: unknown): string | undefined {
    return typeof value === 'string' && value.trim() !== '' ? value : undefined
}

function asAccessArray(value: unknown): unknown[] {
    if (Array.isArray(value)) {
        return value
    }
    if (isRecord(value) && Array.isArray(value.access)) {
        return value.access
    }
    return []
}

function extractSourceName(item: Record<string, unknown>): string | undefined {
    const sourceName = readString(item.sourceName)
    if (sourceName) {
        return sourceName
    }
    const source = item.source
    if (isRecord(source)) {
        return readString(source.name) ?? readString(source.displayName)
    }
    return undefined
}

function isAccessProfileType(type: unknown): boolean {
    if (typeof type !== 'string') {
        return false
    }
    const normalized = type.trim().toUpperCase().replace(/[\s-]/g, '_')
    return normalized === 'ACCESS_PROFILE' || normalized === 'ACCESSPROFILE'
}

/** Maps a single access entry to a sunset ACCESS_PROFILE assignment when applicable. */
export function mapSunsetAccessProfileAssignment(item: unknown): SunsetAccessProfileAssignment | undefined {
    if (!isRecord(item)) {
        return undefined
    }
    if (!isAccessProfileType(item.type)) {
        return undefined
    }

    const id = readString(item.id)
    const removeDate = readString(item.removeDate)
    if (!id || !removeDate) {
        return undefined
    }

    return {
        id,
        name: readString(item.name) ?? readString(item.displayName) ?? id,
        removeDate,
        sourceName: extractSourceName(item),
    }
}

/** Maps an identities-index search document to sunset ACCESS_PROFILE assignments. */
export function mapIdentityWithSunsetAccessProfiles(
    doc: unknown
): IdentityWithSunsetAccessProfiles | undefined {
    if (!isRecord(doc)) {
        return undefined
    }

    const id = readString(doc.id)
    if (!id) {
        return undefined
    }

    const accessProfiles = asAccessArray(doc.access)
        .map(mapSunsetAccessProfileAssignment)
        .filter((assignment): assignment is SunsetAccessProfileAssignment => assignment !== undefined)

    if (accessProfiles.length === 0) {
        return undefined
    }

    return {
        id,
        displayName: readString(doc.displayName) ?? readString(doc.name) ?? id,
        managerId: extractManagerId(doc),
        accessProfiles,
    }
}

/** Searches identities that have ACCESS_PROFILE assignments with a removeDate. */
export async function searchIdentitiesWithSunsetAccessProfiles(
    search: SearchApi
): Promise<IdentityWithSunsetAccessProfiles[]> {
    const identities: IdentityWithSunsetAccessProfiles[] = []
    let offset = 0
    logIscDebug('searchIdentitiesWithSunsetAccessProfiles start', { query: SUNSET_ACCESS_QUERY })

    try {
        while (true) {
            logIscDebug('searchIdentitiesWithSunsetAccessProfiles searchPostV1 request', {
                offset,
                limit: SEARCH_PAGE_SIZE,
                query: SUNSET_ACCESS_QUERY,
            })

            const response = await search.searchPostV1({
                offset,
                limit: SEARCH_PAGE_SIZE,
                search: {
                    indices: ['identities'],
                    query: { query: SUNSET_ACCESS_QUERY },
                    includeNested: true,
                },
            })
            const page = (response.data ?? []) as unknown[]
            logIscDebug('searchIdentitiesWithSunsetAccessProfiles searchPostV1 response', {
                offset,
                pageSize: page.length,
                totalCollected: identities.length,
            })

            for (const doc of page) {
                const mapped = mapIdentityWithSunsetAccessProfiles(doc)
                if (mapped) {
                    identities.push(mapped)
                }
            }

            if (page.length < SEARCH_PAGE_SIZE) {
                break
            }
            offset += SEARCH_PAGE_SIZE
        }

        logIscDebug('searchIdentitiesWithSunsetAccessProfiles complete', { count: identities.length })
        return identities
    } catch (error) {
        logIscRequestFailure('searchIdentitiesWithSunsetAccessProfiles', error)
        throw toConnectorError(error, 'Failed to search identities with sunset access profiles')
    }
}
