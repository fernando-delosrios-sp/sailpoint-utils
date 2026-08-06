import { RESERVED_OUTPUT_KEYS } from './output-schema'
import { inferFromTsType, OperationField } from './schema-inference'
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

function outputFieldType(fieldName: string, outputFields: OperationField[] | undefined): string | undefined {
    return outputFields?.find((field) => field.name === fieldName)?.type
}

/** Formats an operation output value for ISC account attribute storage using typed inference. */
export function formatAttributeValue(value: unknown, fieldType?: string): unknown {
    if (value === null || value === undefined) {
        return undefined
    }

    if (Array.isArray(value)) {
        const elementType = fieldType ? inferFromTsType(fieldType).type : 'STRING'
        return value.map((item) => formatScalarValue(item, elementType))
    }

    if (fieldType) {
        const { type, isMulti } = inferFromTsType(fieldType)
        if (isMulti && Array.isArray(value)) {
            return value.map((item) => formatScalarValue(item, type))
        }
        return formatScalarValue(value, type)
    }

    if (typeof value === 'string') {
        return value
    }
    if (typeof value === 'number' || typeof value === 'boolean' || typeof value === 'bigint') {
        return value
    }
    if (value instanceof Date) {
        return value.toISOString()
    }
    return JSON.stringify(value)
}

function formatScalarValue(value: unknown, iscType: string): unknown {
    if (value === null || value === undefined) {
        return undefined
    }

    switch (iscType) {
        case 'INT':
            return typeof value === 'number' ? value : Number(value)
        case 'BOOLEAN':
            return typeof value === 'boolean' ? value : value === 'true' || value === true
        case 'LONG':
            return typeof value === 'bigint' ? value : BigInt(String(value))
        case 'DATE':
            return value instanceof Date ? value.toISOString() : String(value)
        case 'STRING':
        default:
            if (typeof value === 'string') {
                return value
            }
            if (typeof value === 'number' || typeof value === 'boolean' || typeof value === 'bigint') {
                return String(value)
            }
            return JSON.stringify(value)
    }
}

/** @deprecated Use {@link formatAttributeValue} for typed persist formatting. */
export function serializeAttributeValue(value: unknown): string | undefined {
    const formatted = formatAttributeValue(value)
    if (formatted === undefined) {
        return undefined
    }
    return typeof formatted === 'string' ? formatted : String(formatted)
}

export function buildAccountAttributes<TOutput extends object>(
    sourceId: string,
    id: string,
    attributes: Partial<TOutput> | undefined,
    status: string | undefined,
    outputFields: OperationField[] | undefined,
    now: () => Date = () => new Date()
): Record<string, unknown> {
    const result: Record<string, unknown> = {
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

        const formatted = formatAttributeValue(value, outputFieldType(key, outputFields))
        if (formatted !== undefined) {
            result[key] = formatted
        }
    }

    return result
}

function comparableKeys(expected: Record<string, unknown>): string[] {
    const authorKeys = Object.keys(expected).filter((key) => !RESERVED_OUTPUT_KEYS.has(key) && key !== 'status')
    return ['status', ...authorKeys]
}

function normalizeForComparison(value: unknown): string {
    if (value === null || value === undefined) {
        return ''
    }
    if (typeof value === 'boolean') {
        return value ? 'true' : 'false'
    }
    if (typeof value === 'number' || typeof value === 'bigint') {
        return String(value)
    }
    if (Array.isArray(value)) {
        return JSON.stringify(value)
    }
    return String(value)
}

function coerceReadBackValue(expected: unknown, actual: unknown): unknown {
    if (actual === null || actual === undefined) {
        return actual
    }

    if (typeof expected === 'number' && typeof actual === 'string') {
        const parsed = Number(actual)
        return Number.isNaN(parsed) ? actual : parsed
    }

    if (typeof expected === 'boolean') {
        if (typeof actual === 'string') {
            return actual === 'true'
        }
        return Boolean(actual)
    }

    if (typeof expected === 'bigint') {
        try {
            return BigInt(String(actual))
        } catch {
            return actual
        }
    }

    if (Array.isArray(expected) && typeof actual === 'string') {
        try {
            return JSON.parse(actual)
        } catch {
            return actual
        }
    }

    return actual
}

/** Returns human-readable mismatch descriptions, or empty array when attributes match. */
export function verifyPersistedAccount(
    expected: Record<string, unknown>,
    actual: Record<string, unknown>
): string[] {
    const mismatches: string[] = []

    for (const key of comparableKeys(expected)) {
        const expectedValue = expected[key]
        const actualValue = coerceReadBackValue(expectedValue, actual[key])
        if (normalizeForComparison(actualValue) !== normalizeForComparison(expectedValue)) {
            mismatches.push(`${key}: expected "${normalizeForComparison(expectedValue)}", got "${normalizeForComparison(actualValue)}"`)
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
): Promise<Record<string, unknown> | undefined> {
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
    expected: Record<string, unknown>
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
 * Reconciles source schema before write. Verification runs by default.
 */
export function createPersist<TOutput extends object>(
    deps: PersistDependencies,
    registry: WriteRegistry
): PersistFn<TOutput> {
    return async (id: string, attributes?: Partial<TOutput>, status?: string, options?: { verify?: boolean }) => {
        const attributeKeys = attributes ? Object.keys(attributes) : []
        if (deps.ensureSourceSchema) {
            await deps.ensureSourceSchema(attributeKeys)
        }

        const built = buildAccountAttributes(
            deps.sourceId,
            id,
            attributes,
            status,
            deps.operationSchema?.outputFields
        )
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
