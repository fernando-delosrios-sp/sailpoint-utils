export const OUTCOME_PANEL = {
    keep: {
        background: '#e8f5e9',
        accent: '#2e7d32',
    },
    remove: {
        background: '#ffebee',
        accent: '#c62828',
    },
} as const

export const TYPE_TAG = {
    ROLE: { label: 'role', color: '#1d4ed8', background: '#dbeafe' },
    ACCESS_PROFILE: { label: 'access profile', color: '#7c3aed', background: '#ede9fe' },
    ENTITLEMENT: { label: 'entitlement', color: '#0d9488', background: '#ccfbf1' },
} as const

export const REVOCABILITY_EMOJI = {
    revocable: '✅',
    notRevocable: '🚫',
    keepRecommended: '⭐',
    privileged: '🔐',
    warning: '⚠️',
    info: 'ℹ️',
} as const
