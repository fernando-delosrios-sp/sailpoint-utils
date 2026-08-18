import { TYPE_TAG } from './tokens'

export type AccessKind = keyof typeof TYPE_TAG

/** Renders an inline pill-style span identifying an access object kind. */
export function renderTypeTag(kind: AccessKind): string {
    const style = TYPE_TAG[kind]
    return `<span style='color:${style.color}; font-size:90%; background-color:${style.background}; padding:2px 6px; border-radius:4px;'>${style.label}</span>`
}
