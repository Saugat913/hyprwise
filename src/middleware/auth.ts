// Authentication and User Resolution Middleware / Helpers

import { type Context } from 'hono';
import { type Bindings, type UserRecord, type QuotaSnapshot } from '../types';

export function parseJwtPayload(token: string): any {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
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
  const now = new Date();
  const activePro = !!(user.isPro && (!user.proExpiresAt || new Date(user.proExpiresAt) > now));

  let used = user.dailyAiQueriesCount;
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

export async function resolveUser(c: Context<{ Bindings: Bindings }>, createIfMissing = false): Promise<UserRecord | null> {
  const authHeader = c.req.header('Authorization');
  let token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
  const headerUserId = c.req.header('X-User-Id');
  const headerEmail = c.req.header('X-User-Email');

  let lookupId = headerUserId;
  let lookupEmail = headerEmail;

  if (token) {
    const claims = parseJwtPayload(token);
    if (claims) {
      lookupId = claims.sub || claims.user_id || lookupId;
      lookupEmail = claims.email || lookupEmail;
    }
  }

  if (lookupId) {
    const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(lookupId).first<UserRecord>();
    if (user) return user;
  }

  if (lookupEmail) {
    const user = await c.env.DB.prepare('SELECT * FROM users WHERE email = ?').bind(lookupEmail.toLowerCase()).first<UserRecord>();
    if (user) return user;
  }

  if (createIfMissing && (lookupId || lookupEmail)) {
    const finalId = lookupId || deterministicUserIdFromEmail(lookupEmail || 'user@hyprwise.local');
    const finalEmail = (lookupEmail || `${finalId}@hyprwise.local`).toLowerCase();
    const finalName = finalEmail.split('@')[0];
    const nowIso = new Date().toISOString();
    const todayStr = nowIso.slice(0, 10);

    await c.env.DB.prepare(
      `INSERT INTO users (id, email, displayName, provider, isPro, dailyAiQueriesCount, lastAiQueryDate, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, 0, 0, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET updatedAt = ?`
    ).bind(finalId, finalEmail, finalName, 'auto', todayStr, nowIso, nowIso, nowIso).run();

    return await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(finalId).first<UserRecord>();
  }

  return null;
}
