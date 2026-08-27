import { AccessProfilesApi, SearchApi } from 'sailpoint-api-client'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { isListApiScopeFilter, listEnabledCatalogViaSearch } from '../catalog-search'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { toConnectorError } from '../../framework/connector-error'
import { CatalogAccessItem } from '../roles/list-enabled-roles'

const PAGE_SIZE = 250

function buildScopeFilter(scope: string): string | undefined {
    if (scope === '*') {
        return undefined
    }
    return scope
}

function isEnabledCatalogItem(enabled: boolean | undefined): boolean {
    return enabled !== false
}

/** Paginated list of enabled access profiles with optional scope filter. */
export async function listEnabledAccessProfiles(
    accessProfiles: AccessProfilesApi,
    scope = '*',
    search?: SearchApi
): Promise<CatalogAccessItem[]> {
    const useListApi = isListApiScopeFilter(scope)
    logIscDebug('listEnabledAccessProfiles route', {
        scope,
        scopeLength: scope.length,
        useListApi,
        searchClientPresent: Boolean(search),
    })

    if (!useListApi) {
        if (!search) {
            logIscDebug('listEnabledAccessProfiles abort', { reason: 'SearchApi client missing for ISC search scope' })
            throw new ConnectorError('SearchApi client is required to list access profiles with ISC search scope')
        }
        return listEnabledCatalogViaSearch(search, 'accessprofiles', 'ACCESS_PROFILE', scope)
    }

    const items: CatalogAccessItem[] = []
    let offset = 0
    const filters = buildScopeFilter(scope)

    try {
        while (true) {
            const request = {
                offset,
                limit: PAGE_SIZE,
                ...(filters ? { filters } : {}),
            }
            logIscDebug('listEnabledAccessProfiles listAccessProfilesV1 request', request)

            const response = await accessProfiles.listAccessProfilesV1(request)
            const page = response.data ?? []
            logIscDebug('listEnabledAccessProfiles listAccessProfilesV1 response', {
                offset,
                pageSize: page.length,
                totalCollected: items.length,
            })

            for (const profile of page) {
                if (profile.id && profile.name && isEnabledCatalogItem(profile.enabled)) {
                    items.push({ id: profile.id, name: profile.name, type: 'ACCESS_PROFILE' })
                }
            }

            if (page.length < PAGE_SIZE) {
                break
            }

            offset += PAGE_SIZE
        }

        logIscDebug('listEnabledAccessProfiles complete', { count: items.length })
        return items
    } catch (error) {
        logIscRequestFailure('listEnabledAccessProfiles listAccessProfilesV1', error)
        throw toConnectorError(error, 'Failed to list access profiles')
    }
}
