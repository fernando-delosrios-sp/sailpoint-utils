import { OUTCOME_PANEL } from './tokens'

export type OutcomeKind = 'keep' | 'remove'

const LIST_PANEL_STYLE =
    'margin:0; padding:8px 12px 8px 20px; border-radius:4px; list-style-position:outside; border-left:4px solid'

/** Wraps list HTML in a neutral shell matching outcome panel dimensions (transparent overlay base). */
export function wrapPlainPanel(content: string): string {
    return `<ul style='${LIST_PANEL_STYLE} transparent; background-color:transparent;'>${content}</ul>`
}

/** Wraps list HTML in a colored outcome panel with a left accent border. */
export function wrapOutcomePanel(content: string, outcome: OutcomeKind): string {
    const colors = OUTCOME_PANEL[outcome]
    return `<ul style='${LIST_PANEL_STYLE} ${colors.accent}; background-color:${colors.background};'>${content}</ul>`
}

export interface SideVariants {
    plain: string
    asKept: string
    asRemoved: string
}

/**
 * Builds plain and outcome-panel variants from list body HTML (inner li markup without outer ul).
 * Plain variant wraps body in a standard ul; kept/removed wrap the same body in outcome panels.
 */
export function buildSideVariants(bodyHtml: string): SideVariants {
    return {
        plain: wrapPlainPanel(bodyHtml),
        asKept: wrapOutcomePanel(bodyHtml, 'keep'),
        asRemoved: wrapOutcomePanel(bodyHtml, 'remove'),
    }
}

/** Builds plain and outcome-panel variants from block HTML (e.g. empty-state paragraph). */
export function buildBlockSideVariants(contentHtml: string): SideVariants {
    return {
        plain: wrapPlainPanel(contentHtml),
        asKept: wrapOutcomePanel(contentHtml, 'keep'),
        asRemoved: wrapOutcomePanel(contentHtml, 'remove'),
    }
}
