import { REVOCABILITY_EMOJI } from './tokens'

/** Renders a footer block decoding revocability, keep, and privileged icon suffix meanings. */
export function renderEmojiLegend(): string {
    return `<p style='font-size:90%; color:#546e7a; margin-top:12px;'><strong>Legend:</strong> ${REVOCABILITY_EMOJI.privileged} privileged · ${REVOCABILITY_EMOJI.keepRecommended} recommended to keep · ${REVOCABILITY_EMOJI.revocable} revocable · ${REVOCABILITY_EMOJI.notRevocable} not directly revocable</p>`
}
