// Authentication and Account Management Routes

import { Hono } from 'hono';
import { type Bindings } from '../types';
import {
  resolveUser,
  verifyBearerIdentity,
  computeQuotaSnapshot,
  deterministicUserIdFromEmail,
  getSessionSecret,
} from '../middleware/auth';
import { signSessionToken } from '../middleware/jwt_verify';
import { memoryEvents } from '../compliance_and_admin';

export const authRouter = new Hono<{ Bindings: Bindings }>();

authRouter.post('/firebase', async (c) => {
  try {
    const body = await c.req.json();
    const { displayName, photoUrl, provider, locale, baseCurrency } = body;

    // Cryptographically verify the Firebase ID token from Authorization: Bearer <idToken>
    const verified = await verifyBearerIdentity(c);
    if (!verified && c.env.ALLOW_INSECURE_DEV_AUTH !== 'true') {
      return c.json(
        { error: 'unauthorized', message: 'Valid Google or Apple Firebase ID token is required.' },
        401
      );
    }

    const rawProvider = String(verified?.provider || provider || '').toLowerCase();
    if (rawProvider === 'guest' || rawProvider === 'anonymous') {
      return c.json(
        { error: 'guest_not_allowed', message: 'Guest accounts are disabled. Please sign in with Google or Apple.' },
        403
      );
    }
    const normalizedProvider = rawProvider.includes('apple') ? 'apple' : 'google';

    const uid = verified?.uid || String(body.uid || '').trim();
    const rawEmail = verified?.email || String(body.email || '').trim();
    if (!rawEmail || rawEmail.toLowerCase().startsWith('guest@')) {
      return c.json(
        { error: 'invalid_account', message: 'A verified Google or Apple account email is required.' },
        400
      );
    }
    const emailStr = rawEmail.trim().toLowerCase();

    const existingById = uid
      ? await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first<any>()
      : null;
    const existingByEmail = !existingById
      ? await c.env.DB.prepare('SELECT * FROM users WHERE LOWER(email) = ?')
          .bind(emailStr)
          .first<any>()
      : null;
    const existing = existingById || existingByEmail;
    const isNewUser = !existing;

    const deterministicId = deterministicUserIdFromEmail(
      emailStr,
      normalizedProvider === 'apple' ? 'usr_a_' : 'usr_g_'
    );
    const finalUserId = existing?.id || (uid && uid.length > 5 ? uid : deterministicId);

    const user = {
      id: finalUserId,
      email: emailStr,
      displayName:
        displayName || verified?.name || existing?.displayName || emailStr.split('@')[0],
      photoUrl: photoUrl || verified?.picture || existing?.photoUrl || null,
      provider: normalizedProvider,
      isPro: existing?.isPro ?? 0,
      proExpiresAt: existing?.proExpiresAt ?? null,
      dailyAiQueriesCount: existing?.dailyAiQueriesCount ?? 0,
      lastAiQueryDate: existing?.lastAiQueryDate ?? null,
      createdAt: existing?.createdAt ?? Date.now(),
    };

    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO users (id, email, displayName, photoUrl, provider, isPro, proExpiresAt, dailyAiQueriesCount, lastAiQueryDate, createdAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        user.id,
        user.email,
        user.displayName,
        user.photoUrl,
        user.provider,
        user.isPro,
        user.proExpiresAt,
        user.dailyAiQueriesCount,
        user.lastAiQueryDate,
        user.createdAt
      )
      .run();

    // Auto-initialize user preferences table if needed
    try {
      await c.env.DB.prepare(`
        CREATE TABLE IF NOT EXISTS user_preferences (
          userId TEXT PRIMARY KEY,
          locale TEXT,
          baseCurrency TEXT,
          onboarded INTEGER DEFAULT 1,
          updatedAt INTEGER
        )
      `).run();
    } catch (_) {}

    let prefs: any = null;
    try {
      prefs = await c.env.DB.prepare('SELECT * FROM user_preferences WHERE userId = ?')
        .bind(finalUserId)
        .first<any>();
    } catch (_) {}

    if (!prefs && (locale || baseCurrency)) {
      try {
        await c.env.DB.prepare(`
          INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
          VALUES (?, ?, ?, 1, ?)
        `)
          .bind(finalUserId, locale || null, baseCurrency || null, Date.now())
          .run();

        prefs = await c.env.DB.prepare('SELECT * FROM user_preferences WHERE userId = ?')
          .bind(finalUserId)
          .first<any>();
      } catch (_) {}
    }

    const quota = computeQuotaSnapshot(user as any);
    const sessionToken = await signSessionToken(
      { uid: user.id, email: user.email },
      getSessionSecret(c.env)
    );

    return c.json({
      success: true,
      token: sessionToken,
      isNewUser,
      preferences: prefs
        ? {
            locale: prefs.locale,
            baseCurrency: prefs.baseCurrency,
            onboarded: Boolean(prefs.onboarded),
          }
        : isNewUser
        ? null
        : { onboarded: true },
      user: {
        ...user,
        isPro: quota.activePro,
        dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
        dailyAiQueriesLeft: quota.dailyAiQueriesLeft,
      },
    });
  } catch (e: any) {
    return c.json({ error: e.message || 'Authentication failed' }, 500);
  }
});

authRouter.post('/preferences', async (c) => {
  try {
    const user = await resolveUser(c, false, true);
    if (!user) {
      return c.json({ error: 'Unauthorized' }, 401);
    }

    const body = await c.req.json().catch(() => ({}));
    const locale = typeof body.locale === 'string' ? body.locale.slice(0, 10) : null;
    const baseCurrency =
      typeof body.baseCurrency === 'string' ? body.baseCurrency.slice(0, 6).toUpperCase() : null;

    try {
      await c.env.DB.prepare(`
        CREATE TABLE IF NOT EXISTS user_preferences (
          userId TEXT PRIMARY KEY,
          locale TEXT,
          baseCurrency TEXT,
          onboarded INTEGER DEFAULT 1,
          updatedAt INTEGER
        )
      `).run();
    } catch (_) {}

    await c.env.DB.prepare(`
      INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
      VALUES (?, ?, ?, 1, ?)
      ON CONFLICT(userId) DO UPDATE SET
        locale = COALESCE(excluded.locale, user_preferences.locale),
        baseCurrency = COALESCE(excluded.baseCurrency, user_preferences.baseCurrency),
        onboarded = 1,
        updatedAt = excluded.updatedAt
    `)
      .bind(user.id, locale, baseCurrency, Date.now())
      .run();

    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message || 'Failed to update preferences' }, 500);
  }
});

authRouter.get('/profile', async (c) => {
  const user = await resolveUser(c, true, true);
  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401);
  }
  const quota = computeQuotaSnapshot(user);
  return c.json({
    user: {
      ...user,
      isPro: quota.activePro,
      dailyAiQueriesUsed: quota.dailyAiQueriesUsed,
      dailyAiQueriesLeft: quota.dailyAiQueriesLeft,
    },
  });
});

// Authenticated permanent account deletion (Apple Guideline 5.1.1(v) & Google Play Data Safety)
// Strictly scoped to the verified authenticated caller — never accepts arbitrary target userId/email.
authRouter.post('/account/delete', async (c) => {
  try {
    const user = await resolveUser(c, false, true);
    if (!user) {
      return c.json(
        { error: 'unauthorized', message: 'Verified authentication is required to delete your account.' },
        401
      );
    }

    const targetId = user.id;
    const targetEmail = user.email.toLowerCase();

    if (c.env?.DB) {
      await c.env.DB.prepare('DELETE FROM sync_records WHERE userId = ?').bind(targetId).run();
      await c.env.DB.prepare('DELETE FROM user_preferences WHERE userId = ?').bind(targetId).run();
      await c.env.DB.prepare('DELETE FROM telemetry_events WHERE userId = ?').bind(targetId).run();
      await c.env.DB.prepare('DELETE FROM account_deletions WHERE LOWER(email) = ?')
        .bind(targetEmail)
        .run();
      await c.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(targetId).run();
    }

    memoryEvents.unshift({
      id: `evt_acc_del_${Date.now()}`,
      userId: targetId,
      eventType: 'action',
      eventName: 'account_purged_via_api',
      details: JSON.stringify({ status: 'purged' }),
      deviceInfo: 'App API',
      appVersion: 'api',
      createdAt: Date.now(),
    });
    if (memoryEvents.length > 1000) memoryEvents.length = 1000;

    return c.json({
      success: true,
      message: 'Account, credentials, preferences, telemetry, and cloud backups have been purged permanently.',
    });
  } catch (e: any) {
    return c.json({ error: e.message || 'Deletion failed' }, 500);
  }
});
