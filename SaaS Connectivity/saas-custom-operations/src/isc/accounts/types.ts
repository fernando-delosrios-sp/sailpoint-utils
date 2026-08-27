export interface SourceAccountMatch {
    id: string
    attributes: Record<string, unknown>
}

export interface ListAccountsParams {
    filters?: string
    limit?: number
    offset?: number
    detailLevel?: string
}
