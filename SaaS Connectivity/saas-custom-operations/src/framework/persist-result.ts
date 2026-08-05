import { RESERVED_OUTPUT_KEYS } from './output-schema'
import { PersistDependencies, PersistFn, VerifyPersistedFn, WriteRegistry } from './types'

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

/** Serializes an operation output value for ISC account attribute storage. */
export function serializeAttributeValue(value: unknown): string | undefined {
    if (value === null || value === undefined) {
        return undefined
    }

    if (typeof value === 'string') {
        return value
    }

    if (typeof value === 'number' || typeof value === 'boolean' || typeof value === 'bigint') {
        return String(value)
    }

    return JSON.stringify(value)
}

export function buildAccountAttributes<TOutput extends object>(
    sourceId: string,
    id: string,
    attributes: Partial<TOutput> | undefined,
    status: string | undefined,
    now: () => Date = () => new Date()
): Record<string, string> {
    const result: Record<string, string> = {
        sourceId,
        id,
        date: now().toISOString(),
        status: status ?? DEFAULT_STATUS,
    }

    if (!attributes) {
        return result
    }

    for (const [key, value] of Object.entries(attributes)) {
        if (RESERVED_OUTPUT_KEYS.has(key)) {
            continue
        }

        const serialized = serializeAttributeValue(value)
        if (serialized !== undefined) {
            result[key] = serialized
        }
    }

    return result
}

function comparableKeys(expected: Record<string, string>): string[] {
    const authorKeys = Object.keys(expected).filter((key) => !RESERVED_OUTPUT_KEYS.has(key) && key !== 'status')
    return ['status', ...authorKeys]
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
 * Verification runs by default; pass `{ verify: false }` to defer and call verifyPersisted later.
 */
export function createPersist<TOutput extends object>(
    deps: PersistDependencies,
    registry: WriteRegistry
): PersistFn<TOutput> {
    return async (id: string, attributes?: Partial<TOutput>, status?: string, options?: { verify?: boolean }) => {
        const built = buildAccountAttributes(deps.sourceId, id, attributes, status)
        registry.set(id, built)
        await deps.createAccount(built)

        if (options?.verify !== false) {
            await verifyAccountWrite(deps, id, built)
        }

        console.log(`[persist] identity=${id} status=${built.status}`)
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
