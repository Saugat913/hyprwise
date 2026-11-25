// Firebase App Check / App Integrity Middleware for Hyprwise Backend
// Verifies RS256 signatures against Google's official Firebase App Check JWKS.

import { type Context, type Next } from 'hono';
import { type Bindings } from '../types';
import { verifyAppCheckToken } from './jwt_verify';

export async function firebaseAppCheckMiddleware(
  c: Context<{ Bindings: Bindings }>,
  next: Next
) {
  const path = c.req.path;

  // Exempt public pages, webhooks, and health check from App Check requirement
  if (
    path === '/' ||
    path === '/health' ||
    path.startsWith('/admin') ||
    path.startsWith('/privacy') ||
    path.startsWith('/terms') ||
    path.startsWith('/delete-account') ||
    path.startsWith('/api/webhooks') ||
    path.startsWith('/api/builds')
  ) {
    return next();
  }

  const appCheckToken = c.req.header('X-Firebase-AppCheck')?.trim();
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
    c.header('X-AppCheck-Status', 'unverified_missing');
    return next();
  }

  const verified = await verifyAppCheckToken(
    appCheckToken,
    c.env.GOOGLE_PROJECT_NUMBER,
    c.env.FIREBASE_PROJECT_ID
  );

  if (!verified) {
    if (enforceAppCheck) {
      return c.json(
        {
          error: 'app_integrity_invalid',
          message:
            'Firebase App Check token signature or claims could not be verified. Please refresh through the mobile app.',
        },
        401
      );
    }
    c.header('X-AppCheck-Status', 'unverified_invalid');
    return next();
  }

  c.header('X-AppCheck-Status', 'verified');
  return next();
}
