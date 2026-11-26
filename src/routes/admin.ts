// Production Admin Console Routes (Path-only at /admin, HMAC-SHA256 Session + CSRF + Rate Limit + Audit Log)

import { Hono, type Context } from 'hono';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';
import { type Bindings } from '../types';
import {
  memoryEvents,
  ADMIN_COOKIE_NAME,
  getAdminPassword,
  getAdminAuthToken,
  isUsingDefaultAdminPassword,
} from '../compliance_and_admin';
import {
  safeEqual,
  signAdminSessionToken,
  verifyAdminSessionToken,
  type AdminSessionClaims,
} from '../middleware/jwt_verify';
import {
  computeQuotaSnapshot,
  deterministicUserIdFromEmail,
  getSessionSecret,
} from '../middleware/auth';
import { FirebaseAnalyticsService } from '../services/firebase_analytics';
import {
  renderAdminDashboard,
  renderAdminLoginPage,
  type AdminAuditRow,
  type AdminBackupView,
  type AdminHealthCheck,
  type AdminTab,
  type AdminUserView,
} from './admin_ui';

export const adminRouter = new Hono<{ Bindings: Bindings }>();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DAY_MS = 24 * 60 * 60 * 1000;
const ALLOWED_TABS = new Set<AdminTab>([
  'overview',
  'users',
  'backups',
  'deletions',
  'telemetry',
  'audit',
  'danger',
]);

// Brute-force login rate limiter (per IP: max 5 failed attempts per 15 minutes)
const loginAttempts = new Map<string, number[]>();
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const MAX_LOGIN_FAILURES = 5;

function clientIp(c: Context<{ Bindings: Bindings }>): string {
  return (
    c.req.header('CF-Connecting-IP') ||
    c.req.header('X-Forwarded-For')?.split(',')[0]?.trim() ||
    'unknown'
  );
}

function isLoginLocked(ip: string): boolean {
  const now = Date.now();
  const attempts = (loginAttempts.get(ip) || []).filter((t) => now - t < LOGIN_WINDOW_MS);
  loginAttempts.set(ip, attempts);
  return attempts.length >= MAX_LOGIN_FAILURES;
}

function recordLoginFailure(ip: string): void {
  const now = Date.now();
  const attempts = (loginAttempts.get(ip) || []).filter((t) => now - t < LOGIN_WINDOW_MS);
  attempts.push(now);
  loginAttempts.set(ip, attempts);
  if (loginAttempts.size > 1000) loginAttempts.clear();
}

function clearLoginFailures(ip: string): void {
  loginAttempts.delete(ip);
}

async function resolveAdminSession(
  c: Context<{ Bindings: Bindings }>
): Promise<{ ok: boolean; claims?: AdminSessionClaims; isBearer?: boolean }> {
  const cookie = getCookie(c, ADMIN_COOKIE_NAME);
  if (cookie) {
    const claims = await verifyAdminSessionToken(cookie, getSessionSecret(c.env));
    if (claims) return { ok: true, claims };
  }

  const authHeader = c.req.header('Authorization');
  if (authHeader?.startsWith('Bearer ')) {
    const supplied = authHeader.slice(7).trim();
    const expectedToken = getAdminAuthToken(c.env);
    const expectedPassword = getAdminPassword(c.env);
    if (
      supplied.length > 0 &&
      (safeEqual(supplied, expectedToken) || safeEqual(supplied, expectedPassword))
    ) {
      return { ok: true, isBearer: true };
    }
  }

  return { ok: false };
}

async function requireAdminAndCsrf(
  c: Context<{ Bindings: Bindings }>,
  body: Record<string, string | File>
): Promise<{ ok: true } | { ok: false; response: Response }> {
  const session = await resolveAdminSession(c);
  if (!session.ok) {
    return { ok: false, response: c.redirect('/admin') };
  }
  if (!session.isBearer) {
    const suppliedCsrf = String(body['_csrf'] || '').trim();
    if (!suppliedCsrf || !session.claims || !safeEqual(suppliedCsrf, session.claims.csrf)) {
      return {
        ok: false,
        response: c.redirect(
          '/admin?err=' + encodeURIComponent('Invalid or expired security token. Please retry.')
        ),
      };
    }
  }
  return { ok: true };
}

async function ensureAuditTable(db?: D1Database): Promise<void> {
  if (!db) return;
  try {
    await db
      .prepare(
        `CREATE TABLE IF NOT EXISTS admin_audit_logs (
          id TEXT PRIMARY KEY,
          action TEXT NOT NULL,
          target TEXT,
          details TEXT,
          ipAddress TEXT,
          createdAt INTEGER NOT NULL
        )`
      )
      .run();
  } catch (_) {}
}

async function recordAdminAudit(
  c: Context<{ Bindings: Bindings }>,
  action: string,
  target: string | null,
  details: string | null
): Promise<void> {
  if (!c.env?.DB) return;
  try {
    await ensureAuditTable(c.env.DB);
    const id = `aud_${crypto.randomUUID().replace(/-/g, '').slice(0, 16)}`;
    await c.env.DB.prepare(
      `INSERT INTO admin_audit_logs (id, action, target, details, ipAddress, createdAt)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
      .bind(id, action, target, details, clientIp(c), Date.now())
      .run();
  } catch (_) {}
}

function resolvePlanSubscription(
  plan: string,
  expiresDate?: string
): { isPro: number; proExpiresAt: number | null; label: string } {
  const now = Date.now();
  switch (plan) {
    case 'free':
      return { isPro: 0, proExpiresAt: null, label: 'Free' };
    case 'pro_30d':
      return { isPro: 1, proExpiresAt: now + 30 * DAY_MS, label: 'Pro (30 days)' };
    case 'pro_90d':
      return { isPro: 1, proExpiresAt: now + 90 * DAY_MS, label: 'Pro (90 days)' };
    case 'pro_365d':
      return { isPro: 1, proExpiresAt: now + 365 * DAY_MS, label: 'Pro (365 days)' };
    case 'pro_lifetime':
      return { isPro: 1, proExpiresAt: null, label: 'Pro (Lifetime)' };
    case 'pro_custom': {
      const parsed = expiresDate ? Date.parse(`${expiresDate}T23:59:59Z`) : NaN;
      if (Number.isNaN(parsed)) {
        return { isPro: 1, proExpiresAt: now + 30 * DAY_MS, label: 'Pro (30 days)' };
      }
      return { isPro: 1, proExpiresAt: parsed, label: `Pro (until ${expiresDate})` };
    }
    default:
      return { isPro: 0, proExpiresAt: null, label: 'Free' };
  }
}

function redirectTab(tab: AdminTab, params: { ok?: string; err?: string }): string {
  const qs = new URLSearchParams({ tab });
  if (params.ok) qs.set('ok', params.ok);
  if (params.err) qs.set('err', params.err);
  return `/admin?${qs.toString()}`;
}

// ==========================================
// GET /admin — Login or Production Console
// ==========================================
adminRouter.get('/', async (c) => {
  const session = await resolveAdminSession(c);
  if (!session.ok) {
    return c.html(renderAdminLoginPage());
  }

  const rawTab = (c.req.query('tab') || 'overview') as AdminTab;
  const tab: AdminTab = ALLOWED_TABS.has(rawTab) ? rawTab : 'overview';
  const searchQuery = (c.req.query('q') || '').trim();
  const tierFilter = (c.req.query('tier') || 'all').trim();
  const flashOk = c.req.query('ok') || undefined;
  const flashErr = c.req.query('err') || undefined;

  let rawUsers: any[] = [];
  let backups: AdminBackupView[] = [];
  let deletions: any[] = [];
  let auditLogs: AdminAuditRow[] = [];
  let dbConnected = false;

  const allEvents = [...memoryEvents];
  const todayStr = new Date().toISOString().slice(0, 10);

  if (c.env?.DB) {
    try {
      await ensureAuditTable(c.env.DB);
      dbConnected = true;

      const [uRes, bRes, dRes, tRes, aRes] = await Promise.all([
        c.env.DB.prepare('SELECT * FROM users ORDER BY createdAt DESC LIMIT 500').all(),
        c.env.DB.prepare(
          `SELECT s.userId, u.email, s.version, LENGTH(s.payload) AS sizeBytes, s.lastSyncedAt
           FROM sync_records s
           LEFT JOIN users u ON u.id = s.userId
           ORDER BY s.lastSyncedAt DESC LIMIT 200`
        ).all(),
        c.env.DB.prepare(
          'SELECT * FROM account_deletions ORDER BY requestedAt DESC LIMIT 100'
        ).all(),
        c.env.DB.prepare(
          'SELECT * FROM telemetry_events ORDER BY createdAt DESC LIMIT 200'
        ).all(),
        c.env.DB.prepare(
          'SELECT * FROM admin_audit_logs ORDER BY createdAt DESC LIMIT 100'
        ).all(),
      ]);

      rawUsers = (uRes.results || []) as any[];
      backups = ((bRes.results || []) as any[]).map((b) => ({
        userId: String(b.userId),
        email: b.email ? String(b.email) : null,
        version: Number(b.version || 1),
        sizeBytes: Number(b.sizeBytes || 0),
        lastSyncedAt: Number(b.lastSyncedAt || 0),
      }));
      deletions = (dRes.results || []) as any[];
      auditLogs = ((aRes.results || []) as any[]).map((a) => ({
        id: String(a.id),
        action: String(a.action),
        target: a.target ? String(a.target) : null,
        details: a.details ? String(a.details) : null,
        ipAddress: a.ipAddress ? String(a.ipAddress) : null,
        createdAt: Number(a.createdAt || 0),
      }));

      const seenIds = new Set(allEvents.map((e) => e.id));
      for (const row of (tRes.results || []) as any[]) {
        if (!seenIds.has(row.id)) {
          allEvents.push({
            id: String(row.id),
            userId: row.userId ? String(row.userId) : null,
            eventType: (row.eventType || 'action') as any,
            eventName: String(row.eventName || ''),
            details: row.details ? String(row.details) : null,
            deviceInfo: row.deviceInfo ? String(row.deviceInfo) : null,
            appVersion: row.appVersion ? String(row.appVersion) : null,
            createdAt: Number(row.createdAt || 0),
          });
        }
      }
      allEvents.sort((a, b) => b.createdAt - a.createdAt);
    } catch (_) {}
  }

  const backupByUser = new Map<string, AdminBackupView>();
  for (const b of backups) backupByUser.set(b.userId, b);

  let activeProUsers = 0;
  let expiredProUsers = 0;
  let aiQueriesToday = 0;

  const allUserViews: AdminUserView[] = rawUsers.map((u) => {
    const quota = computeQuotaSnapshot(u);
    const isProFlag = u.isPro === 1 || u.isPro === true;
    const expiredPro = Boolean(isProFlag && !quota.activePro);
    if (quota.activePro) activeProUsers++;
    if (expiredPro) expiredProUsers++;
    if (u.lastAiQueryDate === todayStr) {
      aiQueriesToday += Number(u.dailyAiQueriesCount || 0);
    }
    const b = backupByUser.get(String(u.id));
    return {
      id: String(u.id),
      email: String(u.email || ''),
      displayName: String(u.displayName || ''),
      provider: String(u.provider || 'manual'),
      isPro: isProFlag ? 1 : 0,
      proExpiresAt: u.proExpiresAt ? Number(u.proExpiresAt) : null,
      activePro: quota.activePro,
      expiredPro,
      dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
      createdAt: Number(u.createdAt || 0),
      backupVersion: b ? b.version : null,
      backupBytes: b ? b.sizeBytes : null,
      backupUpdatedAt: b ? b.lastSyncedAt : null,
    };
  });

  // Apply search & tier filters on Users tab
  const filteredUsers = allUserViews.filter((u) => {
    if (tierFilter === 'pro' && !u.activePro) return false;
    if (tierFilter === 'expired' && !u.expiredPro) return false;
    if (tierFilter === 'free' && (u.activePro || u.expiredPro)) return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (
        !u.email.toLowerCase().includes(q) &&
        !u.displayName.toLowerCase().includes(q) &&
        !u.id.toLowerCase().includes(q)
      ) {
        return false;
      }
    }
    return true;
  });

  const totalUsers = allUserViews.length;
  const totalBackupBytes = backups.reduce((sum, b) => sum + b.sizeBytes, 0);
  const totalExceptions = allEvents.filter(
    (e) => e.eventType === 'crash' || e.eventType === 'exception'
  ).length;
  const pendingDeletions = deletions.filter(
    (d) => d.status === 'pending_confirmation' || d.status === 'confirmed'
  ).length;
  const conversionRate =
    totalUsers > 0 ? `${((activeProUsers / totalUsers) * 100).toFixed(1)}%` : '0.0%';

  const usingDefaultPassword = isUsingDefaultAdminPassword(c.env);
  const usingDefaultSecret = !(c.env?.SESSION_SECRET && c.env.SESSION_SECRET.trim());

  const healthChecks: AdminHealthCheck[] = [
    {
      label: 'Cloudflare D1 Database',
      ok: dbConnected,
      critical: true,
      detail: dbConnected ? 'Connected and responding to queries' : 'D1 binding unavailable',
    },
    {
      label: 'Admin Password Secret (ADMIN_PASSWORD)',
      ok: !usingDefaultPassword,
      critical: true,
      detail: usingDefaultPassword
        ? 'Using fallback dev password — run wrangler secret put ADMIN_PASSWORD'
        : 'Custom production secret configured',
    },
    {
      label: 'Session Signing Secret (SESSION_SECRET)',
      ok: !usingDefaultSecret,
      critical: true,
      detail: usingDefaultSecret
        ? 'Not explicitly set — run wrangler secret put SESSION_SECRET'
        : 'HMAC-SHA256 signing key configured',
    },
    {
      label: 'Gemini AI Gateway (GEMINI_API_KEY)',
      ok: Boolean(c.env?.GEMINI_API_KEY?.trim()),
      detail: c.env?.GEMINI_API_KEY?.trim()
        ? 'Live Gemini 2.5 Flash reasoning & OCR enabled'
        : 'Missing — AI falls back to local mode',
    },
    {
      label: 'RevenueCat Webhook Secret (REVENUECAT_WEBHOOK_AUTH)',
      ok: Boolean(c.env?.REVENUECAT_WEBHOOK_AUTH?.trim()),
      detail: c.env?.REVENUECAT_WEBHOOK_AUTH?.trim()
        ? 'Server-to-server subscription webhook armed'
        : 'Not set — webhook rejects requests (503 fail-closed)',
    },
    {
      label: 'Firebase App Check Enforcement (ENFORCE_APP_CHECK)',
      ok: c.env?.ENFORCE_APP_CHECK === 'true',
      detail:
        c.env?.ENFORCE_APP_CHECK === 'true'
          ? 'Strictly enforcing signed RS256 App Check tokens'
          : 'Permissive mode — set ENFORCE_APP_CHECK=true after mobile rollout',
    },
  ];

  const analyticsSummary = await FirebaseAnalyticsService.getAnalyticsSummary({
    propertyId: c.env?.GA4_PROPERTY_ID,
    events: allEvents,
    totalUsers,
  });
  const analyticsHtml = FirebaseAnalyticsService.renderAnalyticsChartsHtml(analyticsSummary);

  return c.html(
    renderAdminDashboard({
      tab,
      csrfToken: session.claims?.csrf || 'bearer',
      flashOk,
      flashErr,
      usingDefaultPassword,
      usingDefaultSecret,
      searchQuery,
      tierFilter,
      metrics: {
        totalUsers,
        activeProUsers,
        expiredProUsers,
        conversionRate,
        totalBackups: backups.length,
        totalBackupBytes,
        totalExceptions,
        totalEvents: allEvents.length,
        aiQueriesToday,
        pendingDeletions,
      },
      users: filteredUsers,
      backups,
      deletions,
      events: allEvents,
      auditLogs,
      healthChecks,
      analyticsHtml,
    })
  );
});

// ==========================================
// POST /admin/login & POST /admin/logout
// ==========================================
adminRouter.post('/login', async (c) => {
  try {
    const ip = clientIp(c);
    if (isLoginLocked(ip)) {
      return c.html(
        renderAdminLoginPage({
          error: 'Too many failed attempts. Login locked for 15 minutes.',
        }),
        429
      );
    }

    const body = await c.req.parseBody();
    const password = String(body['password'] || '').trim();
    const expectedPassword = getAdminPassword(c.env);

    if (password.length > 0 && safeEqual(password, expectedPassword)) {
      clearLoginFailures(ip);
      const { token } = await signAdminSessionToken(getSessionSecret(c.env));
      const isHttps = c.req.url.startsWith('https://');
      setCookie(c, ADMIN_COOKIE_NAME, token, {
        path: '/admin',
        httpOnly: true,
        secure: isHttps,
        sameSite: 'Strict',
        maxAge: 60 * 60 * 12, // 12-hour sliding admin session
      });
      await recordAdminAudit(c, 'login_success', 'admin', 'Console session started');
      return c.redirect('/admin');
    }

    recordLoginFailure(ip);
    await recordAdminAudit(c, 'login_failed', 'admin', 'Invalid password attempt');
    return c.html(renderAdminLoginPage({ error: 'Incorrect password. Access denied.' }), 401);
  } catch (err: any) {
    return c.html(renderAdminLoginPage({ error: err.message || 'Login error' }), 500);
  }
});

adminRouter.post('/logout', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  await recordAdminAudit(c, 'logout', 'admin', 'Console session ended');
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/admin' });
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/' });
  return c.redirect('/admin');
});

// ==========================================
// User & Pro Subscription Management Routes
// ==========================================
adminRouter.post('/users/upsert', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const email = String(body['email'] || '').trim().toLowerCase();
  const rawName = String(body['displayName'] || '').trim().slice(0, 80);
  const provider = String(body['provider'] || 'google').trim().slice(0, 24);
  const plan = String(body['plan'] || 'pro_lifetime').trim();
  const expiresDate = String(body['expiresDate'] || '').trim();

  if (!email || !EMAIL_REGEX.test(email)) {
    return c.redirect(redirectTab('users', { err: 'Please enter a valid email address.' }));
  }
  if (!c.env?.DB) {
    return c.redirect(redirectTab('users', { err: 'Database unavailable.' }));
  }

  const sub = resolvePlanSubscription(plan, expiresDate);
  const existing = await c.env.DB.prepare('SELECT * FROM users WHERE LOWER(email) = ?')
    .bind(email)
    .first<any>();

  if (existing) {
    const nextName = rawName || existing.displayName;
    await c.env.DB.prepare(
      'UPDATE users SET displayName = ?, isPro = ?, proExpiresAt = ? WHERE id = ?'
    )
      .bind(nextName, sub.isPro, sub.proExpiresAt, existing.id)
      .run();
    await recordAdminAudit(c, 'user_subscription_updated', email, `Updated to ${sub.label}`);
    return c.redirect(
      redirectTab('users', { ok: `Updated ${email} → ${sub.label}.` })
    );
  }

  const prefix = provider === 'apple' ? 'usr_a_' : provider === 'google' ? 'usr_g_' : 'usr_m_';
  const newId = deterministicUserIdFromEmail(email, prefix);
  const displayName = rawName || email.split('@')[0];

  await c.env.DB.prepare(
    `INSERT INTO users (id, email, displayName, photoUrl, provider, isPro, proExpiresAt, dailyAiQueriesCount, lastAiQueryDate, createdAt)
     VALUES (?, ?, ?, NULL, ?, ?, ?, 0, NULL, ?)`
  )
    .bind(newId, email, displayName, provider, sub.isPro, sub.proExpiresAt, Date.now())
    .run();

  await recordAdminAudit(c, 'user_provisioned', email, `Created (${provider}) with ${sub.label}`);
  return c.redirect(
    redirectTab('users', { ok: `Provisioned ${email} with ${sub.label}.` })
  );
});

adminRouter.post('/users/subscription', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const plan = String(body['plan'] || 'free').trim();
  const expiresDate = String(body['expiresDate'] || '').trim();
  if (!userId || !c.env?.DB) {
    return c.redirect(redirectTab('users', { err: 'Missing user ID.' }));
  }

  const existing = await c.env.DB.prepare('SELECT id, email, isPro, proExpiresAt FROM users WHERE id = ?')
    .bind(userId)
    .first<any>();
  if (!existing) {
    return c.redirect(redirectTab('users', { err: 'User not found.' }));
  }

  let sub = resolvePlanSubscription(plan, expiresDate);
  // If extending an already active timed Pro subscription via +30d / +365d, stack onto current expiry
  if (
    (plan === 'pro_30d' || plan === 'pro_365d') &&
    existing.isPro === 1 &&
    existing.proExpiresAt &&
    Number(existing.proExpiresAt) > Date.now()
  ) {
    const addDays = plan === 'pro_365d' ? 365 : 30;
    sub = {
      isPro: 1,
      proExpiresAt: Number(existing.proExpiresAt) + addDays * DAY_MS,
      label: `Extended Pro (+${addDays}d)`,
    };
  }

  await c.env.DB.prepare('UPDATE users SET isPro = ?, proExpiresAt = ? WHERE id = ?')
    .bind(sub.isPro, sub.proExpiresAt, userId)
    .run();

  await recordAdminAudit(
    c,
    sub.isPro === 1 ? 'pro_granted' : 'pro_revoked',
    existing.email || userId,
    sub.label
  );
  return c.redirect(
    redirectTab('users', { ok: `${existing.email || userId} → ${sub.label}.` })
  );
});

adminRouter.post('/users/reset-quota', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  if (!userId || !c.env?.DB) {
    return c.redirect(redirectTab('users', { err: 'Missing user ID.' }));
  }

  await c.env.DB.prepare('UPDATE users SET dailyAiQueriesCount = 0, lastAiQueryDate = NULL WHERE id = ?')
    .bind(userId)
    .run();
  await recordAdminAudit(c, 'ai_quota_reset', userId, 'Daily AI query counter reset to 0');
  return c.redirect(redirectTab('users', { ok: `Reset AI quota for ${userId}.` }));
});

adminRouter.post('/users/delete', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const confirmed = String(body['confirm'] || '') === 'yes';
  if (!userId || !confirmed || !c.env?.DB) {
    return c.redirect(redirectTab('users', { err: 'Confirmation required to delete user.' }));
  }

  const user = await c.env.DB.prepare('SELECT id, email FROM users WHERE id = ?')
    .bind(userId)
    .first<any>();
  const email = user?.email ? String(user.email).toLowerCase() : '';

  const stmts = [
    c.env.DB.prepare('DELETE FROM sync_records WHERE userId = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM user_preferences WHERE userId = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM telemetry_events WHERE userId = ?').bind(userId),
    c.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(userId),
  ];
  if (email) {
    stmts.push(
      c.env.DB.prepare('DELETE FROM account_deletions WHERE LOWER(email) = ?').bind(email)
    );
  }
  await c.env.DB.batch(stmts);

  await recordAdminAudit(
    c,
    'user_deleted',
    email || userId,
    'Cascaded delete across users, sync_records, preferences, telemetry & deletions'
  );
  return c.redirect(redirectTab('users', { ok: `Permanently deleted ${email || userId}.` }));
});

// ==========================================
// Cloud Backup & Deletion Queue Management
// ==========================================
adminRouter.post('/backups/delete', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  if (!userId || String(body['confirm'] || '') !== 'yes' || !c.env?.DB) {
    return c.redirect(redirectTab('backups', { err: 'Confirmation required.' }));
  }

  await c.env.DB.prepare('DELETE FROM sync_records WHERE userId = ?').bind(userId).run();
  await recordAdminAudit(c, 'backup_deleted', userId, 'Cloud sync vault removed');
  return c.redirect(redirectTab('backups', { ok: `Deleted cloud vault for ${userId}.` }));
});

adminRouter.post('/deletions/cancel', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const id = String(body['id'] || '').trim();
  if (!id || !c.env?.DB) {
    return c.redirect(redirectTab('deletions', { err: 'Missing deletion ID.' }));
  }

  await c.env.DB.prepare(
    `UPDATE account_deletions SET status = 'cancelled', cancelledAt = ? WHERE id = ?`
  )
    .bind(Date.now(), id)
    .run();
  await recordAdminAudit(c, 'deletion_cancelled', id, 'Admin cancelled pending deletion request');
  return c.redirect(redirectTab('deletions', { ok: 'Deletion request cancelled.' }));
});

adminRouter.post('/deletions/purge', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const id = String(body['id'] || '').trim();
  if (!id || String(body['confirm'] || '') !== 'yes' || !c.env?.DB) {
    return c.redirect(redirectTab('deletions', { err: 'Confirmation required to purge.' }));
  }

  const req = await c.env.DB.prepare('SELECT * FROM account_deletions WHERE id = ?')
    .bind(id)
    .first<any>();
  if (!req) {
    return c.redirect(redirectTab('deletions', { err: 'Request not found.' }));
  }

  const email = String(req.email || '').toLowerCase();
  const user = await c.env.DB.prepare('SELECT id FROM users WHERE LOWER(email) = ?')
    .bind(email)
    .first<any>();

  const stmts = [
    c.env.DB.prepare(`UPDATE account_deletions SET status = 'purged', confirmedAt = COALESCE(confirmedAt, ?) WHERE id = ?`).bind(
      Date.now(),
      id
    ),
  ];
  if (user?.id) {
    stmts.push(
      c.env.DB.prepare('DELETE FROM sync_records WHERE userId = ?').bind(user.id),
      c.env.DB.prepare('DELETE FROM user_preferences WHERE userId = ?').bind(user.id),
      c.env.DB.prepare('DELETE FROM telemetry_events WHERE userId = ?').bind(user.id),
      c.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(user.id)
    );
  }
  await c.env.DB.batch(stmts);
  await recordAdminAudit(c, 'deletion_purged', email, 'Executed immediate account & vault purge');
  return c.redirect(redirectTab('deletions', { ok: `Purged account data for ${email}.` }));
});

// ==========================================
// Telemetry Cleanup & Danger Zone Full Wipe
// ==========================================
adminRouter.post('/telemetry/clear', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const scope = String(body['scope'] || 'crashes');
  if (String(body['confirm'] || '') !== 'yes') {
    return c.redirect(redirectTab('telemetry', { err: 'Confirmation required.' }));
  }

  if (scope === 'crashes') {
    for (let i = memoryEvents.length - 1; i >= 0; i--) {
      if (memoryEvents[i].eventType === 'crash' || memoryEvents[i].eventType === 'exception') {
        memoryEvents.splice(i, 1);
      }
    }
    if (c.env?.DB) {
      await c.env.DB.prepare(
        `DELETE FROM telemetry_events WHERE eventType IN ('crash', 'exception')`
      ).run();
    }
    await recordAdminAudit(c, 'clear_crashes', 'telemetry_events', 'Cleared crash & exception logs');
    return c.redirect(redirectTab('telemetry', { ok: 'Cleared crash and exception logs.' }));
  }

  memoryEvents.length = 0;
  if (c.env?.DB) {
    await c.env.DB.prepare('DELETE FROM telemetry_events').run();
  }
  await recordAdminAudit(c, 'clear_telemetry', 'telemetry_events', 'Cleared all telemetry logs');
  return c.redirect(redirectTab('telemetry', { ok: 'Cleared all telemetry events.' }));
});

adminRouter.post('/danger/wipe', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const scope = String(body['scope'] || '').trim();
  const phrase = String(body['phrase'] || '').trim();
  const confirmed = String(body['confirm'] || '') === 'yes';

  if (!confirmed || !c.env?.DB) {
    return c.redirect(redirectTab('danger', { err: 'Checkbox confirmation is required.' }));
  }

  if (scope === 'telemetry') {
    if (phrase !== 'CLEAR TELEMETRY') {
      return c.redirect(redirectTab('danger', { err: 'Confirmation phrase must be CLEAR TELEMETRY.' }));
    }
    memoryEvents.length = 0;
    await c.env.DB.prepare('DELETE FROM telemetry_events').run();
    await recordAdminAudit(c, 'wipe_telemetry', 'telemetry_events', 'Full telemetry wipe');
    return c.redirect(redirectTab('danger', { ok: 'All telemetry and crash logs cleared.' }));
  }

  if (scope === 'backups') {
    if (phrase !== 'DELETE BACKUPS') {
      return c.redirect(redirectTab('danger', { err: 'Confirmation phrase must be DELETE BACKUPS.' }));
    }
    await c.env.DB.prepare('DELETE FROM sync_records').run();
    await recordAdminAudit(c, 'wipe_backups', 'sync_records', 'Deleted all cloud sync vaults');
    return c.redirect(redirectTab('danger', { ok: 'All cloud sync backups deleted.' }));
  }

  if (scope === 'all') {
    if (phrase !== 'DELETE ALL DATA') {
      return c.redirect(redirectTab('danger', { err: 'Confirmation phrase must be DELETE ALL DATA.' }));
    }
    memoryEvents.length = 0;
    await c.env.DB.batch([
      c.env.DB.prepare('DELETE FROM sync_records'),
      c.env.DB.prepare('DELETE FROM user_preferences'),
      c.env.DB.prepare('DELETE FROM telemetry_events'),
      c.env.DB.prepare('DELETE FROM account_deletions'),
      c.env.DB.prepare('DELETE FROM users'),
    ]);
    await recordAdminAudit(
      c,
      'wipe_all_data',
      'ALL_TABLES',
      'Factory server wipe: users, backups, preferences, telemetry, deletions purged'
    );
    return c.redirect(
      redirectTab('overview', { ok: 'All server data has been permanently deleted.' })
    );
  }

  return c.redirect(redirectTab('danger', { err: 'Unknown wipe scope.' }));
});
