// Shared interfaces and types for Hyprwise Cloudflare Workers Server

export interface Bindings {
  DB: D1Database;
  GEMINI_API_KEY?: string;
  FIREBASE_PROJECT_ID?: string;
  FIREBASE_CLIENT_EMAIL?: string;
  GOOGLE_PROJECT_ID?: string;
  GOOGLE_PROJECT_NUMBER?: string;
  REVENUECAT_SECRET_KEY?: string;
  REVENUECAT_WEBHOOK_AUTH?: string;
  DISCORD_WEBHOOK_URL?: string;
  BUILD_WEBHOOK_SECRET?: string;
  ADMIN_PASSWORD?: string;
  ADMIN_AUTH_TOKEN?: string;
  SESSION_SECRET?: string;
  ALLOWED_ORIGINS?: string;
  ENFORCE_APP_CHECK?: string; // 'true' to strictly enforce App Check in production
  ALLOW_INSECURE_DEV_AUTH?: string; // Only for local offline dev tests; unset/false in prod
  GA4_PROPERTY_ID?: string;   // Google Analytics 4 Property ID for Analytics Data API
}

export interface UserRecord {
  id: string;
  email: string;
  displayName: string;
  photoUrl?: string | null;
  provider: string;
  isPro: number | boolean;
  proExpiresAt?: number | string | null;
  dailyAiQueriesCount: number;
  lastAiQueryDate: string | null;
  createdAt: number | string;
}

export interface TelemetryEvent {
  id: string;
  userId?: string | null;
  eventType: 'exception' | 'crash' | 'action' | 'screen_view';
  eventName: string;
  details?: any;
  deviceInfo?: string | null;
  appVersion?: string | null;
  timestamp: string;
  edgeRegion?: string | null;
}

export interface QuotaSnapshot {
  todayStr: string;
  activePro: boolean;
  dailyAiQueriesUsed: number;
  dailyAiQueriesLeft: number;
  limitReached: boolean;
}
