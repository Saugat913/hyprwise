// Admin Dashboard and Monitoring Routes (Password: P@ssword123)

import { Hono } from 'hono';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';
import { type Bindings, type TelemetryEvent } from '../types';
import {
  renderAdminLoginPage,
  renderAdminDashboard,
  memoryEvents,
  ADMIN_PASSWORD,
  ADMIN_COOKIE_NAME,
  ADMIN_AUTH_TOKEN,
} from '../compliance_and_admin';
import { FirebaseAnalyticsService } from '../services/firebase_analytics';

export const adminRouter = new Hono<{ Bindings: Bindings }>();

export function isAdminAuthenticated(c: any): boolean {
  const cookie = getCookie(c, ADMIN_COOKIE_NAME);
  if (cookie === ADMIN_AUTH_TOKEN) return true;
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.includes(ADMIN_PASSWORD)) return true;
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

  // Fetch Firebase Analytics metrics and render visual charts
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
    const password = (body['password'] as string || '').trim();

    if (password === ADMIN_PASSWORD) {
      setCookie(c, ADMIN_COOKIE_NAME, ADMIN_AUTH_TOKEN, {
        path: '/',
        httpOnly: true,
        secure: false, // works on both localhost and edge HTTPS
        maxAge: 86400 * 7,
      });
      return c.redirect('/admin');
    }

    return c.html(renderAdminLoginPage({ error: 'Incorrect password. Access denied.' }));
  } catch (err: any) {
    return c.html(renderAdminLoginPage({ error: err.message || 'Login error' }));
  }
});

adminRouter.get('/logout', (c) => {
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/' });
  return c.redirect('/admin');
});

adminRouter.post('/logout', (c) => {
  deleteCookie(c, ADMIN_COOKIE_NAME, { path: '/' });
  return c.redirect('/admin');
});
