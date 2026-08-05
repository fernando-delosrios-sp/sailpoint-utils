import { PersistDependencies, PersistFn, VerifyPersistedFn, WriteRegistry } from './types'

const MAX_PARAMS = 9
const DEFAULT_STATUS = 'success'
/** ISC account indexing can take several seconds after createAccountV1. */
const DEFAULT_MAX_ATTEMPTS = 15
const DEFAULT_RETRY_DELAY_MS = 500

export class PersistVerificationError extends Error {
    constructor(
        public readonly identity: string,
        message: string
    ) {
        super(message)
        this.name = 'PersistVerificationError'
    }
}

export function buildAccountAttributes(
    sourceId: string,
    id: string,
    params: string[] | undefined,
    status: string | undefined,
    now: () => Date = () => new Date()
): Record<string, string> {
    const attributes: Record<string, string> = {
        sourceId,
        id,
        date: now().toISOString(),
        status: status ?? DEFAULT_STATUS,
    }

    params?.forEach((value, index) => {
        if (index < MAX_PARAMS) {
            attributes[`param${index + 1}`] = value
        }
    })

    return attributes
}

function comparableKeys(expected: Record<string, string>): string[] {
    // date is omitted: upsert read-back may return a prior timestamp until ISC re-indexes
    return ['status', ...Object.keys(expected).filter((key) => /^param\d+$/.test(key))]
}

/** Returns human-readable mismatch descriptions, or empty array when attributes match. */
export function verifyPersistedAccount(
    expected: Record<string, string>,
    actual: Record<string, string>
): string[] {
    const mismatches: string[] = []

    for (const key of comparableKeys(expected)) {
        if (actual[key] !== expected[key]) {
            mismatches.push(`${key}: expected "${expected[key]}", got "${actual[key] ?? ''}"`)
        }
    }

    return mismatches
}

async function defaultSleep(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms))
}

export async function readWithRetry(
    readAccount: PersistDependencies['readAccount'],
    id: string,
    maxAttempts = DEFAULT_MAX_ATTEMPTS,
    delayMs = DEFAULT_RETRY_DELAY_MS,
    sleep: (ms: number) => Promise<void> = defaultSleep
): Promise<Record<string, string> | undefined> {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const account = await readAccount(id)
        if (account) {
            return account
        }

        if (attempt < maxAttempts) {
            await sleep(delayMs)
        }
    }

    return undefined
}

export async function verifyAccountWrite(
    deps: PersistDependencies,
    id: string,
    expected: Record<string, string>
): Promise<void> {
    const sleep = deps.sleep ?? defaultSleep
    const actual = await readWithRetry(deps.readAccount, id, DEFAULT_MAX_ATTEMPTS, DEFAULT_RETRY_DELAY_MS, sleep)

    if (!actual) {
        throw new PersistVerificationError(id, `Verification failed for identity ${id}: account not found after retries`)
    }

    const mismatches = verifyPersistedAccount(expected, actual)
    if (mismatches.length > 0) {
        throw new PersistVerificationError(
            id,
            `Verification failed for identity ${id}: ${mismatches.join('; ')}`
        )
    }
}

/**
 * Persists operation output to the dummy source via account create (upsert semantics).
 * Signature: persist(id, params?, status?, options?) where id is the native account identity.
 * Verification runs by default; pass `{ verify: false }` to defer and call verifyPersisted later.
 */
export function createPersist(deps: PersistDependencies, registry: WriteRegistry): PersistFn {
    return async (id: string, params?: string[], status?: string, options?: { verify?: boolean }) => {
        const attributes = buildAccountAttributes(deps.sourceId, id, params, status)
        registry.set(id, attributes)
        await deps.createAccount(attributes)

        if (options?.verify !== false) {
            await verifyAccountWrite(deps, id, attributes)
        }

        console.log(`[persist] identity=${id} status=${attributes.status}`)
    }
}

/** Verifies a list of identities against attributes recorded during persist in this invocation. */
export function createVerifyPersisted(deps: PersistDependencies, registry: WriteRegistry): VerifyPersistedFn {
    return async (ids: string[]) => {
        for (const id of ids) {
            const expected = registry.get(id)
            if (!expected) {
                throw new PersistVerificationError(
                    id,
                    `Identity ${id} was not persisted in this invocation`
                )
            }

            await verifyAccountWrite(deps, id, expected)
        }
    }
}
