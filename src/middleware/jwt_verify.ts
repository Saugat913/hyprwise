// Cryptographic JWT & Security Utilities for Cloudflare Workers (WebCrypto API)
// Verifies Firebase Auth ID tokens (RS256 JWKS), Firebase App Check tokens (RS256 JWKS),
// and server-signed HMAC-SHA256 session tokens.

interface JwksCacheEntry {
  keys: Record<string, JsonWebKey>;
  expiresAt: number;
}

const jwksCache = new Map<string, JwksCacheEntry>();

const FIREBASE_AUTH_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const FIREBASE_APPCHECK_JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';

export function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  const maxLen = Math.max(ab.length, bb.length);
  let diff = ab.length ^ bb.length;
  for (let i = 0; i < maxLen; i++) {
    diff |= (ab[i] ?? 0) ^ (bb[i] ?? 0);
  }
  return diff === 0;
}

function base64UrlToUint8Array(base64Url: string): Uint8Array<ArrayBuffer> {
  let base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4 !== 0) base64 += '=';
  const binary = atob(base64);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function uint8ArrayToBase64Url(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function decodeJsonPart<T = any>(base64Url: string): T | null {
  try {
    const bytes = base64UrlToUint8Array(base64Url);
    const json = new TextDecoder().decode(bytes);
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

async function fetchJwks(url: string): Promise<Record<string, JsonWebKey>> {
  const now = Date.now();
  const cached = jwksCache.get(url);
  if (cached && cached.expiresAt > now) {
    return cached.keys;
  }

  const res = await fetch(url, { cf: { cacheTtl: 3600 } } as any);
  if (!res.ok) {
    throw new Error(`Failed to fetch JWKS (${res.status})`);
  }

  const cacheControl = res.headers.get('cache-control') || '';
  const maxAgeMatch = cacheControl.match(/max-age=(\d+)/);
  const ttlMs = maxAgeMatch ? Math.min(Number(maxAgeMatch[1]) * 1000, 6 * 3600 * 1000) : 3600 * 1000;

  const data = (await res.json()) as { keys?: Array<JsonWebKey & { kid?: string }> };
  const keys: Record<string, JsonWebKey> = {};
  for (const k of data.keys || []) {
    if (k.kid) keys[k.kid] = k;
  }

  jwksCache.set(url, { keys, expiresAt: now + ttlMs });
  return keys;
}

async function verifyRs256Jwt(token: string, jwksUrl: string): Promise<any | null> {
  const parts = token.split('.');
  if (parts.length !== 3) return null;

  const [headerB64, payloadB64, signatureB64] = parts;
  const header = decodeJsonPart<{ alg?: string; kid?: string }>(headerB64);
  const payload = decodeJsonPart<any>(payloadB64);
  if (!header || !payload) return null;
  if (header.alg !== 'RS256' || !header.kid) return null;

  const keys = await fetchJwks(jwksUrl);
  let jwk = keys[header.kid];
  if (!jwk) {
    // Key rotation: invalidate cache once and retry
    jwksCache.delete(jwksUrl);
    const refreshed = await fetchJwks(jwksUrl);
    jwk = refreshed[header.kid];
    if (!jwk) return null;
  }

  const cryptoKey = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify']
  );

  const signingInput = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const signature = base64UrlToUint8Array(signatureB64);

  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    signature,
    signingInput
  );

  return valid ? payload : null;
}

export interface VerifiedFirebaseClaims {
  uid: string;
  email?: string;
  name?: string;
  picture?: string;
  provider?: string;
}

export async function verifyFirebaseIdToken(
  token: string,
  projectId: string
): Promise<VerifiedFirebaseClaims | null> {
  try {
    const payload = await verifyRs256Jwt(token, FIREBASE_AUTH_JWKS_URL);
    if (!payload) return null;

    const nowSec = Math.floor(Date.now() / 1000);
    const expectedIss = `https://securetoken.google.com/${projectId}`;

    if (payload.iss !== expectedIss) return null;
    if (payload.aud !== projectId) return null;
    if (typeof payload.exp !== 'number' || payload.exp <= nowSec) return null;
    if (typeof payload.iat !== 'number' || payload.iat > nowSec + 300) return null;
    const uid = typeof payload.sub === 'string' && payload.sub.length > 0 ? payload.sub : null;
    if (!uid) return null;

    const signInProvider = String(payload.firebase?.sign_in_provider || '').toLowerCase();
    // Strictly reject Firebase anonymous/guest tokens — only Google & Apple accounts are allowed
    if (signInProvider === 'anonymous') {
      return null;
    }
    const normalizedProvider =
      signInProvider === 'apple.com'
        ? 'apple'
        : signInProvider === 'google.com'
        ? 'google'
        : signInProvider || undefined;

    return {
      uid,
      email: typeof payload.email === 'string' ? payload.email.toLowerCase() : undefined,
      name: typeof payload.name === 'string' ? payload.name : undefined,
      picture: typeof payload.picture === 'string' ? payload.picture : undefined,
      provider: normalizedProvider,
    };
  } catch {
    return null;
  }
}

export async function verifyAppCheckToken(
  token: string,
  projectNumber?: string,
  projectId?: string
): Promise<{ appId?: string; sub?: string } | null> {
  try {
    const payload = await verifyRs256Jwt(token, FIREBASE_APPCHECK_JWKS_URL);
    if (!payload) return null;

    const nowSec = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== 'number' || payload.exp <= nowSec) return null;
    if (typeof payload.iat === 'number' && payload.iat > nowSec + 300) return null;

    if (projectNumber) {
      const expectedIss = `https://firebaseappcheck.googleapis.com/${projectNumber}`;
      if (payload.iss !== expectedIss) return null;
      const audList: string[] = Array.isArray(payload.aud) ? payload.aud : [];
      const expectedAudNumber = `projects/${projectNumber}`;
      const expectedAudId = projectId ? `projects/${projectId}` : '';
      if (!audList.includes(expectedAudNumber) && (!expectedAudId || !audList.includes(expectedAudId))) {
        return null;
      }
    }

    return {
      appId: typeof payload.sub === 'string' ? payload.sub : payload.app_id,
      sub: typeof payload.sub === 'string' ? payload.sub : undefined,
    };
  } catch {
    return null;
  }
}

async function importHmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

export async function signSessionToken(
  payload: { uid: string; email: string },
  secret: string,
  ttlSeconds = 60 * 60 * 24 * 7
): Promise<string> {
  const nowSec = Math.floor(Date.now() / 1000);
  const headerB64 = uint8ArrayToBase64Url(
    new TextEncoder().encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  );
  const payloadB64 = uint8ArrayToBase64Url(
    new TextEncoder().encode(
      JSON.stringify({
        sub: payload.uid,
        email: payload.email.toLowerCase(),
        iss: 'hyprwise-server',
        iat: nowSec,
        exp: nowSec + ttlSeconds,
      })
    )
  );
  const key = await importHmacKey(secret);
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${headerB64}.${payloadB64}`)
  );
  const sigB64 = uint8ArrayToBase64Url(new Uint8Array(sig));
  return `${headerB64}.${payloadB64}.${sigB64}`;
}

export async function verifySessionToken(
  token: string,
  secret: string
): Promise<VerifiedFirebaseClaims | null> {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [headerB64, payloadB64, sigB64] = parts;
    const header = decodeJsonPart<{ alg?: string }>(headerB64);
    const payload = decodeJsonPart<any>(payloadB64);
    if (!header || !payload || header.alg !== 'HS256') return null;
    if (payload.iss !== 'hyprwise-server') return null;

    const nowSec = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== 'number' || payload.exp <= nowSec) return null;
    if (typeof payload.sub !== 'string' || !payload.sub) return null;

    const key = await importHmacKey(secret);
    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      base64UrlToUint8Array(sigB64),
      new TextEncoder().encode(`${headerB64}.${payloadB64}`)
    );
    if (!valid) return null;

    return {
      uid: payload.sub,
      email: typeof payload.email === 'string' ? payload.email.toLowerCase() : undefined,
    };
  } catch {
    return null;
  }
}

export interface AdminSessionClaims {
  sub: 'admin';
  csrf: string;
  iat: number;
  exp: number;
}

export async function signAdminSessionToken(
  secret: string,
  ttlSeconds = 60 * 60 * 12
): Promise<{ token: string; csrf: string }> {
  const nowSec = Math.floor(Date.now() / 1000);
  const csrfBytes = new Uint8Array(24);
  crypto.getRandomValues(csrfBytes);
  const csrf = uint8ArrayToBase64Url(csrfBytes);

  const headerB64 = uint8ArrayToBase64Url(
    new TextEncoder().encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  );
  const payloadB64 = uint8ArrayToBase64Url(
    new TextEncoder().encode(
      JSON.stringify({
        sub: 'admin',
        scope: 'admin_console',
        csrf,
        iss: 'hyprwise-admin',
        iat: nowSec,
        exp: nowSec + ttlSeconds,
      })
    )
  );
  const key = await importHmacKey(secret);
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${headerB64}.${payloadB64}`)
  );
  const sigB64 = uint8ArrayToBase64Url(new Uint8Array(sig));
  return { token: `${headerB64}.${payloadB64}.${sigB64}`, csrf };
}

export async function verifyAdminSessionToken(
  token: string,
  secret: string
): Promise<AdminSessionClaims | null> {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [headerB64, payloadB64, sigB64] = parts;
    const header = decodeJsonPart<{ alg?: string }>(headerB64);
    const payload = decodeJsonPart<any>(payloadB64);
    if (!header || !payload || header.alg !== 'HS256') return null;
    if (payload.iss !== 'hyprwise-admin' || payload.sub !== 'admin') return null;
    if (typeof payload.csrf !== 'string' || payload.csrf.length < 16) return null;

    const nowSec = Math.floor(Date.now() / 1000);
    if (typeof payload.exp !== 'number' || payload.exp <= nowSec) return null;

    const key = await importHmacKey(secret);
    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      base64UrlToUint8Array(sigB64),
      new TextEncoder().encode(`${headerB64}.${payloadB64}`)
    );
    if (!valid) return null;

    return {
      sub: 'admin',
      csrf: payload.csrf,
      iat: Number(payload.iat) || nowSec,
      exp: Number(payload.exp),
    };
  } catch {
    return null;
  }
}
