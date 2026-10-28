CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  displayName TEXT NOT NULL,
  photoUrl TEXT,
  provider TEXT NOT NULL,
  isPro INTEGER NOT NULL DEFAULT 0,
  proExpiresAt INTEGER,
  dailyAiQueriesCount INTEGER NOT NULL DEFAULT 0,
  lastAiQueryDate TEXT,
  createdAt INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_records (
  userId TEXT PRIMARY KEY,
  version INTEGER NOT NULL DEFAULT 1,
  lastSyncedAt INTEGER NOT NULL,
  payload TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS telemetry_events (
  id TEXT PRIMARY KEY,
  userId TEXT,
  eventType TEXT NOT NULL,
  eventName TEXT NOT NULL,
  details TEXT,
  deviceInfo TEXT,
  appVersion TEXT,
  createdAt INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS account_deletions (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  token TEXT NOT NULL,
  status TEXT NOT NULL,
  reason TEXT,
  requestedAt INTEGER NOT NULL,
  confirmedAt INTEGER,
  scheduledPurgeAt INTEGER NOT NULL,
  cancelledAt INTEGER
);

