import { mkdir, readdir, rm, writeFile } from 'node:fs/promises'
import { execFile } from 'node:child_process'
import path from 'node:path'
import { promisify } from 'node:util'

import { fetchBytes } from './maven.mjs'
import { DIST_DIR, DRIVERS_DIR } from './drivers.mjs'

const execFileAsync = promisify(execFile)

export const downloadDriver = async (driver, outputDir = DRIVERS_DIR) => {
    await mkdir(outputDir, { recursive: true })

    const bytes = await fetchBytes(driver.jarUrl)
    if (!bytes.byteLength) throw new Error(`Empty download for ${driver.engine}`)

    const jarPath = path.join(outputDir, driver.jarFileName)
    await writeFile(jarPath, bytes)
    return { jarPath, bytes: bytes.byteLength }
}

export const zipJar = async (jarPath, distDir = DIST_DIR) => {
    await mkdir(distDir, { recursive: true })

    const jarFile = path.basename(jarPath)
    const zipName = jarFile.replace(/\.jar$/i, '.zip')
    const zipPath = path.join(distDir, zipName)
    await execFileAsync('zip', ['-j', '-q', zipPath, jarFile], { cwd: path.dirname(jarPath) })
    return zipPath
}

export const downloadAndZip = async (driver) => {
    const { jarPath, bytes } = await downloadDriver(driver)
    const zipPath = await zipJar(jarPath)
    return { jarPath, zipPath, bytes }
}

export const downloadAndZipAll = async (drivers) => {
    await rm(DRIVERS_DIR, { recursive: true, force: true })
    await rm(DIST_DIR, { recursive: true, force: true })
    await mkdir(DRIVERS_DIR, { recursive: true })
    await mkdir(DIST_DIR, { recursive: true })

    const results = []
    for (const driver of drivers) {
        const result = await downloadAndZip(driver)
        results.push({ driver, ...result })
        console.log(`  ${driver.engine}@${driver.version}  (${result.bytes.toLocaleString()} bytes)`)
    }

    return results
}

export const writeManifest = async (drivers, configPath, mode) => {
    const manifestPath = path.join(DRIVERS_DIR, 'manifest.json')
    const manifest = {
        generatedAt: new Date().toISOString(),
        mode,
        configPath: path.resolve(configPath),
        outputDirectory: DRIVERS_DIR,
        distDirectory: DIST_DIR,
        drivers: drivers.map((d) => ({
            engine: d.engine,
            name: d.name,
            class: d.class,
            version: d.version,
            groupId: d.groupId,
            artifactId: d.artifactId,
            fileName: d.jarFileName,
            sourceUrl: d.jarUrl,
            notes: d.notes,
        })),
    }
    await writeFile(manifestPath, `${JSON.stringify(manifest, null, 4)}\n`)
    return manifestPath
}

export const listExistingJars = async (outputDir = DRIVERS_DIR) => {
    try {
        return (await readdir(outputDir)).filter((f) => f.endsWith('.jar'))
    } catch {
        return []
    }
}
