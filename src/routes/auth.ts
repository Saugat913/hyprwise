// Authentication and Account Management Routes

import { Hono } from 'hono';
import { type Bindings } from '../types';
import { resolveUser, computeQuotaSnapshot, deterministicUserIdFromEmail } from '../middleware/auth';
import { memoryEvents } from '../compliance_and_admin';

export const authRouter = new Hono<{ Bindings: Bindings }>();

authRouter.post('/firebase', async (c) => {
  try {
    const body = await c.req.json();
    const { uid, email, displayName, photoUrl, provider, locale, baseCurrency } = body;

    const emailStr = String(email || `${uid || 'user'}@hyprwise.local`).trim().toLowerCase();
    const existingByEmail = await c.env.DB.prepare('SELECT * FROM users WHERE LOWER(email) = ?')
      .bind(emailStr)
      .first<any>();
    const existingById = uid
      ? await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first<any>()
      : null;
    const existing = existingByEmail || existingById;
    const isNewUser = !existing;

    const deterministicId = deterministicUserIdFromEmail(emailStr, provider === 'apple' ? 'usr_a_' : 'usr_g_');
    const finalUserId = existing?.id || (uid && uid.length > 5 ? uid : deterministicId);

    const user = {
      id: finalUserId,
      email: emailStr,
      displayName: displayName || existing?.displayName || emailStr.split('@')[0],
      photoUrl: photoUrl || existing?.photoUrl || null,
      provider: provider || 'google',
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

    // Update preferences if client provided them
    if (locale || baseCurrency) {
      try {
        await c.env.DB.prepare(`
          INSERT INTO user_preferences (userId, locale, baseCurrency, onboarded, updatedAt)
          VALUES (?, ?, ?, 1, ?)
          ON CONFLICT(userId) DO UPDATE SET
            locale = COALESCE(excluded.locale, user_preferences.locale),
            baseCurrency = COALESCE(excluded.baseCurrency, user_preferences.baseCurrency),
            onboarded = 1,
            updatedAt = excluded.updatedAt
        `).bind(finalUserId, locale || null, baseCurrency || null, Date.now()).run();
      } catch (_) {}
    }

    let prefs: any = null;
    try {
      prefs = await c.env.DB.prepare('SELECT * FROM user_preferences WHERE userId = ?')
        .bind(finalUserId)
        .first<any>();
    } catch (_) {}

    const quota = computeQuotaSnapshot(user as any);

    return c.json({
      success: true,
      token: `tok_${finalUserId}_${Date.now()}`,
      isNewUser,
      preferences: prefs ? {
        locale: prefs.locale,
        baseCurrency: prefs.baseCurrency,
        onboarded: Boolean(prefs.onboarded),
      } : (isNewUser ? null : { onboarded: true }),
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
    const user = await resolveUser(c);
    if (!user) {
      return c.json({ error: 'Unauthorized' }, 401);
    }
    const body = await c.req.json();
    const { locale, baseCurrency } = body;

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
    `).bind(user.id, locale || null, baseCurrency || null, Date.now()).run();

    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message || 'Failed to update preferences' }, 500);
  }
});

authRouter.get('/profile', async (c) => {
  const user = await resolveUser(c, true);
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

authRouter.post('/account/delete', async (c) => {
  try {
    const user = await resolveUser(c);
    let targetId = user?.id;
    let targetEmail = user?.email;

    try {
      const body = await c.req.json();
      if (body.userId) targetId = body.userId;
      if (body.email) targetEmail = body.email;
    } catch (_) {}

    if (!targetId && !targetEmail) {
      return c.json({ error: 'User identification required' }, 400);
    }

    if (c.env?.DB) {
      if (targetId) {
        await c.env.DB.prepare('DELETE FROM sync_records WHERE userId = ?').bind(targetId).run();
        await c.env.DB.prepare('DELETE FROM users WHERE id = ?').bind(targetId).run();
      }
      if (targetEmail) {
        await c.env.DB.prepare('DELETE FROM users WHERE LOWER(email) = ?').bind(targetEmail.toLowerCase()).run();
      }
    }

    memoryEvents.unshift({
      id: `evt_acc_del_${Date.now()}`,
      userId: targetId || targetEmail,
      eventType: 'action',
      eventName: 'account_purged_via_api',
      details: JSON.stringify({ targetId, targetEmail }),
      deviceInfo: 'App API',
      appVersion: 'api',
      createdAt: Date.now(),
    });

    return c.json({
      success: true,
      message: 'Account, credentials, and associated cloud backups have been purged permanently.',
    });
  } catch (e: any) {
    return c.json({ error: e.message || 'Deletion failed' }, 500);
  }
});
