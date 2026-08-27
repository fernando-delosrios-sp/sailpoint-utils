import { type IscClientConfig, iscGet } from '../http'

export interface CompensatingControlV1 {
    id: string
    name: string
    description?: string
}

/** Lists tenant compensating controls. */
export async function listControlsV1(config: IscClientConfig): Promise<CompensatingControlV1[]> {
    const result = await iscGet<CompensatingControlV1[] | { items?: CompensatingControlV1[] }>(
        config,
        '/controls/v1',
        { experimental: true }
    )
    return Array.isArray(result) ? result : (result.items ?? [])
}
