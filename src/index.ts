import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { type Bindings } from './types';
import { firebaseAppCheckMiddleware } from './middleware/app_check';
import { safeEqual } from './middleware/jwt_verify';
import { aiRouter } from './routes/ai';
import { syncRouter } from './routes/sync';
import { authRouter } from './routes/auth';
import { adminRouter } from './routes/admin';
import { renderLandingPage } from './routes/landing';
import {
  renderPrivacyPolicyPage,
  renderTermsOfServicePage,
  renderAccountDeletionPage,
  memoryEvents,
} from './compliance_and_admin';
import {
  HYPRWISE_FAVICON_SVG,
  HYPRWISE_MARK_SVG,
  HYPRWISE_BADGE_SVG,
  HYPRWISE_APP_ICON_DARK_SVG,
} from './brand_assets';

export { Bindings };

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const app = new Hono<{ Bindings: Bindings }>();

// Global request logger & security headers middleware
app.use('*', logger());
app.use('*', async (c, next) => {
  await next();
  c.header('X-Content-Type-Options', 'nosniff');
  c.header('X-Frame-Options', 'DENY');
  c.header('Referrer-Policy', 'strict-origin-when-cross-origin');
  c.header('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  if (c.req.url.startsWith('https://')) {
    c.header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }
  const contentType = c.res.headers.get('Content-Type') || '';
  if (contentType.includes('text/html')) {
    c.header(
      'Content-Security-Policy',
      "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; form-action 'self'; frame-ancestors 'none'; base-uri 'self'"
    );
  }
});

// Scoped CORS exclusively for API endpoints (never expose /admin or /delete-account cross-origin)
app.use(
  '/api/*',
  cors({
    origin: (origin, c) => {
      const configured = (c.env?.ALLOWED_ORIGINS || '')
        .split(',')
        .map((s: string) => s.trim())
        .filter(Boolean);
      if (configured.length === 0) return origin || '*';
      return configured.includes(origin) ? origin : '';
    },
    allowMethods: ['GET', 'POST', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-Firebase-AppCheck', 'X-User-Id', 'X-User-Email'],
    maxAge: 86400,
  })
);

// Firebase App Check / Mobile App Integrity Protection
app.use('/api/*', firebaseAppCheckMiddleware);

// ==========================================
// 1. Health & Edge Status
// ==========================================
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    service: 'hyprwise-server',
    version: '1.0.0',
    edge: true,
    timestamp: Date.now(),
  });
});

// ==========================================
// 2. Brand Assets & Public Pages
// ==========================================
app.get('/', (c) => c.html(renderLandingPage()));

app.get('/brand/favicon.svg', (c) =>
  c.text(HYPRWISE_FAVICON_SVG, 200, {
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'public, max-age=86400',
  })
);

app.get('/favicon.ico', (c) =>
  c.text(HYPRWISE_FAVICON_SVG, 200, {
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'public, max-age=86400',
  })
);

app.get('/brand/mark.svg', (c) =>
  c.text(HYPRWISE_MARK_SVG, 200, {
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'public, max-age=86400',
  })
);

app.get('/brand/icon.svg', (c) =>
  c.text(HYPRWISE_BADGE_SVG, 200, {
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'public, max-age=86400',
  })
);

app.get('/brand/app-icon.svg', (c) =>
  c.text(HYPRWISE_APP_ICON_DARK_SVG, 200, {
    'Content-Type': 'image/svg+xml; charset=utf-8',
    'Cache-Control': 'public, max-age=86400',
  })
);

// ==========================================
// 3. Compliance Pages (Google Play & Apple Mandate)
// ==========================================
app.get('/privacy', (c) => c.html(renderPrivacyPolicyPage()));
app.get('/privacy-policy', (c) => c.html(renderPrivacyPolicyPage()));

app.get('/terms', (c) => c.html(renderTermsOfServicePage()));
app.get('/terms-of-service', (c) => c.html(renderTermsOfServicePage()));

app.get('/delete-account', (c) => c.html(renderAccountDeletionPage()));
app.get('/account-deletion', (c) => c.html(renderAccountDeletionPage()));

// Handle web account deletion requests (30-day grace window)
app.post('/delete-account', async (c) => {
  try {
    const body = await c.req.parseBody();
    const email = String(body['email'] || body['identifier'] || '').trim().toLowerCase();
    const reason = String(body['reason'] || '').trim().slice(0, 200) || null;

    if (!email || !EMAIL_REGEX.test(email)) {
      return c.html(
        renderAccountDeletionPage({ error: 'Please enter a valid email address.' }),
        400
      );
    }

    const now = Date.now();
    const scheduledPurgeAt = now + THIRTY_DAYS_MS;
    const token = `del_${crypto.randomUUID().replace(/-/g, '')}`;
    const reqId = `req_${crypto.randomUUID().replace(/-/g, '')}`;

    if (c.env?.DB) {
      await c.env.DB.prepare(
        `INSERT INTO account_deletions (id, email, token, status, reason, requestedAt, scheduledPurgeAt)
         VALUES (?, ?, ?, 'pending_confirmation', ?, ?, ?)`
      )
        .bind(reqId, email, token, reason, now, scheduledPurgeAt)
        .run();
    }

    memoryEvents.unshift({
      id: `evt_del_req_${now}`,
      userId: email,
      eventType: 'action',
      eventName: 'account_deletion_requested',
      details: JSON.stringify({ reason }),
      deviceInfo: 'Web Portal',
      appVersion: 'web',
      createdAt: now,
    });
    if (memoryEvents.length > 1000) memoryEvents.length = 1000;

    return c.html(renderAccountDeletionPage({ status: 'email_sent', email, token }));
  } catch (err: any) {
    return c.html(
      renderAccountDeletionPage({ error: err.message || 'Failed to submit request.' }),
      500
    );
  }
});

app.get('/delete-account/confirm', async (c) => {
  const token = (c.req.query('token') || '').trim();
  if (!token) {
    return c.html(
      renderAccountDeletionPage({ error: 'Invalid or missing confirmation token.' }),
      400
    );
  }

  let email = '';
  let scheduledPurgeDate = '';
  if (c.env?.DB) {
    const record = await c.env.DB.prepare('SELECT * FROM account_deletions WHERE token = ?')
      .bind(token)
      .first<any>();
    if (!record) {
      return c.html(
        renderAccountDeletionPage({ error: 'Confirmation token not found or expired.' }),
        404
      );
    }
    if (record.status === 'cancelled') {
      return c.html(
        renderAccountDeletionPage({
          error: 'This deletion request was already cancelled.',
          email: record.email,
        }),
        400
      );
    }
    email = record.email;
    const now = Date.now();
    const purgeAt = Number(record.scheduledPurgeAt) || now + THIRTY_DAYS_MS;
    scheduledPurgeDate = new Date(purgeAt).toISOString().slice(0, 10);
    await c.env.DB.prepare(
      `UPDATE account_deletions SET status = 'confirmed', confirmedAt = ?, scheduledPurgeAt = ? WHERE id = ?`
    )
      .bind(now, purgeAt, record.id)
      .run();
  }

  return c.html(
    renderAccountDeletionPage({
      status: 'confirmed',
      email,
      scheduledPurgeDate,
    })
  );
});

app.post('/delete-account/cancel', async (c) => {
  try {
    const body = await c.req.parseBody();
    const email = String(body['email'] || '').trim().toLowerCase();
    if (!email || !EMAIL_REGEX.test(email)) {
      return c.html(
        renderAccountDeletionPage({ error: 'Please enter a valid email address to cancel.' }),
        400
      );
    }

    if (c.env?.DB) {
      await c.env.DB.prepare(
        `UPDATE account_deletions
         SET status = 'cancelled', cancelledAt = ?
         WHERE LOWER(email) = ? AND status IN ('pending_confirmation', 'confirmed')`
      )
        .bind(Date.now(), email)
        .run();
    }

    return c.html(renderAccountDeletionPage({ status: 'cancelled', email }));
  } catch (err: any) {
    return c.html(
      renderAccountDeletionPage({ error: err.message || 'Could not cancel deletion request.' }),
      500
    );
  }
});

// ==========================================
// 4. Mount Modular Subrouters
// ==========================================
app.route('/admin', adminRouter);
app.route('/api/ai', aiRouter);
app.route('/api/sync', syncRouter);
app.route('/api/auth', authRouter);
app.route('/api', authRouter); // Supports POST /api/account/delete

// ==========================================
// 5. Webhooks & Telemetry
// ==========================================
app.post('/api/builds/notify', async (c) => {
  const secret = c.env.BUILD_WEBHOOK_SECRET?.trim();
  if (!secret) {
    return c.json({ error: 'Build webhook is not configured on this server' }, 503);
  }
  const authHeader = c.req.header('Authorization') || '';
  const supplied = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : '';
  if (!supplied || !safeEqual(supplied, secret)) {
    return c.json({ error: 'Unauthorized build notification' }, 401);
  }
  return c.json({ success: true, message: 'Build notification received' });
});

// RevenueCat server-to-server subscription webhook
app.post('/api/webhooks/revenuecat', async (c) => {
  const secret = c.env.REVENUECAT_WEBHOOK_AUTH?.trim();
  if (!secret) {
    return c.json({ error: 'RevenueCat webhook secret not configured' }, 503);
  }
  const authHeader = (c.req.header('Authorization') || '').trim();
  const supplied = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : authHeader;
  if (!supplied || !safeEqual(supplied, secret)) {
    return c.json({ error: 'Unauthorized webhook' }, 401);
  }

  try {
    const body = await c.req.json();
    const event = body?.event;
    const appUserId = String(event?.app_user_id || '').trim();
    const eventType = String(event?.type || '').toUpperCase();
    const expirationMs = event?.expiration_at_ms ? Number(event.expiration_at_ms) : null;

    if (appUserId && c.env?.DB) {
      const grantEvents = new Set([
        'INITIAL_PURCHASE',
        'RENEWAL',
        'UNCANCELLATION',
        'NON_RENEWING_PURCHASE',
        'PRODUCT_CHANGE',
      ]);
      const revokeEvents = new Set(['EXPIRATION', 'BILLING_ISSUE']);

      if (grantEvents.has(eventType)) {
        await c.env.DB.prepare('UPDATE users SET isPro = 1, proExpiresAt = ? WHERE id = ?')
          .bind(expirationMs, appUserId)
          .run();
      } else if (revokeEvents.has(eventType)) {
        await c.env.DB.prepare('UPDATE users SET isPro = 0, proExpiresAt = ? WHERE id = ?')
          .bind(expirationMs, appUserId)
          .run();
      }
    }
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message || 'Webhook processing failed' }, 400);
  }
});

// Redacted crash & telemetry ingestion
const ALLOWED_EVENT_TYPES = new Set(['exception', 'crash', 'action', 'screen_view']);

app.post('/api/telemetry/event', async (c) => {
  try {
    const body = await c.req.json().catch(() => ({}));
    const rawType = String(body.eventType || 'action').toLowerCase();
    const eventType = (ALLOWED_EVENT_TYPES.has(rawType) ? rawType : 'action') as
      | 'exception'
      | 'crash'
      | 'action'
      | 'screen_view';
    const eventName = String(body.eventName || 'unknown_event').slice(0, 120);
    const userId = body.userId ? String(body.userId).slice(0, 120) : null;
    const deviceInfo = body.deviceInfo ? String(body.deviceInfo).slice(0, 120) : null;
    const appVersion = body.appVersion ? String(body.appVersion).slice(0, 40) : null;
    const detailsStr =
      body.details != null
        ? (typeof body.details === 'string' ? body.details : JSON.stringify(body.details)).slice(
            0,
            2000
          )
        : null;

    const now = Date.now();
    const id = `evt_${crypto.randomUUID().replace(/-/g, '').slice(0, 16)}`;

    memoryEvents.unshift({
      id,
      userId,
      eventType,
      eventName,
      details: detailsStr,
      deviceInfo,
      appVersion,
      createdAt: now,
    });
    if (memoryEvents.length > 1000) memoryEvents.length = 1000;

    if (c.env?.DB) {
      await c.env.DB.prepare(
        `INSERT INTO telemetry_events (id, userId, eventType, eventName, details, deviceInfo, appVersion, createdAt)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(id, userId, eventType, eventName, detailsStr, deviceInfo, appVersion, now)
        .run();
    }

    return c.json({ success: true, id });
  } catch {
    return c.json({ success: false }, 400);
  }
});

export default app;
