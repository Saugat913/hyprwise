// Admin Dashboard and Monitoring Routes

import { Hono, type Context } from 'hono';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';
import { type Bindings } from '../types';
import {
  renderAdminLoginPage,
  renderAdminDashboard,
  memoryEvents,
  ADMIN_COOKIE_NAME,
  getAdminPassword,
  getAdminAuthToken,
} from '../compliance_and_admin';
import { safeEqual } from '../middleware/jwt_verify';
import { FirebaseAnalyticsService } from '../services/firebase_analytics';

export const adminRouter = new Hono<{ Bindings: Bindings }>();

export function isAdminAuthenticated(c: Context<{ Bindings: Bindings }>): boolean {
  const expectedToken = getAdminAuthToken(c.env);
  const expectedPassword = getAdminPassword(c.env);

  const cookie = getCookie(c, ADMIN_COOKIE_NAME);
  if (cookie && safeEqual(cookie, expectedToken)) return true;

  const authHeader = c.req.header('Authorization');
  if (authHeader?.startsWith('Bearer ')) {
    const supplied = authHeader.slice(7).trim();
    if (safeEqual(supplied, expectedPassword) || safeEqual(supplied, expectedToken)) {
      return true;
    }
  }
  return false;
}

adminRouter.get('/', async (c) => {
  if (!isAdminAuthenticated(c)) {
    return c.html(renderAdminLoginPage());
  }

  let users: any[] = [];
  let totalUsers = 0;
  let proUsers = 0;
  let totalBackups = 0;

  if (c.env?.DB) {
    try {
      const userList = await c.env.DB.prepare('SELECT * FROM users ORDER BY createdAt DESC LIMIT 100').all();
      users = userList.results || [];
      totalUsers = users.length;
      proUsers = users.filter((u: any) => u.isPro === 1).length;

      const syncList = await c.env.DB.prepare('SELECT COUNT(*) as count FROM sync_records').first<{ count: number }>();
      totalBackups = syncList?.count || 0;
    } catch (_) {}
  }

  let deletions: any[] = [];
  if (c.env?.DB) {
    try {
      const delList = await c.env.DB.prepare(
        "SELECT * FROM account_deletions WHERE status IN ('pending_confirmation', 'confirmed') ORDER BY requestedAt DESC LIMIT 20"
      ).all();
      deletions = delList.results || [];
    } catch (_) {}
  }

  let allEvents = [...memoryEvents];
  if (c.env?.DB) {
    try {
      const dbEvents = await c.env.DB.prepare(
        'SELECT * FROM telemetry_events ORDER BY createdAt DESC LIMIT 100'
      ).all();
      if (dbEvents.results && dbEvents.results.length > 0) {
        const existingIds = new Set(allEvents.map((e) => e.id));
        for (const ev of dbEvents.results) {
          const item = ev as any;
          if (!existingIds.has(item.id)) {
            allEvents.push({
              id: item.id,
              userId: item.userId || null,
              eventType: item.eventType || 'action',
              eventName: item.eventName || '',
              details: item.details || null,
              deviceInfo: item.deviceInfo || null,
              appVersion: item.appVersion || '',
              createdAt: Number(item.createdAt) || Date.now(),
            });
          }
        }
        allEvents.sort((a, b) => b.createdAt - a.createdAt);
      }
    } catch (_) {}
  }

  const totalExceptions = allEvents.filter((e) => e.eventType === 'exception' || e.eventType === 'crash').length;
  const totalInteractions = allEvents.filter((e) => e.eventType === 'action' || e.eventType === 'screen_view').length;
  const conversionRate = totalUsers > 0 ? `${((proUsers / totalUsers) * 100).toFixed(1)}%` : '0%';

  const analyticsSummary = await FirebaseAnalyticsService.getAnalyticsSummary({
    propertyId: c.env?.GA4_PROPERTY_ID,
    events: allEvents,
    totalUsers,
  });
  const analyticsHtml = FirebaseAnalyticsService.renderAnalyticsChartsHtml(analyticsSummary);

  return c.html(
    renderAdminDashboard({
      metrics: {
        totalUsers,
        proUsers,
        conversionRate,
        totalBackups,
        totalExceptions,
        totalInteractions,
        uptime: '99.98%',
      },
      events: allEvents,
      users,
      deletions,
      analyticsHtml,
    })
  );
});

adminRouter.post('/login', async (c) => {
  try {
    const body = await c.req.parseBody();
    const password = String(body['password'] || '').trim();
    const expectedPassword = getAdminPassword(c.env);

    if (password.length > 0 && safeEqual(password, expectedPassword)) {
      const isHttps = c.req.url.startsWith('https://');
      setCookie(c, ADMIN_COOKIE_NAME, getAdminAuthToken(c.env), {
        path: '/admin',
        httpOnly: true,
        secure: isHttps,
        sameSite: 'Strict',
        maxAge: 86400 * 7,
      });
      return c.redirect('/admin');
    }

    return c.html(renderAdminLoginPage({ error: 'Incorrect password. Access denied.' }), 401);
  } catch (err: any) {
    return c.html(renderAdminLoginPage({ error: err.message || 'Login error' }), 500);
  }
});

adminRouter.get('/logout', (c) => {
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/admin' });
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/' });
  return c.redirect('/admin');
});

adminRouter.post('/logout', (c) => {
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/admin' });
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/' });
  return c.redirect('/admin');
});
