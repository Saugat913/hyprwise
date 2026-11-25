// Cloud Sync Routes (Pro Feature — Strictly Authenticated)

import { Hono } from 'hono';
import { type Bindings } from '../types';
import { resolveUser, computeQuotaSnapshot } from '../middleware/auth';

interface SyncRecordRow {
  userId: string;
  version: number;
  lastSyncedAt: number;
  payload: string;
}

const MAX_SYNC_PAYLOAD_BYTES = 5 * 1024 * 1024; // 5 MB safety limit

export const syncRouter = new Hono<{ Bindings: Bindings }>();

syncRouter.post('/push', async (c) => {
  try {
    const user = await resolveUser(c, false, true);
    if (!user) {
      return c.json({ error: 'unauthorized', message: 'Authentication required.' }, 401);
    }
    const quota = computeQuotaSnapshot(user);
    if (!quota.activePro) {
      return c.json(
        {
          error: 'pro_required',
          feature: 'cloud_sync',
          message: 'Cloud backup and cross-device sync requires an active Hyprwise Pro subscription.',
        },
        403
      );
    }

    const body = await c.req.json();
    const { data } = body;
    if (data === undefined || data === null) {
      return c.json({ error: 'invalid_payload', message: 'Missing sync data.' }, 400);
    }

    const payloadStr = typeof data === 'string' ? data : JSON.stringify(data);
    if (new TextEncoder().encode(payloadStr).byteLength > MAX_SYNC_PAYLOAD_BYTES) {
      return c.json({ error: 'payload_too_large', message: 'Sync payload exceeds 5 MB limit.' }, 413);
    }

    const existing = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
      .bind(user.id)
      .first<SyncRecordRow>();
    const newVersion = (existing?.version ?? 0) + 1;
    const now = Date.now();

    await c.env.DB.prepare(
      `INSERT OR REPLACE INTO sync_records (userId, version, lastSyncedAt, payload)
       VALUES (?, ?, ?, ?)`
    )
      .bind(user.id, newVersion, now, payloadStr)
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
  const user = await resolveUser(c, false, true);
  if (!user) {
    return c.json({ error: 'unauthorized', message: 'Authentication required.' }, 401);
  }
  const quota = computeQuotaSnapshot(user);
  if (!quota.activePro) {
    return c.json(
      {
        error: 'pro_required',
        feature: 'cloud_sync',
        message: 'Cloud backup and cross-device sync requires an active Hyprwise Pro subscription.',
      },
      403
    );
  }

  const record = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
    .bind(user.id)
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
  const user = await resolveUser(c, false, true);
  if (!user) {
    return c.json({ error: 'unauthorized', message: 'Authentication required.' }, 401);
  }

  const record = await c.env.DB.prepare('SELECT * FROM sync_records WHERE userId = ?')
    .bind(user.id)
    .first<SyncRecordRow>();
  return c.json({
    hasData: !!record,
    version: record?.version ?? 0,
    lastSyncedAt: record?.lastSyncedAt ?? null,
  });
});
