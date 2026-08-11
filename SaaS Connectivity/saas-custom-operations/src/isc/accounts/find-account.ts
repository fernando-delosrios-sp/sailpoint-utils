import { AccountsApi } from 'sailpoint-api-client'
import { listAccounts } from './account-client'
import { SourceAccountMatch } from './types'

const SOURCE_SCAN_PAGE_SIZE = 250

/** Escapes a value for use inside OData double-quoted string literals. */
export function escapeODataString(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/"/g, '""')
}

function accountMatchesNativeIdentity(
    account: { nativeIdentity?: string | null; name?: string | null; attributes?: unknown },
    nativeIdentity: string
): boolean {
    const attrs = (account.attributes ?? {}) as Record<string, unknown>
    return (
        account.nativeIdentity === nativeIdentity ||
        account.name === nativeIdentity ||
        attrs.id === nativeIdentity
    )
}

function accountOnSource(
    account: {
        id?: string
        sourceId?: string
        nativeIdentity?: string | null
        name?: string | null
        attributes?: unknown
    },
    sourceId: string,
    nativeIdentity: string
): SourceAccountMatch | undefined {
    if (!account.id || account.sourceId !== sourceId || !accountMatchesNativeIdentity(account, nativeIdentity)) {
        return undefined
    }

    return {
        id: account.id,
        attributes: (account.attributes ?? {}) as Record<string, unknown>,
    }
}

function isHttpStatus(error: unknown, status: number): boolean {
    if (typeof error !== 'object' || error === null) {
        return false
    }

    const candidate = error as { status?: number; response?: { status?: number } }
    return candidate.status === status || candidate.response?.status === status
}

async function listAccountsMatchingFilter(
    accounts: AccountsApi,
    filters: string,
    sourceId: string,
    nativeIdentity: string
): Promise<SourceAccountMatch | undefined> {
    const page = await listAccounts(accounts, {
        filters,
        limit: SOURCE_SCAN_PAGE_SIZE,
        detailLevel: 'FULL',
    })

    for (const account of page) {
        if (account && !account.id) {
            throw new Error(
                `Account for native identity ${nativeIdentity} on source ${sourceId} is missing ISC account id`
            )
        }

        const match = accountOnSource(account, sourceId, nativeIdentity)
        if (match) {
            return match
        }
    }

    return undefined
}

async function scanAccountsOnSourceForIdentity(
    accounts: AccountsApi,
    sourceId: string,
    nativeIdentity: string
): Promise<SourceAccountMatch | undefined> {
    let offset = 0

    while (true) {
        const page = await listAccounts(accounts, {
            filters: `sourceId eq "${sourceId}"`,
            limit: SOURCE_SCAN_PAGE_SIZE,
            offset,
            detailLevel: 'FULL',
        })

        for (const account of page) {
            if (!account.id || account.sourceId !== sourceId) {
                continue
            }

            const attrs = (account.attributes ?? {}) as Record<string, unknown>
            if (
                attrs.id === nativeIdentity ||
                account.nativeIdentity === nativeIdentity ||
                account.name === nativeIdentity
            ) {
                return { id: account.id, attributes: attrs }
            }
        }

        if (page.length < SOURCE_SCAN_PAGE_SIZE) {
            return undefined
        }

        offset += SOURCE_SCAN_PAGE_SIZE
    }
}

/** Looks up an account on a source by native identity. */
export async function findAccountOnSource(
    accounts: AccountsApi,
    sourceId: string,
    nativeIdentity: string
): Promise<SourceAccountMatch | undefined> {
    const escaped = escapeODataString(nativeIdentity)
    const sourceFilter = `sourceId eq "${sourceId}"`

    const lookupFilters = [
        `nativeIdentity eq "${escaped}" and ${sourceFilter}`,
        `nativeIdentity eq "${escaped}"`,
        `name eq "${escaped}" and ${sourceFilter}`,
        `name eq "${escaped}"`,
        `attributes.id eq "${escaped}" and ${sourceFilter}`,
        `attributes.id eq "${escaped}"`,
    ]

    for (const filters of lookupFilters) {
        let match: SourceAccountMatch | undefined
        try {
            match = await listAccountsMatchingFilter(accounts, filters, sourceId, nativeIdentity)
        } catch (error) {
            if (isHttpStatus(error, 400)) {
                continue
            }
            throw error
        }

        if (match) {
            if (filters.startsWith('nativeIdentity eq') && !filters.includes('sourceId eq')) {
                console.log(`[persist] located identity=${nativeIdentity} via nativeIdentity filter`)
            } else if (filters.startsWith('name eq')) {
                console.log(`[persist] located identity=${nativeIdentity} via name filter`)
            }
            return match
        }
    }

    const byScan = await scanAccountsOnSourceForIdentity(accounts, sourceId, nativeIdentity)
    if (byScan) {
        console.log(`[persist] located identity=${nativeIdentity} via source scan`)
    }
    return byScan
}
