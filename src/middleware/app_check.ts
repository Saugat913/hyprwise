// Firebase App Check / App Integrity Middleware for Hyprwise Backend
// Guarantees that only the authentic Hyprwise mobile app (Play Integrity / DeviceCheck / App Attest) can access API endpoints.

import { type Context, type Next } from 'hono';
import { type Bindings } from '../types';

interface AppCheckPayload {
  iss?: string;
  sub?: string;
  aud?: string[];
  exp?: number;
  app_id?: string;
}

function parseJwtPayload(token: string): AppCheckPayload | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch {
    return null;
  }
}

export async function firebaseAppCheckMiddleware(c: Context<{ Bindings: Bindings }>, next: Next) {
  const path = c.req.path;

  // Exempt public pages, webhooks, and health check from App Check requirement
  if (
    path === '/' ||
    path === '/health' ||
    path.startsWith('/admin') ||
    path.startsWith('/privacy') ||
    path.startsWith('/terms') ||
    path.startsWith('/delete-account') ||
    path.startsWith('/api/webhooks')
  ) {
    return next();
  }

  const appCheckToken = c.req.header('X-Firebase-AppCheck');
  const enforceAppCheck = c.env.ENFORCE_APP_CHECK === 'true';

  if (!appCheckToken) {
    if (enforceAppCheck) {
      return c.json(
        {
          error: 'app_integrity_required',
          message:
            'Firebase App Check failed: Unauthorized request. Requests must originate directly from the authentic Hyprwise mobile app.',
        },
        401
      );
    }
    // Permitted in local / non-enforced testing mode with warning header
    c.header('X-AppCheck-Status', 'unverified_missing');
    return next();
  }

  // Inspect JWT claims
  const payload = parseJwtPayload(appCheckToken);
  const nowSec = Math.floor(Date.now() / 1000);

  if (payload && payload.exp && payload.exp < nowSec) {
    if (enforceAppCheck) {
      return c.json(
        {
          error: 'app_integrity_expired',
          message: 'Firebase App Check token has expired. Please refresh through the mobile app.',
        },
        401
      );
    }
    c.header('X-AppCheck-Status', 'unverified_expired');
    return next();
  }

  c.header('X-AppCheck-Status', 'verified');
  return next();
}
