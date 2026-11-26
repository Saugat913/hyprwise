// Production Admin Console Routes (Path-only at /admin, HMAC-SHA256 Session + CSRF + Rate Limit + Audit Log)
// Supports full server data editing (profiles, Pro subscriptions, preferences, AI quotas, Cloud Sync JSON vaults),
// live app system monitoring, CSV/JSON exports, deletion compliance queue, and Danger Zone wipes.

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
  type AdminBackupInspect,
  type AdminBackupView,
  type AdminHealthCheck,
  type AdminPrefRow,
  type AdminTab,
  type AdminTableStat,
  type AdminUserInspect,
  type AdminUserView,
} from './admin_ui';

export const adminRouter = new Hono<{ Bindings: Bindings }>();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_VAULT_EDIT_BYTES = 5 * 1024 * 1024;
const ALLOWED_TABS = new Set<AdminTab>([
  'overview',
  'users',
  'backups',
  'data',
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

async function ensureAdminTables(db?: D1Database): Promise<void> {
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
    await db
      .prepare(
        `CREATE TABLE IF NOT EXISTS user_preferences (
          userId TEXT PRIMARY KEY,
          locale TEXT,
          baseCurrency TEXT,
          onboarded INTEGER DEFAULT 1,
          updatedAt INTEGER
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
    await ensureAdminTables(c.env.DB);
    const id = `aud_${crypto.randomUUID().replace(/-/g, '').slice(0, 16)}`;
    await c.env.DB.prepare(
      `INSERT INTO admin_audit_logs (id, action, target, details, ipAddress, createdAt)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
      .bind(id, action, target, details, clientIp(c), Date.now())
      .run();
  } catch (_) {}
}

function summarizeSyncPayload(payloadStr: string): Array<{ key: string; count: string }> {
  try {
    const parsed = JSON.parse(payloadStr);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return [{ key: 'root', count: Array.isArray(parsed) ? `${parsed.length} items` : typeof parsed }];
    }
    const items: Array<{ key: string; count: string }> = [];
    for (const [k, v] of Object.entries(parsed as Record<string, unknown>)) {
      if (Array.isArray(v)) {
        items.push({ key: k, count: `${v.length}` });
      } else if (v && typeof v === 'object') {
        items.push({ key: k, count: `${Object.keys(v as object).length} keys` });
      } else if (v !== null && v !== undefined) {
        items.push({ key: k, count: String(v).slice(0, 24) });
      }
    }
    return items.slice(0, 14);
  } catch {
    return [{ key: 'raw', count: 'non-JSON payload' }];
  }
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

function redirectTab(
  tab: AdminTab,
  params: { ok?: string; err?: string; inspect?: string }
): string {
  const qs = new URLSearchParams({ tab });
  if (params.inspect) qs.set('inspect', params.inspect);
  if (params.ok) qs.set('ok', params.ok);
  if (params.err) qs.set('err', params.err);
  return `/admin?${qs.toString()}`;
}

function csvCell(v: unknown): string {
  const s = String(v ?? '').replace(/"/g, '""');
  return `"${s}"`;
}

// ==========================================
// GET /admin — Login or Modern Operations Console
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
  const eventTypeFilter = (c.req.query('etype') || 'all').trim();
  const inspectId = (c.req.query('inspect') || '').trim();
  const openCreate = c.req.query('new') === '1';
  const flashOk = c.req.query('ok') || undefined;
  const flashErr = c.req.query('err') || undefined;

  let rawUsers: any[] = [];
  let backups: AdminBackupView[] = [];
  let prefsList: AdminPrefRow[] = [];
  let deletions: any[] = [];
  let auditLogs: AdminAuditRow[] = [];
  let tableStats: AdminTableStat[] = [];
  let inspectedUser: AdminUserInspect | null = null;
  let inspectedBackup: AdminBackupInspect | null = null;
  let dbConnected = false;

  const allEvents = [...memoryEvents];
  const todayStr = new Date().toISOString().slice(0, 10);

  if (c.env?.DB) {
    try {
      await ensureAdminTables(c.env.DB);
      dbConnected = true;

      const [uRes, bRes, pRes, dRes, tRes, aRes, cntUsers, cntSync, cntPrefs, cntTel, cntDel, cntAud] =
        await Promise.all([
          c.env.DB.prepare('SELECT * FROM users ORDER BY createdAt DESC LIMIT 500').all(),
          c.env.DB.prepare(
            `SELECT s.userId, u.email, u.displayName, s.version, LENGTH(s.payload) AS sizeBytes, s.lastSyncedAt
             FROM sync_records s
             LEFT JOIN users u ON u.id = s.userId
             ORDER BY s.lastSyncedAt DESC LIMIT 200`
          ).all(),
          c.env.DB.prepare(
            `SELECT p.userId, u.email, u.displayName, p.locale, p.baseCurrency, p.onboarded, p.updatedAt
             FROM user_preferences p
             LEFT JOIN users u ON u.id = p.userId
             ORDER BY p.updatedAt DESC LIMIT 300`
          ).all(),
          c.env.DB.prepare(
            'SELECT * FROM account_deletions ORDER BY requestedAt DESC LIMIT 100'
          ).all(),
          c.env.DB.prepare(
            'SELECT * FROM telemetry_events ORDER BY createdAt DESC LIMIT 300'
          ).all(),
          c.env.DB.prepare(
            'SELECT * FROM admin_audit_logs ORDER BY createdAt DESC LIMIT 150'
          ).all(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM users').first<any>(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM sync_records').first<any>(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM user_preferences').first<any>(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM telemetry_events').first<any>(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM account_deletions').first<any>(),
          c.env.DB.prepare('SELECT COUNT(*) AS c FROM admin_audit_logs').first<any>(),
        ]);

      rawUsers = (uRes.results || []) as any[];
      backups = ((bRes.results || []) as any[]).map((b) => ({
        userId: String(b.userId),
        email: b.email ? String(b.email) : null,
        displayName: b.displayName ? String(b.displayName) : null,
        version: Number(b.version || 1),
        sizeBytes: Number(b.sizeBytes || 0),
        lastSyncedAt: Number(b.lastSyncedAt || 0),
      }));
      prefsList = ((pRes.results || []) as any[]).map((p) => ({
        userId: String(p.userId),
        email: p.email ? String(p.email) : null,
        displayName: p.displayName ? String(p.displayName) : null,
        locale: p.locale ? String(p.locale) : '',
        baseCurrency: p.baseCurrency ? String(p.baseCurrency) : '',
        onboarded: Boolean(p.onboarded),
        updatedAt: Number(p.updatedAt || 0),
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

      tableStats = [
        { table: 'users', rows: Number(cntUsers?.c || 0), description: 'Accounts, Pro tier & AI quotas' },
        { table: 'sync_records', rows: Number(cntSync?.c || 0), description: 'Cloud sync backup JSON vaults' },
        { table: 'user_preferences', rows: Number(cntPrefs?.c || 0), description: 'Base currency, locale & onboarding' },
        { table: 'telemetry_events', rows: Number(cntTel?.c || 0), description: 'App crashes, exceptions & actions' },
        { table: 'account_deletions', rows: Number(cntDel?.c || 0), description: '30-day compliance deletion queue' },
        { table: 'admin_audit_logs', rows: Number(cntAud?.c || 0), description: 'Immutable console operation log' },
      ];

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

      // Load deep inspector payload when viewing a specific backup or user
      if (tab === 'backups' && inspectId) {
        const rec = await c.env.DB.prepare(
          `SELECT s.userId, u.email, u.displayName, s.version, s.lastSyncedAt, s.payload
           FROM sync_records s LEFT JOIN users u ON u.id = s.userId
           WHERE s.userId = ?`
        )
          .bind(inspectId)
          .first<any>();
        if (rec) {
          let prettyJson = String(rec.payload || '');
          try {
            prettyJson = JSON.stringify(JSON.parse(prettyJson), null, 2);
          } catch (_) {}
          const rawBytes = new TextEncoder().encode(String(rec.payload || '')).byteLength;
          const truncated = prettyJson.length > 60000;
          inspectedBackup = {
            userId: String(rec.userId),
            email: rec.email ? String(rec.email) : null,
            displayName: rec.displayName ? String(rec.displayName) : null,
            version: Number(rec.version || 1),
            sizeBytes: rawBytes,
            lastSyncedAt: Number(rec.lastSyncedAt || 0),
            summary: summarizeSyncPayload(String(rec.payload || '')),
            prettyJson: truncated ? prettyJson.slice(0, 60000) : prettyJson,
            truncated,
          };
        }
      }
    } catch (_) {}
  }

  const backupByUser = new Map<string, AdminBackupView>();
  for (const b of backups) backupByUser.set(b.userId, b);

  const prefByUser = new Map<string, AdminPrefRow>();
  for (const p of prefsList) prefByUser.set(p.userId, p);

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
    const pr = prefByUser.get(String(u.id));
    return {
      id: String(u.id),
      email: String(u.email || ''),
      displayName: String(u.displayName || ''),
      provider: String(u.provider || 'google'),
      isPro: isProFlag ? 1 : 0,
      proExpiresAt: u.proExpiresAt ? Number(u.proExpiresAt) : null,
      activePro: quota.activePro,
      expiredPro,
      dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
      createdAt: Number(u.createdAt || 0),
      backupVersion: b ? b.version : null,
      backupBytes: b ? b.sizeBytes : null,
      backupUpdatedAt: b ? b.lastSyncedAt : null,
      baseCurrency: pr?.baseCurrency || null,
      locale: pr?.locale || null,
      onboarded: pr ? pr.onboarded : null,
    };
  });

  // Load User Inspector details if ?tab=users&inspect=<userId>
  if (tab === 'users' && inspectId) {
    const found = allUserViews.find((u) => u.id === inspectId);
    if (found) {
      let vaultSummary: Array<{ key: string; count: string }> = [];
      if (c.env?.DB && found.backupVersion !== null) {
        try {
          const syncRow = await c.env.DB.prepare('SELECT payload FROM sync_records WHERE userId = ?')
            .bind(found.id)
            .first<any>();
          if (syncRow?.payload) {
            vaultSummary = summarizeSyncPayload(String(syncRow.payload));
          }
        } catch (_) {}
      }
      const recentEvents = allEvents
        .filter((e) => e.userId === found.id || e.userId === found.email)
        .slice(0, 10);
      inspectedUser = {
        user: found,
        vaultSummary,
        recentEvents,
      };
    }
  }

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

  // Apply filters on Telemetry tab
  const filteredEvents = allEvents.filter((e) => {
    if (eventTypeFilter === 'crash' && e.eventType !== 'crash' && e.eventType !== 'exception') {
      return false;
    }
    if (eventTypeFilter === 'action' && e.eventType !== 'action') return false;
    if (eventTypeFilter === 'screen_view' && e.eventType !== 'screen_view') return false;
    if (tab === 'telemetry' && searchQuery) {
      const q = searchQuery.toLowerCase();
      const blob = `${e.eventName} ${e.eventType} ${e.userId || ''} ${e.details || ''} ${e.appVersion || ''}`.toLowerCase();
      if (!blob.includes(q)) return false;
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
      detail: dbConnected ? 'Connected · tilvane-db responding' : 'D1 binding unavailable',
    },
    {
      label: 'Admin Password (ADMIN_PASSWORD)',
      ok: !usingDefaultPassword,
      critical: true,
      detail: usingDefaultPassword
        ? 'Fallback dev password active — rotate via wrangler secret put'
        : 'Production secret active',
    },
    {
      label: 'Session Signing (SESSION_SECRET)',
      ok: !usingDefaultSecret,
      critical: true,
      detail: usingDefaultSecret
        ? 'Not set — run wrangler secret put SESSION_SECRET'
        : 'HMAC-SHA256 signing active',
    },
    {
      label: 'Gemini AI Proxy (GEMINI_API_KEY)',
      ok: Boolean(c.env?.GEMINI_API_KEY?.trim()),
      detail: c.env?.GEMINI_API_KEY?.trim()
        ? 'Gemini 2.5 Flash reasoning & OCR live'
        : 'Missing — AI falls back to local mode',
    },
    {
      label: 'RevenueCat Webhook (REVENUECAT_WEBHOOK_AUTH)',
      ok: Boolean(c.env?.REVENUECAT_WEBHOOK_AUTH?.trim()),
      detail: c.env?.REVENUECAT_WEBHOOK_AUTH?.trim()
        ? 'Server-to-server billing webhook armed'
        : 'Not set — webhook rejects (503 fail-closed)',
    },
    {
      label: 'Firebase App Check (ENFORCE_APP_CHECK)',
      ok: c.env?.ENFORCE_APP_CHECK === 'true',
      detail:
        c.env?.ENFORCE_APP_CHECK === 'true'
          ? 'Strictly enforcing signed RS256 App Check tokens'
          : 'Permissive mode — enable after mobile rollout',
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
      dbConnected,
      searchQuery,
      tierFilter,
      eventTypeFilter,
      openCreate,
      metrics: {
        totalUsers,
        activeProUsers,
        expiredProUsers,
        freeUsers: Math.max(0, totalUsers - activeProUsers - expiredProUsers),
        conversionRate,
        totalBackups: backups.length,
        totalBackupBytes,
        totalExceptions,
        totalEvents: allEvents.length,
        crashFreeRate: analyticsSummary.crashFreeRate,
        aiQueriesToday,
        pendingDeletions,
      },
      users: filteredUsers,
      allUsersCompact: allUserViews.slice(0, 100).map((u) => ({ id: u.id, email: u.email, displayName: u.displayName })),
      inspectedUser,
      backups,
      inspectedBackup,
      preferences: prefsList,
      deletions,
      events: filteredEvents,
      auditLogs,
      tableStats,
      healthChecks,
      analyticsHtml,
    })
  );
});

// ==========================================
// Exports (CSV Users & JSON Cloud Vault) — Auth Protected
// ==========================================
adminRouter.get('/export/users.csv', async (c) => {
  const session = await resolveAdminSession(c);
  if (!session.ok) return c.redirect('/admin');
  if (!c.env?.DB) return c.text('Database unavailable', 503);

  const res = await c.env.DB.prepare(
    `SELECT u.id, u.email, u.displayName, u.provider, u.isPro, u.proExpiresAt, u.dailyAiQueriesCount, u.createdAt,
            p.baseCurrency, p.locale
     FROM users u
     LEFT JOIN user_preferences p ON p.userId = u.id
     ORDER BY u.createdAt DESC LIMIT 2000`
  ).all();

  const header = [
    'id',
    'email',
    'displayName',
    'provider',
    'isPro',
    'proExpiresAt',
    'dailyAiQueriesCount',
    'baseCurrency',
    'locale',
    'createdAt',
  ].join(',');

  const lines = ((res.results || []) as any[]).map((r) =>
    [
      r.id,
      r.email,
      r.displayName,
      r.provider,
      r.isPro ? 'true' : 'false',
      r.proExpiresAt ? new Date(Number(r.proExpiresAt)).toISOString() : '',
      r.dailyAiQueriesCount ?? 0,
      r.baseCurrency ?? '',
      r.locale ?? '',
      r.createdAt ? new Date(Number(r.createdAt)).toISOString() : '',
    ]
      .map(csvCell)
      .join(',')
  );

  await recordAdminAudit(c, 'export_users_csv', 'users', `Exported ${lines.length} users to CSV`);
  return new Response([header, ...lines].join('\n'), {
    status: 200,
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="hyprwise-users-${new Date().toISOString().slice(0, 10)}.csv"`,
      'Cache-Control': 'no-store',
    },
  });
});

adminRouter.get('/backups/export', async (c) => {
  const session = await resolveAdminSession(c);
  if (!session.ok) return c.redirect('/admin');

  const userId = (c.req.query('userId') || '').trim();
  if (!userId || !c.env?.DB) return c.text('Missing userId', 400);

  const rec = await c.env.DB.prepare('SELECT userId, version, lastSyncedAt, payload FROM sync_records WHERE userId = ?')
    .bind(userId)
    .first<any>();
  if (!rec) return c.text('Vault not found', 404);

  let body = String(rec.payload || '{}');
  try {
    body = JSON.stringify(JSON.parse(body), null, 2);
  } catch (_) {}

  await recordAdminAudit(c, 'backup_exported', userId, `Downloaded sync vault v${rec.version}`);
  const safeName = userId.replace(/[^a-zA-Z0-9_-]/g, '_');
  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Disposition': `attachment; filename="hyprwise-vault-${safeName}-v${rec.version}.json"`,
      'Cache-Control': 'no-store',
    },
  });
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
        maxAge: 60 * 60 * 12,
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
  const rawProvider = String(body['provider'] || 'google').trim().toLowerCase();
  const provider = rawProvider === 'apple' ? 'apple' : 'google';
  const plan = String(body['plan'] || 'pro_lifetime').trim();
  const expiresDate = String(body['expiresDate'] || '').trim();
  const baseCurrency = String(body['baseCurrency'] || '').trim().toUpperCase().slice(0, 6);

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
    if (baseCurrency) {
      await ensureAdminTables(c.env.DB);
      await c.env.DB.prepare(
        `INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
         VALUES (?, 'en', ?, 1, ?)
         ON CONFLICT(userId) DO UPDATE SET baseCurrency = excluded.baseCurrency, updatedAt = excluded.updatedAt`
      )
        .bind(existing.id, baseCurrency, Date.now())
        .run();
    }
    await recordAdminAudit(c, 'user_subscription_updated', email, `Updated to ${sub.label}`);
    return c.redirect(
      redirectTab('users', { inspect: existing.id, ok: `Updated ${email} → ${sub.label}.` })
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

  if (baseCurrency) {
    await ensureAdminTables(c.env.DB);
    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
       VALUES (?, 'en', ?, 1, ?)`
    )
      .bind(newId, baseCurrency, Date.now())
      .run();
  }

  await recordAdminAudit(c, 'user_provisioned', email, `Created (${provider}) with ${sub.label}`);
  return c.redirect(
    redirectTab('users', { inspect: newId, ok: `Provisioned ${email} with ${sub.label}.` })
  );
});

// Edit user profile, quota, and preferences directly from the User Inspector
adminRouter.post('/users/update', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const email = String(body['email'] || '').trim().toLowerCase();
  const displayName = String(body['displayName'] || '').trim().slice(0, 80);
  const rawProvider = String(body['provider'] || 'google').trim().toLowerCase();
  const provider = rawProvider === 'apple' ? 'apple' : 'google';
  const rawQuota = Number(body['dailyAiQueriesCount']);
  const dailyAiQueriesCount = Number.isFinite(rawQuota) ? Math.max(0, Math.min(10000, Math.floor(rawQuota))) : 0;
  const baseCurrency = String(body['baseCurrency'] || '').trim().toUpperCase().slice(0, 6);
  const locale = String(body['locale'] || '').trim().slice(0, 12);
  const onboarded = String(body['onboarded'] || '1') === '1' ? 1 : 0;

  if (!userId || !c.env?.DB) {
    return c.redirect(redirectTab('users', { err: 'Missing user ID.' }));
  }
  if (!email || !EMAIL_REGEX.test(email)) {
    return c.redirect(redirectTab('users', { inspect: userId, err: 'Valid email address required.' }));
  }

  const todayStr = new Date().toISOString().slice(0, 10);
  await ensureAdminTables(c.env.DB);
  await c.env.DB.prepare(
    `UPDATE users
     SET email = ?, displayName = ?, provider = ?, dailyAiQueriesCount = ?, lastAiQueryDate = ?
     WHERE id = ?`
  )
    .bind(
      email,
      displayName || email.split('@')[0],
      provider,
      dailyAiQueriesCount,
      dailyAiQueriesCount > 0 ? todayStr : null,
      userId
    )
    .run();

  if (baseCurrency || locale) {
    await c.env.DB.prepare(
      `INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(userId) DO UPDATE SET
         locale = excluded.locale,
         baseCurrency = excluded.baseCurrency,
         onboarded = excluded.onboarded,
         updatedAt = excluded.updatedAt`
    )
      .bind(userId, locale || null, baseCurrency || null, onboarded, Date.now())
      .run();
  }

  await recordAdminAudit(
    c,
    'user_updated',
    email,
    `Profile/prefs updated (currency=${baseCurrency || '-'}, locale=${locale || '-'}, aiUsed=${dailyAiQueriesCount})`
  );
  return c.redirect(
    redirectTab('users', { inspect: userId, ok: `Saved server changes for ${email}.` })
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
  if (
    (plan === 'pro_30d' || plan === 'pro_90d' || plan === 'pro_365d') &&
    existing.isPro === 1 &&
    existing.proExpiresAt &&
    Number(existing.proExpiresAt) > Date.now()
  ) {
    const addDays = plan === 'pro_365d' ? 365 : plan === 'pro_90d' ? 90 : 30;
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
    redirectTab('users', { inspect: userId, ok: `${existing.email || userId} → ${sub.label}.` })
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
  return c.redirect(redirectTab('users', { inspect: userId, ok: `Reset AI quota for ${userId}.` }));
});

adminRouter.post('/users/delete', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const confirmed = String(body['confirm'] || '') === 'yes';
  if (!userId || !confirmed || !c.env?.DB) {
    return c.redirect(redirectTab('users', { inspect: userId, err: 'Confirmation required to delete user.' }));
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
// Preferences & Cloud Sync Vault Editing
// ==========================================
adminRouter.post('/preferences/upsert', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const baseCurrency = String(body['baseCurrency'] || '').trim().toUpperCase().slice(0, 6);
  const locale = String(body['locale'] || '').trim().slice(0, 12);
  const onboarded = String(body['onboarded'] || '1') === '1' ? 1 : 0;

  if (!userId || !c.env?.DB) {
    return c.redirect(redirectTab('data', { err: 'User ID is required.' }));
  }

  await ensureAdminTables(c.env.DB);
  await c.env.DB.prepare(
    `INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(userId) DO UPDATE SET
       locale = excluded.locale,
       baseCurrency = excluded.baseCurrency,
       onboarded = excluded.onboarded,
       updatedAt = excluded.updatedAt`
  )
    .bind(userId, locale || null, baseCurrency || null, onboarded, Date.now())
    .run();

  await recordAdminAudit(
    c,
    'preferences_updated',
    userId,
    `currency=${baseCurrency || '-'}, locale=${locale || '-'}, onboarded=${onboarded}`
  );
  return c.redirect(redirectTab('data', { ok: `Saved preferences for ${userId}.` }));
});

adminRouter.post('/backups/update', async (c) => {
  const body = await c.req.parseBody();
  const guard = await requireAdminAndCsrf(c, body);
  if (!guard.ok) return guard.response;

  const userId = String(body['userId'] || '').trim();
  const rawPayload = String(body['payload'] || '').trim();
  if (!userId || !rawPayload || !c.env?.DB) {
    return c.redirect(redirectTab('backups', { inspect: userId, err: 'User ID and JSON payload are required.' }));
  }

  if (new TextEncoder().encode(rawPayload).byteLength > MAX_VAULT_EDIT_BYTES) {
    return c.redirect(redirectTab('backups', { inspect: userId, err: 'Payload exceeds 5 MB limit.' }));
  }

  let normalizedJson: string;
  try {
    normalizedJson = JSON.stringify(JSON.parse(rawPayload));
  } catch (err: any) {
    return c.redirect(
      redirectTab('backups', {
        inspect: userId,
        err: `Invalid JSON syntax: ${err?.message || 'parse failed'}`,
      })
    );
  }

  const existing = await c.env.DB.prepare('SELECT version FROM sync_records WHERE userId = ?')
    .bind(userId)
    .first<any>();
  const nextVersion = Number(existing?.version || 0) + 1;
  const now = Date.now();

  await c.env.DB.prepare(
    `INSERT OR REPLACE INTO sync_records (userId, version, lastSyncedAt, payload)
     VALUES (?, ?, ?, ?)`
  )
    .bind(userId, nextVersion, now, normalizedJson)
    .run();

  await recordAdminAudit(
    c,
    'backup_edited',
    userId,
    `Updated cloud sync vault JSON → v${nextVersion} (${normalizedJson.length} bytes)`
  );
  return c.redirect(
    redirectTab('backups', { inspect: userId, ok: `Saved cloud vault v${nextVersion} for ${userId}.` })
  );
});

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

// ==========================================
// Deletion Queue Management
// ==========================================
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
    c.env.DB.prepare(
      `UPDATE account_deletions SET status = 'purged', confirmedAt = COALESCE(confirmedAt, ?) WHERE id = ?`
    ).bind(Date.now(), id),
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
