import type { SodViolationPrediction } from './types'

export const OFFLINE_VIOLATION_PREDICTION: SodViolationPrediction = {
    violationContexts: [
        {
            policy: {
                id: 'offline-policy-001',
                name: 'Finance Control',
            },
        },
        {
            policy: {
                id: 'offline-policy-002',
                name: 'Procurement Control',
            },
        },
    ],
}

/** Returns deterministic offline violation prediction for local operation tests. */
export function predictSodViolationsForIdentityOffline(_identityId: string): SodViolationPrediction {
    return OFFLINE_VIOLATION_PREDICTION
}

export const OFFLINE_ROLE_ENTITLEMENT_IDS = ['offline-ent-001', 'offline-ent-002']
