// Authentication and Account Management Routes

import { Hono } from 'hono';
import { type Bindings } from '../types';
import { resolveUser, computeQuotaSnapshot, deterministicUserIdFromEmail } from '../middleware/auth';
import { memoryEvents } from '../compliance_and_admin';

export const authRouter = new Hono<{ Bindings: Bindings }>();

authRouter.post('/firebase', async (c) => {
  try {
    const body = await c.req.json();
    const { uid, email, displayName, photoUrl, provider } = body;

    const emailStr = String(email || `${uid || 'user'}@hyprwise.local`).trim().toLowerCase();
    const existingByEmail = await c.env.DB.prepare('SELECT * FROM users WHERE LOWER(email) = ?')
      .bind(emailStr)
      .first<any>();
    const existingById = uid
      ? await c.env.DB.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first<any>()
      : null;
    const existing = existingByEmail || existingById;

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

    const quota = computeQuotaSnapshot(user as any);

    return c.json({
      success: true,
      token: `tok_${finalUserId}_${Date.now()}`,
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
