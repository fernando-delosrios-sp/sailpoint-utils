import { ConnectorError } from '@sailpoint/connector-sdk'
import { type IscClientConfig, iscGet } from '../http'

export interface ViolationAccessItem {
    id: string
    name: string
    type?: string
}

export interface ViolationSide {
    name?: string
    accessItems?: ViolationAccessItem[]
    entitlements?: ViolationAccessItem[]
}

export interface ViolationV1 {
    id: string
    owner: { id: string; name?: string }
    identity: { id: string; name?: string }
    policy?: { id: string; name?: string }
    leftSide?: ViolationSide
    rightSide?: ViolationSide
    groupA?: ViolationSide
    groupB?: ViolationSide
}

interface ViolationReferenceResponse {
    id: string
    name?: string
    type?: string
}

interface ViolationCriteriaItemResponse {
    id?: string
    name?: string
    type?: string
    existing?: boolean
}

interface ViolationCriteriaResponse {
    name?: string
    criteriaList?: ViolationCriteriaItemResponse[]
    conflictingItems?: ViolationCriteriaItemResponse[]
}

/** Raw GET /violations/v1/:id payload (ReferenceResponse + conflictingAccessCriteria). */
export interface ViolationV1Response {
    id: string
    owner?: ViolationReferenceResponse
    identity?: ViolationReferenceResponse
    target?: ViolationReferenceResponse
    policy?: ViolationReferenceResponse
    leftSide?: ViolationSide
    rightSide?: ViolationSide
    groupA?: ViolationSide
    groupB?: ViolationSide
    conflictingAccessCriteria?: {
        leftCriteria?: ViolationCriteriaResponse
        rightCriteria?: ViolationCriteriaResponse
    }
    /** Live GET /violations/v1/:id — object or two-element array [left, right]. */
    conflictingCriteria?:
        | {
              leftCriteria?: ViolationCriteriaResponse
              rightCriteria?: ViolationCriteriaResponse
              leftSide?: ViolationCriteriaResponse
              rightSide?: ViolationCriteriaResponse
          }
        | ViolationCriteriaResponse[]
        | ViolationCriteriaItemResponse[]
}

function mapCriteriaToSide(criteria?: ViolationCriteriaResponse): ViolationSide | undefined {
    if (!criteria) {
        return undefined
    }

    const entitlements = (criteria.criteriaList ?? [])
        .filter((item): item is ViolationCriteriaItemResponse & { id: string } => Boolean(item.id))
        .filter((item) => !item.type || item.type.toUpperCase() === 'ENTITLEMENT')
        .filter((item) => item.existing !== false)
        .map((item) => ({
            id: item.id,
            name: item.name ?? item.id,
            type: item.type,
        }))

    return {
        name: criteria.name,
        entitlements,
    }
}

function toCriteriaResponse(side: unknown): ViolationCriteriaResponse | undefined {
    if (!side || typeof side !== 'object') {
        return undefined
    }

    const candidate = side as Record<string, unknown>
    if (Array.isArray(candidate.conflictingItems)) {
        return {
            name: candidate.name as string | undefined,
            criteriaList: candidate.conflictingItems as ViolationCriteriaItemResponse[],
        }
    }
    if (Array.isArray(candidate.criteriaList)) {
        return {
            name: candidate.name as string | undefined,
            criteriaList: candidate.criteriaList as ViolationCriteriaItemResponse[],
        }
    }
    if (Array.isArray(candidate.accessItems)) {
        return {
            name: candidate.name as string | undefined,
            criteriaList: candidate.accessItems as ViolationCriteriaItemResponse[],
        }
    }
    if (Array.isArray(candidate.entitlements)) {
        return {
            name: candidate.name as string | undefined,
            criteriaList: candidate.entitlements as ViolationCriteriaItemResponse[],
        }
    }
    if (typeof candidate.id === 'string') {
        return { criteriaList: [candidate as ViolationCriteriaItemResponse] }
    }

    return undefined
}

function resolveConflictingCriteriaSides(raw: ViolationV1Response): {
    leftCriteria?: ViolationCriteriaResponse
    rightCriteria?: ViolationCriteriaResponse
} {
    const accessCriteria = raw.conflictingAccessCriteria
    if (accessCriteria?.leftCriteria || accessCriteria?.rightCriteria) {
        return {
            leftCriteria: accessCriteria.leftCriteria,
            rightCriteria: accessCriteria.rightCriteria,
        }
    }

    const criteria = raw.conflictingCriteria
    if (!criteria) {
        return {}
    }

    if (Array.isArray(criteria)) {
        return {
            leftCriteria: toCriteriaResponse(criteria[0]),
            rightCriteria: toCriteriaResponse(criteria[1]),
        }
    }

    return {
        leftCriteria: criteria.leftCriteria ?? criteria.leftSide,
        rightCriteria: criteria.rightCriteria ?? criteria.rightSide,
    }
}

/** Normalizes violation API responses into the internal ViolationV1 shape. */
export function normalizeViolationV1Response(raw: ViolationV1Response): ViolationV1 {
    const identity = raw.identity ?? raw.target
    if (!identity?.id) {
        throw new ConnectorError('Violation response missing target identity reference')
    }
    if (!raw.owner?.id) {
        throw new ConnectorError('Violation response missing owner reference')
    }

    const { leftCriteria, rightCriteria } = resolveConflictingCriteriaSides(raw)
    const leftSide = raw.leftSide ?? raw.groupA ?? mapCriteriaToSide(leftCriteria)
    const rightSide = raw.rightSide ?? raw.groupB ?? mapCriteriaToSide(rightCriteria)

    return {
        id: raw.id,
        owner: { id: raw.owner.id, name: raw.owner.name },
        identity: { id: identity.id, name: identity.name },
        policy: raw.policy ? { id: raw.policy.id, name: raw.policy.name } : undefined,
        leftSide,
        rightSide,
    }
}

/** Fetches a policy violation by ID. */
export async function getViolationV1(
    config: IscClientConfig,
    violationId: string
): Promise<ViolationV1> {
    const raw = await iscGet<ViolationV1Response>(
        config,
        `/violations/v1/${encodeURIComponent(violationId)}`,
        { experimental: true }
    )
    return normalizeViolationV1Response(raw)
}

/** Resolves left/right violation sides regardless of response field naming. */
export function resolveViolationSides(violation: ViolationV1): { groupA: ViolationSide; groupB: ViolationSide } {
    const groupA = violation.leftSide ?? violation.groupA ?? {}
    const groupB = violation.rightSide ?? violation.groupB ?? {}
    return { groupA, groupB }
}

/** Extracts entitlement access items from a violation side. */
export function extractSideEntitlements(side: ViolationSide): ViolationAccessItem[] {
    if (side.entitlements?.length) {
        return side.entitlements
    }
    return (side.accessItems ?? []).filter(
        (item) => !item.type || item.type.toUpperCase() === 'ENTITLEMENT'
    )
}
