import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { ROOT, loadConfig } from './common.mjs';
import { listKnownGoodTags } from './tags.mjs';
import { recentEntries } from './ledger.mjs';

function fmtTs(ts) {
  if (!ts) return '—';
  return String(ts).replace('T', ' ').replace(/\.\d{3}Z$/, ' UTC').replace(/Z$/, ' UTC');
}

function changeRow(entry) {
  const e = entry.entry;
  if (e.kind === 'change') {
    const decision = (e.decisions ?? []).map((d) => d.decision).join(', ') || '—';
    const tag = e.tag ? `\`${e.tag}\`` : '—';
    return `| change | [#${e.pr}](${e.url ?? '#'}) | @${e.author ?? '—'} | ${decision} | ${tag} | ${fmtTs(e.timestamp)} |`;
  }
  if (e.kind === 'restore') {
    const decision = e.decision?.decision ?? '—';
    return `| restore | \`${e.sourceTag}\` | @${e.requester ?? '—'} | ${decision} | — | ${fmtTs(e.timestamp)} |`;
  }
  if (e.kind === 'init') {
    const counts = e.counts
      ? `${e.counts.entitlements ?? 0} entitlements, ${e.counts.accessProfiles ?? 0} access profiles, ${e.counts.roles ?? 0} roles`
      : 'baseline';
    const tag = e.tag ? `\`${e.tag}\`` : '—';
    return `| init | ${counts} | @${e.requester ?? '—'} | fresh backup | ${tag} | ${fmtTs(e.timestamp)} |`;
  }
  if (e.kind === 'drift') {
    const n = (e.added?.length ?? 0) + (e.changed?.length ?? 0) + (e.deleted?.length ?? 0);
    const issue = e.issueUrl ? `[issue](${e.issueUrl})` : '—';
    // Entries written before drift went through governance approval have no
    // `decision` and were auto-committed; keep showing that for history.
    const decision = e.restored ? `${e.decision ?? 'rejected'}, ISC restored` : (e.decision ?? 'committed');
    const who = (e.modifiers ?? [])
      .map((name) => String(name).replace(/\|/g, '\\|').replace(/\s+/g, ' ').trim())
      .filter(Boolean)
      .join(', ') || 'unknown';
    return `| drift | ${n} file(s) | ${who} | ${decision} | ${issue} | ${fmtTs(e.timestamp)} |`;
  }
  return `| ${e.kind} | — | — | — | — | ${fmtTs(e.timestamp)} |`;
}

/**
 * Generate README.md from config + ledger + known-good tags.
 */
export function generateReadme({
  config = loadConfig(),
  entries = recentEntries(30),
  tags = listKnownGoodTags({ limit: 15 }),
  outPath = join(ROOT, 'README.md'),
} = {}) {
  const tenant = config.tenant ?? {};
  const sources = (config.entitlementSources ?? [])
    .map((s) => `- ${s.name} (\`${s.id}\`)`)
    .join('\n') || '_None configured — edit `config.yaml` via PR._';

  const history = entries.length
    ? entries.map(changeRow).join('\n')
    : '| — | — | — | — | — | — |';

  const tagList = tags.length
    ? tags.map((t) => `- [\`${t}\`](../../releases/tag/${encodeURIComponent(t)})`).join('\n')
    : '_No known-good tags yet._';

  const md = `# Access Model Change Management

GitHub-centric governance of ISC **entitlements** (metadata), **access profiles** and **roles** for tenant **${tenant.name ?? 'unknown'}**.

| | |
|---|---|
| API | \`${tenant.apiUrl ?? ''}\` |
| UI | ${tenant.uiUrl ? `[${tenant.uiUrl}](${tenant.uiUrl})` : '—'} |
| Governance group | ${config.approval?.governanceGroupName ?? '—'} |
| Backup schedule (UTC) | \`${config.backup?.schedule ?? '0 2 * * *'}\` |

## How changes ship

1. Open a PR that edits files under \`access/\`.
2. CI validates schemas and name references.
3. An ISC workflow asks the **governance group**, then each changed item's **owner** when that is enabled.
4. On approval, the PR auto-merges and GitHub Actions push the change to ISC.
5. A successful apply creates an immutable \`known-good/…\` tag.

Drift (ISC edited outside a PR) asks only the governance group. Approving copies ISC into git. Rejecting puts ISC back to match git. A timeout changes nothing, and the next backup asks again. The Who column names the ISC audit actor associated with that drift since git and ISC last matched.

Direct pushes to \`main\` are blocked when a ruleset is in place. Only the automation GitHub App is meant to write backups, id write-back, the ledger, and this README.

## Reset

**Actions → Init** wipes issues, tags, releases, other branches, previous workflow runs, and git history, then commits a fresh ISC backup as the only commit on \`main\` and tags it \`known-good/…\`. It cancels any other in-progress workflow runs first. ISC is not changed. Type \`RESET\` to confirm. This cannot be undone. Deleting previous workflow runs needs the GitHub App repository permission **Actions: Read and write**.

## Entitlement sources (allowlist)

${sources}

Entitlements are identified by their ISC id, so a source may contain several
entitlements sharing a name and even a native value — one Entra group surfaces
as \`group\`, \`azureADActiveGroup\` and \`azureADEligibleGroup\`. Where that
happens the file names carry the smallest suffix that tells them apart; unique
names use the plain name slug.

## Recent history

| Kind | Ref | Who | Decision | Tag / issue | When |
|------|-----|-----|----------|-------------|------|
${history}

## Known-good tags

Use **Actions → Restore** with one of these tags. Restore approval goes only to the governance group.

${tagList}

## Local commands

\`\`\`bash
npm install
npm run validate
npm run plan
npm run backup          # requires ISC_* env
npm run restore -- --tag known-good/… --dry-run
\`\`\`

---
_Generated by \`npm run readme\`. Do not edit by hand._
`;

  writeFileSync(outPath, md, 'utf8');
  return { outPath, entryCount: entries.length, tagCount: tags.length };
}
