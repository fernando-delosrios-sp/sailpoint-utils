import { AccountsApi, TaskManagementApi } from 'sailpoint-api-client'
import { RESERVED_OUTPUT_KEYS } from './output-schema'
import { inferFromTsType, OperationField } from './schema-inference'
import { PersistDependencies, PersistFn, VerifyPersistedFn, WriteRegistry } from './types'

const DEFAULT_STATUS = 'success'
/** ISC account indexing can take several seconds after createAccountV1. */
const DEFAULT_MAX_ATTEMPTS = 30
const DEFAULT_RETRY_DELAY_MS = 500
const POST_CREATE_LOOKUP_ATTEMPTS = 5
const SOURCE_SCAN_PAGE_SIZE = 250

interface AccountProvisioningTaskStatus {
    completed?: string | null
    completionStatus?: string | null
    messages?: Array<{
        type?: string
        key?: string
        localizedText?: { message?: string } | null
        parameters?: Record<string, unknown> | null
    }>
    target?: { id?: string; type?: string | null; name?: string }
    attributes?: Record<string, unknown>
}

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

/** Escapes a value for use inside OData double-quoted string literals. */
export function escapeODataString(value: string): string {
    return value.replace(/\\/g, '\\\\').replace(/"/g, '""')
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

async function readPersistedAccount(
    deps: PersistDependencies,
    nativeIdentity: string,
    iscAccountId?: string
): Promise<Record<string, unknown> | undefined> {
    if (iscAccountId && deps.readAccountByIscId) {
        return deps.readAccountByIscId(iscAccountId)
    }
    return deps.readAccount(nativeIdentity)
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
    expected: Record<string, unknown>,
    iscAccountId?: string
): Promise<void> {
    const sleep = deps.sleep ?? defaultSleep

    for (let attempt = 1; attempt <= DEFAULT_MAX_ATTEMPTS; attempt++) {
        const actual = await readPersistedAccount(deps, id, iscAccountId)

        if (actual) {
            const mismatches = verifyPersistedAccount(expected, actual)
            if (mismatches.length === 0) {
                return
            }
            if (attempt === DEFAULT_MAX_ATTEMPTS) {
                throw new PersistVerificationError(
                    id,
                    `Verification failed for identity ${id}: ${mismatches.join('; ')}`
                )
            }
        } else if (attempt === DEFAULT_MAX_ATTEMPTS) {
            const taskHint = iscAccountId
                ? ''
                : ' Check ISC task monitor for the createAccount taskId logged above.'
            throw new PersistVerificationError(
                id,
                `Verification failed for identity ${id}: account not found after retries.${taskHint}`
            )
        }

        if (attempt < DEFAULT_MAX_ATTEMPTS) {
            await sleep(DEFAULT_RETRY_DELAY_MS)
        }
    }
}

type SourceAccountMatch = { id: string; attributes: Record<string, unknown> }

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

async function listAccountsMatchingFilter(
    accounts: AccountsApi,
    filters: string,
    sourceId: string,
    nativeIdentity: string
): Promise<SourceAccountMatch | undefined> {
    const response = await accounts.listAccountsV1({
        filters,
        limit: SOURCE_SCAN_PAGE_SIZE,
        detailLevel: 'FULL',
    })

    for (const account of response.data ?? []) {
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
        const response = await accounts.listAccountsV1({
            filters: `sourceId eq "${sourceId}"`,
            limit: SOURCE_SCAN_PAGE_SIZE,
            offset,
            detailLevel: 'FULL',
        })
        const page = response.data ?? []

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

/** Looks up a result-source account by native identity. */
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
    ]

    for (const filters of lookupFilters) {
        const match = await listAccountsMatchingFilter(accounts, filters, sourceId, nativeIdentity)
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

const TASK_SUCCESS_STATUSES = new Set(['SUCCESS', 'WARNING'])

function formatTaskMessages(messages: Array<{ type?: string; localizedText?: { message?: string } | null; key?: string }> | undefined): string {
    if (!messages?.length) {
        return ''
    }

    const parts = messages
        .filter((message) => message.type === 'ERROR' || message.type === 'WARN')
        .map((message) => message.localizedText?.message ?? message.key)
        .filter(Boolean)

    return parts.length > 0 ? `: ${parts.join('; ')}` : ''
}

const ISC_ACCOUNT_ID_PATTERN = /^[a-f0-9]{32}$/i

/** Best-effort extraction of the ISC account UUID from a completed provisioning task. */
export function extractIscAccountIdFromProvisioningTask(task: AccountProvisioningTaskStatus): string | undefined {
    const candidates: string[] = []

    if (task.target?.id) {
        candidates.push(task.target.id)
    }

    for (const value of Object.values(task.attributes ?? {})) {
        if (typeof value === 'string') {
            candidates.push(value)
        }
    }

    for (const message of task.messages ?? []) {
        for (const value of Object.values(message.parameters ?? {})) {
            if (typeof value === 'string') {
                candidates.push(value)
            }
        }
    }

    return candidates.find((candidate) => ISC_ACCOUNT_ID_PATTERN.test(candidate))
}

/** Polls an ISC account provisioning task until it completes or fails. */
export async function waitForAccountProvisioningTask(
    tasks: TaskManagementApi,
    taskId: string,
    maxAttempts = DEFAULT_MAX_ATTEMPTS,
    delayMs = DEFAULT_RETRY_DELAY_MS,
    sleep: (ms: number) => Promise<void> = defaultSleep
): Promise<AccountProvisioningTaskStatus> {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const response = await tasks.getTaskStatusV1({ id: taskId })
        const task = response.data

        if (!task) {
            if (attempt === maxAttempts) {
                throw new Error(`Account provisioning task ${taskId} was not found`)
            }
        } else if (task.completed) {
            const completionStatus = task.completionStatus ?? 'UNKNOWN'
            if (TASK_SUCCESS_STATUSES.has(completionStatus)) {
                console.log(`[persist] account task ${taskId} completed with ${completionStatus}`)
                return task as AccountProvisioningTaskStatus
            }

            throw new Error(
                `Account provisioning task ${taskId} failed with ${completionStatus}${formatTaskMessages(task.messages)}`
            )
        }

        if (attempt < maxAttempts) {
            await sleep(delayMs)
        }
    }

    throw new Error(`Account provisioning task ${taskId} did not complete after retries`)
}

async function resolveAccountAfterProvisioning(
    accounts: AccountsApi,
    sourceId: string,
    nativeIdentity: string,
    task?: AccountProvisioningTaskStatus,
    maxAttempts = POST_CREATE_LOOKUP_ATTEMPTS,
    delayMs = DEFAULT_RETRY_DELAY_MS,
    sleep: (ms: number) => Promise<void> = defaultSleep
): Promise<string | undefined> {
    const taskAccountIds = [
        task?.target?.id,
        task ? extractIscAccountIdFromProvisioningTask(task) : undefined,
    ].filter((value): value is string => Boolean(value))

    for (const taskAccountId of taskAccountIds) {
        try {
            const response = await accounts.getAccountV1({ id: taskAccountId })
            const account = response.data
            if (account?.id && account.sourceId === sourceId) {
                console.log(`[persist] resolved identity=${nativeIdentity} iscAccountId=${account.id} from task`)
                return account.id
            }
        } catch {
            // Fall back to list-based lookup below.
        }
    }

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const found = await findAccountOnSource(accounts, sourceId, nativeIdentity)
        if (found?.id) {
            return found.id
        }

        if (attempt < maxAttempts) {
            await sleep(delayMs)
        }
    }

    return undefined
}

export interface UpsertSourceAccountOptions {
    waitForAccountTask?: (taskId: string) => Promise<AccountProvisioningTaskStatus>
}

/** Creates or updates a result-source account keyed by native identity. */
export async function upsertSourceAccount(
    accounts: AccountsApi,
    sourceId: string,
    attributes: Record<string, unknown>,
    options: UpsertSourceAccountOptions = {}
): Promise<string | undefined> {
    const nativeId = String(attributes.id)
    console.log(`[persist] upsert sourceId=${sourceId} identity=${nativeId}`)
    const existing = await findAccountOnSource(accounts, sourceId, nativeId)

    if (existing) {
        console.log(`[persist] upsert identity=${nativeId} action=put iscAccountId=${existing.id}`)
        const putResponse = await accounts.putAccountV1({
            id: existing.id,
            accountAttributes: { attributes: attributes as { sourceId: string; [key: string]: unknown } },
        })
        const putTaskId = putResponse.data?.id
        let completedTask: AccountProvisioningTaskStatus | undefined
        if (putTaskId) {
            console.log(`[persist] putAccount taskId=${putTaskId}`)
            if (options.waitForAccountTask) {
                completedTask = await options.waitForAccountTask(putTaskId)
            }
        }
        return (await resolveAccountAfterProvisioning(accounts, sourceId, nativeId, completedTask)) ?? existing.id
    }

    console.log(`[persist] upsert identity=${nativeId} action=create`)
    const createResponse = await accounts.createAccountV1({
        accountAttributesCreate: {
            attributes: attributes as { sourceId: string; [key: string]: unknown },
        },
    })
    const taskId = createResponse.data?.id
    let completedTask: AccountProvisioningTaskStatus | undefined
    if (taskId) {
        console.log(`[persist] createAccount taskId=${taskId}`)
        if (options.waitForAccountTask) {
            completedTask = await options.waitForAccountTask(taskId)
        }
    }

    return resolveAccountAfterProvisioning(accounts, sourceId, nativeId, completedTask)
}

/**
 * Persists operation output to the result source via account upsert (create or put by native identity).
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
        const iscAccountId = await deps.upsertAccount(built)

        if (options?.verify !== false) {
            await verifyAccountWrite(deps, id, built, iscAccountId)
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
