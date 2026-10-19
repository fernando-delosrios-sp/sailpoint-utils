/**
 * Mint a short-lived GitHub App installation token from the App's private key.
 *
 * The installer runs locally, not inside Actions, so it has no
 * `actions/create-github-app-token@v1` to lean on. This hand-rolls the same
 * JWT-then-installation-token exchange that action does, using only
 * `node:crypto` — no extra dependency for one RS256 signature.
 *
 * Why this exists at all: a repo with the `amcm-main-protection` ruleset
 * active only lets the GitHub App push straight to `main` (the ruleset's one
 * bypass actor); every other credential, including the operator's own `gh`
 * login, is a normal PR-only contributor there. The installer's original
 * refresh push used the operator's `gh` token and would be rejected by that
 * same ruleset on any repo update run after the first install. Minting the
 * App's own token lets `update` land the same way the repo's own workflows
 * already do.
 */
import { createSign } from 'node:crypto';

function base64url(input) {
  const buf = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function signAppJwt({ appId, privateKeyPem, now = Math.floor(Date.now() / 1000) }) {
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64url(JSON.stringify({
    // 60s in the past absorbs clock drift between this machine and GitHub,
    // the same margin GitHub's own docs recommend for App JWTs.
    iat: now - 60,
    exp: now + 600,
    iss: String(appId).trim(),
  }));
  const signingInput = `${header}.${payload}`;
  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  signer.end();
  const signature = base64url(signer.sign(privateKeyPem));
  return `${signingInput}.${signature}`;
}

async function ghApi(path, { method = 'GET', token, body, fetchImpl = fetch } = {}) {
  const res = await fetchImpl(`https://api.github.com${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const err = new Error(`${method} ${path} → ${res.status}: ${json?.message ?? text}`);
    err.status = res.status;
    throw err;
  }
  return json;
}

/**
 * Exchange the App's private key for a token scoped to one repo's
 * installation. Valid for one hour; the installer's whole update run
 * finishes well inside that.
 */
export async function mintInstallationToken({ appId, privateKeyPem, owner, repo, fetchImpl = fetch }) {
  if (!appId || !privateKeyPem) {
    throw new Error('mintInstallationToken requires appId and privateKeyPem');
  }
  const jwt = signAppJwt({ appId, privateKeyPem });
  const installation = await ghApi(`/repos/${owner}/${repo}/installation`, { token: jwt, fetchImpl });
  const grant = await ghApi(`/app/installations/${installation.id}/access_tokens`, {
    method: 'POST',
    token: jwt,
    fetchImpl,
  });
  return { token: grant.token, expiresAt: grant.expires_at, installationId: installation.id };
}

export { signAppJwt };
