import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { type Bindings } from './types';
import { firebaseAppCheckMiddleware } from './middleware/app_check';
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

const app = new Hono<{ Bindings: Bindings }>();

// Global middleware
app.use('*', logger());
app.use('*', cors());

// Firebase App Check / Mobile App Integrity Protection
// Ensures only genuine Hyprwise mobile apps can access API routes
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
// Root Landing Page (Admin button is intentionally hidden from public visitors)
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
// 3. Compliance Pages (Google Play Mandate)
// ==========================================
app.get('/privacy', (c) => c.html(renderPrivacyPolicyPage()));
app.get('/privacy-policy', (c) => c.html(renderPrivacyPolicyPage()));

app.get('/terms', (c) => c.html(renderTermsOfServicePage()));
app.get('/terms-of-service', (c) => c.html(renderTermsOfServicePage()));

app.get('/delete-account', (c) => c.html(renderAccountDeletionPage()));
app.get('/account-deletion', (c) => c.html(renderAccountDeletionPage()));

// Handle web account deletion requests
app.post('/delete-account', async (c) => {
  try {
    const body = await c.req.parseBody();
    const email = (body['email'] as string || body['identifier'] as string || '').trim();
    if (!email) {
      return c.html(renderAccountDeletionPage({ error: 'Please enter a valid email address.' }));
    }

    if (c.env?.DB) {
      const token = `del_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
      await c.env.DB.prepare(
        `INSERT INTO account_deletions (id, email, token, status, requestedAt)
         VALUES (?, ?, ?, 'pending_confirmation', ?)`
      )
        .bind(`req_${Date.now()}`, email.toLowerCase(), token, Date.now())
        .run();
    }

    memoryEvents.unshift({
      id: `evt_del_req_${Date.now()}`,
      userId: email,
      eventType: 'action',
      eventName: 'account_deletion_requested',
      details: JSON.stringify({ email }),
      deviceInfo: 'Web Portal',
      appVersion: 'web',
      createdAt: Date.now(),
    });

    return c.html(renderAccountDeletionPage({ status: 'email_sent', email }));
  } catch (err: any) {
    return c.html(renderAccountDeletionPage({ error: err.message || 'Failed to submit request.' }));
  }
});

app.get('/delete-account/confirm', async (c) => {
  const token = (c.req.query('token') || '').trim();
  if (!token) {
    return c.html(renderAccountDeletionPage({ error: 'Invalid or missing confirmation token.' }));
  }

  let email = '';
  if (c.env?.DB) {
    const record = await c.env.DB.prepare('SELECT * FROM account_deletions WHERE token = ?')
      .bind(token)
      .first<any>();
    if (record) {
      email = record.email;
      await c.env.DB.prepare(
        `UPDATE account_deletions SET status = 'confirmed', confirmedAt = ? WHERE id = ?`
      )
        .bind(Date.now(), record.id)
        .run();
    }
  }

  return c.html(renderAccountDeletionPage({ status: 'confirmed', email }));
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
// 5. Build Webhooks & Telemetry
// ==========================================
app.post('/api/builds/notify', async (c) => {
  const authHeader = c.req.header('Authorization');
  const secret = c.env.BUILD_WEBHOOK_SECRET;
  if (secret && authHeader !== `Bearer ${secret}`) {
    return c.json({ error: 'Unauthorized build notification' }, 401);
  }
  return c.json({ success: true, message: 'Build notification received' });
});

app.post('/api/telemetry/event', async (c) => {
  return c.json({ success: true });
});

export default app;
