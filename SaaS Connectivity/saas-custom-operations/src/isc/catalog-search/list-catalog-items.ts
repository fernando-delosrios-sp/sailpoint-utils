import { SearchApi } from 'sailpoint-api-client'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { toConnectorError } from '../../framework/connector-error'
import { CatalogAccessItem } from '../roles/list-enabled-roles'

const SEARCH_PAGE_SIZE = 250

export function isWildcardScope(scope: string): boolean {
    const trimmed = scope.trim()
    return trimmed === '' || trimmed === '*'
}

/** True when scope uses V3 list filter operators (e.g. `name sw "Finance-"`). */
export function isListApiScopeFilter(scope: string): boolean {
    if (isWildcardScope(scope)) {
        return false
    }
    return /\s(eq|sw|co|gt|ge|lt|le|in)\s/i.test(scope)
}

export function buildEnabledSearchQuery(scope: string): string {
    if (isWildcardScope(scope)) {
        return 'enabled:true'
    }
    return `enabled:true AND (${scope.trim()})`
}

/** Paginated ISC search for enabled catalog items in roles or accessprofiles indices. */
export async function listEnabledCatalogViaSearch(
    search: SearchApi,
    index: 'roles' | 'accessprofiles',
    type: CatalogAccessItem['type'],
    scope: string
): Promise<CatalogAccessItem[]> {
    const items: CatalogAccessItem[] = []
    let offset = 0
    const query = buildEnabledSearchQuery(scope)
    logIscDebug('listEnabledCatalogViaSearch start', { index, type, scope, query })

    try {
        while (true) {
            const request = {
                offset,
                limit: SEARCH_PAGE_SIZE,
                search: {
                    indices: [index],
                    query: { query },
                },
            }
            logIscDebug('listEnabledCatalogViaSearch searchPostV1 request', request)

            const response = await search.searchPostV1(request)

            const page = (response.data ?? []) as Array<{ id?: string; name?: string }>
            logIscDebug('listEnabledCatalogViaSearch searchPostV1 response', {
                index,
                offset,
                pageSize: page.length,
                totalCollected: items.length,
            })
            for (const doc of page) {
                if (doc.id && doc.name) {
                    items.push({ id: doc.id, name: doc.name, type })
                }
            }

            if (page.length < SEARCH_PAGE_SIZE) {
                break
            }

            offset += SEARCH_PAGE_SIZE
        }

        logIscDebug('listEnabledCatalogViaSearch complete', { index, type, count: items.length })
        return items
    } catch (error) {
        const label = type === 'ROLE' ? 'roles' : 'access profiles'
        logIscRequestFailure(`listEnabledCatalogViaSearch ${label}`, error)
        throw toConnectorError(error, `Failed to search ${label}`)
    }
}
