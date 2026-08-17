import { RolesApi, SearchApi } from 'sailpoint-api-client'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { isListApiScopeFilter, listEnabledCatalogViaSearch } from '../catalog-search'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { toConnectorError } from '../../framework/connector-error'

export interface CatalogAccessItem {
    id: string
    name: string
    type: 'ROLE' | 'ACCESS_PROFILE'
}

const PAGE_SIZE = 50

function buildScopeFilter(scope: string): string | undefined {
    if (scope === '*') {
        return undefined
    }
    return scope
}

function isEnabledCatalogItem(enabled: boolean | undefined): boolean {
    return enabled !== false
}

/** Paginated list of enabled roles with optional scope filter. */
export async function listEnabledRoles(
    roles: RolesApi,
    scope = '*',
    search?: SearchApi
): Promise<CatalogAccessItem[]> {
    const useListApi = isListApiScopeFilter(scope)
    logIscDebug('listEnabledRoles route', {
        scope,
        scopeLength: scope.length,
        useListApi,
        searchClientPresent: Boolean(search),
    })

    if (!useListApi) {
        if (!search) {
            logIscDebug('listEnabledRoles abort', { reason: 'SearchApi client missing for ISC search scope' })
            throw new ConnectorError('SearchApi client is required to list roles with ISC search scope')
        }
        return listEnabledCatalogViaSearch(search, 'roles', 'ROLE', scope)
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
            logIscDebug('listEnabledRoles listRolesV1 request', request)

            const response = await roles.listRolesV1(request)
            const page = response.data ?? []
            logIscDebug('listEnabledRoles listRolesV1 response', {
                offset,
                pageSize: page.length,
                totalCollected: items.length,
            })

            for (const role of page) {
                if (role.id && role.name && isEnabledCatalogItem(role.enabled)) {
                    items.push({ id: role.id, name: role.name, type: 'ROLE' })
                }
            }

            if (page.length < PAGE_SIZE) {
                break
            }

            offset += PAGE_SIZE
        }

        logIscDebug('listEnabledRoles complete', { count: items.length })
        return items
    } catch (error) {
        logIscRequestFailure('listEnabledRoles listRolesV1', error)
        throw toConnectorError(error, 'Failed to list roles')
    }
}
