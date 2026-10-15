import { TaggedObjectsApi } from 'sailpoint-api-client'
import { toConnectorError } from '../../framework/connector-error'
import { logIscDebug, logIscRequestFailure } from '../debug/log-isc-request'
import { TaggedObjectRef, TaggedObjectType } from './types'

const PAGE_SIZE = 250

const RECONCILED_TYPES = new Set<TaggedObjectType>(['ENTITLEMENT', 'ACCESS_PROFILE', 'ROLE', 'IDENTITY'])

/** Lists objects currently carrying a tag, limited to reconciled object types. */
export async function listObjectsByTag(
    taggedObjects: TaggedObjectsApi,
    tagName: string,
    allowedTypes: ReadonlySet<TaggedObjectType> = RECONCILED_TYPES
): Promise<TaggedObjectRef[]> {
    const refs: TaggedObjectRef[] = []
    let offset = 0
    const filters = `tagName eq "${tagName.replace(/"/g, '\\"')}"`

    try {
        while (true) {
            const request = { offset, limit: PAGE_SIZE, filters }
            logIscDebug('listObjectsByTag listTaggedObjectsV1 request', request)
            const response = await taggedObjects.listTaggedObjectsV1(request)
            const page = response.data ?? []
            for (const item of page) {
                const id = item.objectRef?.id
                const type = item.objectRef?.type as TaggedObjectType | undefined
                if (!id || !type || !allowedTypes.has(type)) {
                    continue
                }
                refs.push({ type, id })
            }
            if (page.length < PAGE_SIZE) {
                break
            }
            offset += PAGE_SIZE
        }
        logIscDebug('listObjectsByTag complete', { tagName, count: refs.length })
        return refs
    } catch (error) {
        logIscRequestFailure('listObjectsByTag listTaggedObjectsV1', error)
        throw toConnectorError(error, `Failed to list objects with tag ${tagName}`)
    }
}
