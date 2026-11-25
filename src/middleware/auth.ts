// Authentication and User Resolution Middleware / Helpers
// Verifies Firebase RS256 ID tokens and HMAC-SHA256 session tokens before resolving users.

import { type Context } from 'hono';
import { type Bindings, type UserRecord, type QuotaSnapshot } from '../types';
import {
  verifyFirebaseIdToken,
  verifySessionToken,
  type VerifiedFirebaseClaims,
} from './jwt_verify';

export function getSessionSecret(env: Bindings): string {
  return (
    env.SESSION_SECRET ||
    env.ADMIN_AUTH_TOKEN ||
    env.REVENUECAT_WEBHOOK_AUTH ||
    'hyprwise-ephemeral-dev-secret-rotate-in-prod'
  );
}

export function deterministicUserIdFromEmail(email: string, prefix = 'usr_g_'): string {
  const norm = email.trim().toLowerCase();
  let h1 = 0x811c9dc5;
  let h2 = 0x01000193;
  for (let i = 0; i < norm.length; i++) {
    const code = norm.charCodeAt(i);
    h1 ^= code;
    h1 = Math.imul(h1, 0x01000193) >>> 0;
    h2 ^= (code * 31) & 0xff;
    h2 = Math.imul(h2, 0x85ebca6b) >>> 0;
  }
  const hex = h1.toString(16).padStart(8, '0') + h2.toString(16).padStart(8, '0');
  return `${prefix}${hex}`;
}

export function computeQuotaSnapshot(user: UserRecord): QuotaSnapshot {
  const todayStr = new Date().toISOString().slice(0, 10);
  const nowMs = Date.now();
  const expiresMs =
    typeof user.proExpiresAt === 'number'
      ? user.proExpiresAt
      : user.proExpiresAt
      ? Date.parse(String(user.proExpiresAt))
      : null;

  const isProFlag = user.isPro === 1 || user.isPro === true;
  const activePro = Boolean(isProFlag && (!expiresMs || Number.isNaN(expiresMs) || expiresMs > nowMs));

  let used = Number(user.dailyAiQueriesCount || 0);
  if (user.lastAiQueryDate !== todayStr) {
    used = 0;
  }

  const left = activePro ? 999999 : Math.max(0, 5 - used);
  const limitReached = !activePro && left <= 0;

  return {
    todayStr,
    activePro,
    dailyAiQueriesUsed: used,
    dailyAiQueriesLeft: left,
    limitReached,
  };
}

export async function verifyBearerIdentity(
  c: Context<{ Bindings: Bindings }>
): Promise<VerifiedFirebaseClaims | null> {
  const authHeader = c.req.header('Authorization');
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7).trim() : null;
  if (!token) return null;

  const projectId = c.env.FIREBASE_PROJECT_ID || 'tilvane';

  // 1. Try Firebase RS256 ID token verification against Google's official JWKS
  const firebaseClaims = await verifyFirebaseIdToken(token, projectId);
  if (firebaseClaims) return firebaseClaims;

  // 2. Try server-signed HMAC-SHA256 session JWT
  const sessionClaims = await verifySessionToken(token, getSessionSecret(c.env));
  if (sessionClaims) return sessionClaims;

  return null;
}

export async function resolveUser(
  c: Context<{ Bindings: Bindings }>,
  createIfMissing = false,
  requireVerifiedToken = false
): Promise<UserRecord | null> {
  const verified = await verifyBearerIdentity(c);

  let lookupId: string | undefined = verified?.uid;
  let lookupEmail: string | undefined = verified?.email;

  if (!verified) {
    if (requireVerifiedToken) {
      return null;
    }
    // Only allow unverified header lookup when explicitly opted in for local dev/testing
    // OR for read-only non-sensitive anonymous AI fallback when no token is supplied.
    if (c.env.ALLOW_INSECURE_DEV_AUTH === 'true') {
      lookupId = c.req.header('X-User-Id') || undefined;
      lookupEmail = c.req.header('X-User-Email')?.toLowerCase() || undefined;
    } else {
      return null;
    }
  }

  if (lookupId) {
    const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
      .bind(lookupId)
      .first<UserRecord>();
    if (user) return user;
  }

  if (lookupEmail) {
    const user = await c.env.DB.prepare('SELECT * FROM users WHERE LOWER(email) = ?')
      .bind(lookupEmail.toLowerCase())
      .first<UserRecord>();
    if (user) return user;
  }

  if (createIfMissing && (lookupId || lookupEmail)) {
    const finalEmail = (lookupEmail || `${lookupId}@hyprwise.local`).toLowerCase();
    const finalId = lookupId || deterministicUserIdFromEmail(finalEmail);
    const finalName = verified?.name || finalEmail.split('@')[0];
    const nowMs = Date.now();
    const todayStr = new Date(nowMs).toISOString().slice(0, 10);

    await c.env.DB.prepare(
      `INSERT OR IGNORE INTO users (id, email, displayName, photoUrl, provider, isPro, dailyAiQueriesCount, lastAiQueryDate, createdAt)
       VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)`
    )
      .bind(
        finalId,
        finalEmail,
        finalName,
        verified?.picture || null,
        verified?.provider || 'firebase',
        todayStr,
        nowMs
      )
      .run();

    return await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
      .bind(finalId)
      .first<UserRecord>();
  }

  return null;
}
