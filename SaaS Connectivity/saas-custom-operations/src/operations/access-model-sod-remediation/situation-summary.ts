import { buildAccessModelSodContextPanelHtml } from '../../lib/sod-form-html'
import { AccessModelSodAccessItemType } from './form-service'

export interface BuildSituationSummaryHtmlParams {
    uiOrigin?: string
    accessItemId: string
    accessItemType: AccessModelSodAccessItemType
    accessItemName: string
    policyId: string
    policyName: string
}

/** Assembles launch-time situationSummaryHtml for access-model-sod-remediation forms. */
export function buildSituationSummaryHtml(params: BuildSituationSummaryHtmlParams): string {
    return buildAccessModelSodContextPanelHtml(params)
}
