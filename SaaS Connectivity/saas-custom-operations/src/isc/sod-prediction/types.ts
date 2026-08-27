/** Minimal SoD predict response shape used by preventive SoD check helpers. */
export interface SodViolationPrediction {
    violationContexts?: Array<{
        policy?: {
            id?: string
            name?: string
        }
    }>
}
