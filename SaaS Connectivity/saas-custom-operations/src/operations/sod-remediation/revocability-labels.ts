import { REVOCABILITY_EMOJI } from '../../lib/sod-form-html'

export { REVOCABILITY_EMOJI }

/** Renders a side correction recommendation paragraph when present. */
export function renderSideCorrectionHtml(
    sideLabel: string | null,
    escapeHtml: (text: string) => string
): string {
    if (!sideLabel) {
        return ''
    }

    return `<p><em>${REVOCABILITY_EMOJI.keepRecommended} Recommended to correct ${escapeHtml(sideLabel)} based on keep recommendations on the other side.</em></p>`
}
