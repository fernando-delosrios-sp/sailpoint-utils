import { TagsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'

function namesMatch(left: string, right: string): boolean {
    return left.trim().toLowerCase() === right.trim().toLowerCase()
}

/**
 * Ensures a tag with the given name exists, creating it when missing.
 * ISC tag names are case-insensitive unique (e.g. filter `privileged` returns `PRIVILEGED`);
 * returns the canonical name stored in the tenant.
 */
export async function ensureTag(tags: TagsApi, name: string): Promise<string> {
    const filters = `name eq "${name.replace(/"/g, '\\"')}"`
    logIscDebug('ensureTag listTagsV1', { name, filters })
    try {
        const listed = await tags.listTagsV1({ filters, limit: 1 })
        const existing = (listed.data ?? []).find((tag) => typeof tag.name === 'string' && namesMatch(tag.name, name))
        if (existing?.name) {
            return existing.name
        }
        logIscDebug('ensureTag createTagV1', { name })
        const created = await tags.createTagV1({ tag2: { name } as never })
        return created.data?.name ?? name
    } catch (error) {
        logIscRequestFailure('ensureTag', error)
        throw toConnectorError(error, `Failed to ensure tag ${name}`)
    }
}
