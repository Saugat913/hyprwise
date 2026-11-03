// Cloud Sync Routes (Pro Feature)

import { Hono } from 'hono';
import { type Bindings } from '../types';
import { resolveUser } from '../middleware/auth';

interface SyncRecordRow {
  userId: string;
  version: number;
  lastSyncedAt: number;
  payload: string;
}

export const syncRouter = new Hono<{ Bindings: Bindings }>();

syncRouter.post('/push', async (c) => {
  try {
    const user = await resolveUser(c);
    if (!user || !user.isPro) {
      return c.json(
        {
          error: 'pro_required',
          feature: 'cloud_sync',
          message: 'Cloud backup and cross-device sync requires an active Hyprwise Pro subscription.',
        },
        403
      );
    }
    const userId = user.id;

    const body = await c.req.json();
    const { data } = body;

    const existing = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
      .bind(userId)
      .first<SyncRecordRow>();
    const newVersion = (existing?.version ?? 0) + 1;
    const now = Date.now();
    const payloadStr = typeof data === 'string' ? data : JSON.stringify(data);

    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO sync_records (userId, version, lastSyncedAt, payload)
       VALUES (?, ?, ?, ?)`
    )
      .bind(userId, newVersion, now, payloadStr)
      .run();

    return c.json({
      success: true,
      version: newVersion,
      syncedAt: now,
      message: 'Cloud sync push successful',
    });
  } catch (e: any) {
    return c.json({ error: e.message || 'Sync push failed' }, 500);
  }
});

syncRouter.get('/pull', async (c) => {
  const user = await resolveUser(c);
  if (!user || !user.isPro) {
    return c.json(
      {
        error: 'pro_required',
        feature: 'cloud_sync',
        message: 'Cloud backup and cross-device sync requires an active Hyprwise Pro subscription.',
      },
      403
    );
  }
  const userId = user.id;

  const record = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
    .bind(userId)
    .first<SyncRecordRow>();
  if (!record) {
    return c.json({
      empty: true,
      data: null,
      message: 'No remote sync data available for this account',
    });
  }

  let parsedPayload: any;
  try {
    parsedPayload = JSON.parse(record.payload);
  } catch {
    parsedPayload = record.payload;
  }

  return c.json({
    empty: false,
    version: record.version,
    lastSyncedAt: record.lastSyncedAt,
    data: parsedPayload,
  });
});

syncRouter.get('/status', async (c) => {
  const user = await resolveUser(c);
  const userId = user?.id || 'default_user';

  const record = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
    .bind(userId)
    .first<SyncRecordRow>();
  return c.json({
    hasData: !!record,
    version: record?.version ?? 0,
    lastSyncedAt: record?.lastSyncedAt ?? null,
  });
});
