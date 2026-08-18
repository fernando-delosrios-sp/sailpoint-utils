import {
    buildAccountAttributes,
    formatAccountContentsForLog,
    mergePersistAttributes,
    PersistVerificationError,
} from './persist-result'
import { FrameworkLogger } from './logger'
import { recordInhibitedPersist } from './payload-persist-collector'
import { OperationSchemaContract, PersistFn, PersistOptions, VerifyPersistedFn, WriteRegistry } from './types'

export interface TestModePersistOptions {
    sourceId: string
    operationSchema?: OperationSchemaContract
    onPersist?: () => void
    logger?: FrameworkLogger
}

/** Persist/verify implementations that log inhibited writes instead of calling ISC. */
export function createTestModePersist<TOutput extends object>(
    options: TestModePersistOptions,
    registry: WriteRegistry
): { persist: PersistFn<TOutput>; verifyPersisted: VerifyPersistedFn } {
    const log = options.logger

    const persist: PersistFn<TOutput> = async (id, attributes, status, persistOptions?: PersistOptions) => {
        const mergedAttributes = mergePersistAttributes(attributes, persistOptions)
        const attributeKeys = mergedAttributes ? Object.keys(mergedAttributes) : []
        if (attributeKeys.length > 0) {
            log?.info(`[test-mode] inhibited ensureSourceSchema keys=${attributeKeys.join(',')}`)
        }

        const built = buildAccountAttributes(
            options.sourceId,
            id,
            mergedAttributes,
            status,
            options.operationSchema?.outputFields
        )
        registry.set(id, built)
        recordInhibitedPersist({ identity: id, status: String(built.status ?? 'success'), attributes: built })
        log?.info(
            `[test-mode] inhibited persist identity=${id} status=${built.status} ${formatAccountContentsForLog(built)}`
        )
        options.onPersist?.()
    }

    const verifyPersisted: VerifyPersistedFn = async (ids) => {
        log?.info(`[test-mode] inhibited verifyPersisted identities=${ids.join(',')}`)
        for (const id of ids) {
            const expected = registry.get(id)
            if (!expected) {
                throw new PersistVerificationError(
                    id,
                    `Identity ${id} was not persisted in this invocation`
                )
            }
        }
    }

    return { persist, verifyPersisted }
}


