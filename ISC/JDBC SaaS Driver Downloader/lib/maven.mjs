export const MAVEN_CENTRAL = 'https://repo1.maven.org/maven2'

const artifactPath = (groupId, artifactId) => `${groupId.replace(/\./g, '/')}/${artifactId}`

export const metadataUrl = (groupId, artifactId) =>
    `${MAVEN_CENTRAL}/${artifactPath(groupId, artifactId)}/maven-metadata.xml`

export const jarUrl = (groupId, artifactId, version) =>
    `${MAVEN_CENTRAL}/${artifactPath(groupId, artifactId)}/${version}/${artifactId}-${version}.jar`

export const isStable = (version) => !/(alpha|beta|rc|snapshot|preview|m\d+)/i.test(version)

const parseTag = (xml, tag) => xml.match(new RegExp(`<${tag}>([^<]+)</${tag}>`))?.[1]?.trim()

const parseTags = (xml, tag) =>
    [...xml.matchAll(new RegExp(`<${tag}>([^<]+)</${tag}>`, 'g'))].map((m) => m[1].trim())

export const listStableVersions = (metadataXml) => parseTags(metadataXml, 'version').filter(isStable)

export const latestStable = (metadataXml) => {
    const release = parseTag(metadataXml, 'release')
    if (release && isStable(release)) return release

    const versions = listStableVersions(metadataXml)
    if (!versions.length) throw new Error('No stable versions found in Maven metadata.')
    return versions[versions.length - 1]
}

export const fetchText = async (url) => {
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Request failed (${res.status}) for ${url}`)
    return res.text()
}

export const fetchBytes = async (url) => {
    const res = await fetch(url)
    if (!res.ok) throw new Error(`Request failed (${res.status}) for ${url}`)
    return new Uint8Array(await res.arrayBuffer())
}
