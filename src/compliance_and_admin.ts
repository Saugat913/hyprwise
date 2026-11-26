// Compliance pages & shared security/HTML utilities for Hyprwise Edge Server.
// Public UI strictly contains NO admin links, icons, or buttons (admin is path-only at /admin).

import { getHyprwiseIconSvg } from './brand_assets';
import { type Bindings } from './types';

export function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export interface TelemetryEvent {
  id: string;
  userId?: string | null;
  eventType: 'exception' | 'crash' | 'action' | 'screen_view';
  eventName: string;
  details?: string | null;
  deviceInfo?: string | null;
  appVersion?: string | null;
  createdAt: number;
}

// In-memory telemetry ring buffer (preserves last 1,000 events across edge isolate life)
export const memoryEvents: TelemetryEvent[] = [];

export const ADMIN_COOKIE_NAME = 'hyprwise_admin_session';
export const DEFAULT_DEV_ADMIN_PASSWORD = 'P@ssword123';
const DEFAULT_DEV_ADMIN_TOKEN = 'hypr_adm_token_p92817x8';

export function getAdminPassword(env?: Partial<Bindings>): string {
  return (env?.ADMIN_PASSWORD && env.ADMIN_PASSWORD.trim()) || DEFAULT_DEV_ADMIN_PASSWORD;
}

export function isUsingDefaultAdminPassword(env?: Partial<Bindings>): boolean {
  return !(env?.ADMIN_PASSWORD && env.ADMIN_PASSWORD.trim() && env.ADMIN_PASSWORD.trim() !== DEFAULT_DEV_ADMIN_PASSWORD);
}

export function getAdminAuthToken(env?: Partial<Bindings>): string {
  return (env?.ADMIN_AUTH_TOKEN && env.ADMIN_AUTH_TOKEN.trim()) || DEFAULT_DEV_ADMIN_TOKEN;
}

// Shared Hyprwise Design System CSS Tokens (exact parity with Flutter AppPalette WCAG AA)
export const HYPRWISE_SHARED_CSS = `
  :root {
    --bg: #F6F6F6;
    --surface: #FFFFFF;
    --hero: #141417;
    --ink: #0F0F11;
    --muted: #59615D;
    --border: #E6E8E7;
    --fill: #EDEEED;
    --brand: #FF6500;
    --brand-text: #B84400;
    --brand-bg: #FFF0E6;
    --green: #1F7A45;
    --green-bg: #E3F3EA;
    --red: #B42318;
    --red-bg: #FDECEB;
    --amber: #9A5B00;
    --amber-bg: #FFF1D6;
    --radius: 12px;
    --radius-sm: 8px;
    --font: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, monospace;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background-color: var(--bg);
    color: var(--ink);
    font-family: var(--font);
    line-height: 1.6;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    -webkit-font-smoothing: antialiased;
  }
`;

// Public HTML Wrapper (Hyprwise WCAG AA Palette, 12px radius, ZERO admin links/icons)
export function wrapHtml({
  title,
  bodyContent,
  activeNav = '',
}: {
  title: string;
  bodyContent: string;
  activeNav?: '' | 'privacy' | 'terms' | 'delete';
}): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)} | Hyprwise</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    ${HYPRWISE_SHARED_CSS}
    header {
      background: rgba(255, 255, 255, 0.94);
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .nav-container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: var(--ink);
      font-weight: 800;
      font-size: 1.2rem;
      letter-spacing: -0.03em;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 4px;
    }
    .nav-link {
      color: var(--muted);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 600;
      padding: 7px 12px;
      border-radius: var(--radius-sm);
      transition: background 0.15s ease, color 0.15s ease;
    }
    .nav-link:hover {
      color: var(--ink);
      background: var(--fill);
    }
    .nav-link.active {
      color: var(--ink);
      background: var(--fill);
    }
    main {
      flex: 1;
      max-width: 920px;
      width: 100%;
      margin: 0 auto;
      padding: 36px 24px 68px;
    }
    .content-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 32px;
    }
    .nav-card {
      text-decoration: none;
      display: block;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 22px;
      transition: border-color 0.15s ease, transform 0.15s ease;
    }
    .nav-card:hover {
      border-color: var(--ink);
      transform: translateY(-1px);
    }
    h1 {
      font-size: 2rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 8px;
      color: var(--ink);
    }
    .subtitle {
      color: var(--muted);
      font-size: 0.9375rem;
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .section-eyebrow {
      color: var(--brand-text);
      font-size: 0.72rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      margin-bottom: 6px;
      display: block;
    }
    h2 {
      font-size: 1.2rem;
      font-weight: 700;
      margin: 28px 0 10px;
      color: var(--ink);
      letter-spacing: -0.015em;
    }
    h3 {
      font-size: 1rem;
      font-weight: 700;
      margin: 16px 0 8px;
      color: var(--ink);
    }
    p, ul {
      color: var(--muted);
      font-size: 0.9375rem;
      margin-bottom: 14px;
      line-height: 1.7;
    }
    ul { padding-left: 20px; }
    li { margin-bottom: 6px; }
    strong { color: var(--ink); font-weight: 600; }
    code {
      font-family: var(--font-mono);
      background: var(--fill);
      padding: 2px 6px;
      border-radius: 6px;
      font-size: 0.85em;
      color: var(--ink);
      border: 1px solid var(--border);
    }
    .callout {
      background: var(--fill);
      border: 1px solid var(--border);
      border-left: 3px solid var(--ink);
      border-radius: var(--radius-sm);
      padding: 14px 18px;
      margin: 20px 0;
    }
    .callout p { margin: 0; color: var(--ink); font-size: 0.9rem; }
    .callout-success { border-left-color: var(--green); background: var(--green-bg); border-color: #BFE6CE; }
    .callout-warning { border-left-color: var(--amber); background: var(--amber-bg); border-color: #F3DBA8; }
    .callout-danger { border-left-color: var(--red); background: var(--red-bg); border-color: #F5C2BE; }
    .data-table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      margin: 16px 0 22px;
    }
    table.flat-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 0.875rem; }
    table.flat-table th {
      background: var(--fill);
      color: var(--ink);
      font-weight: 700;
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    table.flat-table td {
      padding: 12px 14px;
      border-bottom: 1px solid var(--border);
      color: var(--muted);
    }
    table.flat-table tr:last-child td { border-bottom: none; }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 18px;
      border-radius: var(--radius);
      font-weight: 700;
      font-size: 0.875rem;
      text-decoration: none;
      cursor: pointer;
      border: 1px solid transparent;
      transition: background 0.15s ease, border-color 0.15s ease;
    }
    .btn-primary { background: var(--ink); color: #FFFFFF; }
    .btn-primary:hover { background: #262629; }
    .btn-danger { background: var(--red); color: #FFFFFF; }
    .btn-danger:hover { background: #961D14; }
    .btn-outline { background: var(--surface); border-color: var(--border); color: var(--ink); }
    .btn-outline:hover { background: var(--fill); }
    .form-group { margin-bottom: 16px; }
    label {
      display: block;
      margin-bottom: 6px;
      font-size: 0.825rem;
      font-weight: 700;
      color: var(--ink);
    }
    input, select, textarea {
      width: 100%;
      padding: 10px 14px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      color: var(--ink);
      font-family: inherit;
      font-size: 0.9rem;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--ink);
      box-shadow: 0 0 0 3px rgba(15, 15, 17, 0.10);
    }
    .alert {
      padding: 14px 18px;
      border-radius: var(--radius);
      margin-bottom: 20px;
      font-size: 0.875rem;
      line-height: 1.55;
    }
    .alert-success { background: var(--green-bg); border: 1px solid #BFE6CE; color: var(--green); }
    .alert-error { background: var(--red-bg); border: 1px solid #F5C2BE; color: var(--red); }
    .status-dot {
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--green);
      margin-right: 6px;
    }
    footer {
      border-top: 1px solid var(--border);
      padding: 26px 24px;
      background: var(--surface);
      margin-top: auto;
    }
    .footer-container {
      max-width: 1000px;
      margin: 0 auto;
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: 14px;
      color: var(--muted);
      font-size: 0.825rem;
    }
    .footer-links { display: flex; gap: 18px; flex-wrap: wrap; }
    .footer-links a { color: var(--muted); text-decoration: none; font-weight: 500; }
    .footer-links a:hover { color: var(--ink); }
    @media (max-width: 640px) {
      .content-card { padding: 22px 18px; }
      h1 { font-size: 1.65rem; }
      .nav-link { font-size: 0.8rem; padding: 6px 9px; }
    }
  </style>
</head>
<body>
  <header>
    <div class="nav-container">
      <a href="/" class="logo">
        ${getHyprwiseIconSvg(28)}
        <span>hyprwise</span>
      </a>
      <nav class="nav-links" aria-label="Primary">
        <a href="/privacy" class="nav-link ${activeNav === 'privacy' ? 'active' : ''}">Privacy</a>
        <a href="/terms" class="nav-link ${activeNav === 'terms' ? 'active' : ''}">Terms</a>
        <a href="/delete-account" class="nav-link ${activeNav === 'delete' ? 'active' : ''}">Delete Account</a>
      </nav>
    </div>
  </header>
  <main>
    ${bodyContent}
  </main>
  <footer>
    <div class="footer-container">
      <div>© 2026 Hyprwise · <code>com.hypr.hyprwise</code></div>
      <div class="footer-links">
        <a href="/privacy">Privacy Policy</a>
        <a href="/terms">Terms of Service</a>
        <a href="/delete-account">Account Deletion</a>
        <a href="/health">Status</a>
      </div>
    </div>
  </footer>
</body>
</html>`;
}

// 1. Privacy Policy Page
export function renderPrivacyPolicyPage(): string {
  const content = `
    <div class="content-card">
      <span class="section-eyebrow">Google Play &amp; Apple Data Safety</span>
      <h1>Hyprwise Privacy Policy</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: November 26, 2026 · Version 1.4.0</p>

      <div class="callout callout-success">
        <p><strong>Core Privacy Guarantee:</strong> Hyprwise is engineered local-first. Your financial logs, hourly shift rates, bank accounts, and budgets live in an on-device SQLite database via Drift. We never sell, monetize, or broker your personal financial records to third-party advertisers.</p>
      </div>

      <h2>1. Overview &amp; Scope</h2>
      <p>
        This Privacy Policy outlines how Hyprwise ("we", "our", or "the App", Android &amp; iOS Application ID: <code>com.hypr.hyprwise</code>) collects, handles, stores, and protects user information across mobile platforms and edge server infrastructure.
      </p>

      <h2>2. Data Collection &amp; Processing Architecture</h2>
      <div class="data-table-container">
        <table class="flat-table">
          <thead>
            <tr>
              <th>Data Category</th>
              <th>Storage Location</th>
              <th>Security Controls</th>
              <th>Purpose</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Financial Accounts &amp; Shifts</strong></td>
              <td>On-device local SQLite (Drift)</td>
              <td>OS app sandbox encryption</td>
              <td>Shift wage tracking, dual-currency budgeting, balance forecasting</td>
            </tr>
            <tr>
              <td><strong>Authentication Profile</strong></td>
              <td>Firebase Auth &amp; Edge D1</td>
              <td>TLS 1.3 &amp; RS256 JWKS / HMAC-SHA256 verification</td>
              <td>Cross-device sync and Pro subscription restoration</td>
            </tr>
            <tr>
              <td><strong>Optional Cloud Backups</strong></td>
              <td>Cloudflare D1 (Pro opt-in)</td>
              <td>Verified token isolation over HTTPS</td>
              <td>Disaster recovery &amp; multi-device backup</td>
            </tr>
            <tr>
              <td><strong>Receipt OCR Scans</strong></td>
              <td>Transient memory buffer</td>
              <td>Ephemeral single-request inference</td>
              <td>Gemini 2.5 Flash receipt extraction (not retained)</td>
            </tr>
            <tr>
              <td><strong>Redacted Diagnostics</strong></td>
              <td>Hyprwise Edge Telemetry</td>
              <td>Sensitive fields redacted, zero secrets</td>
              <td>Unhandled crash capture and reliability fixes</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h2>3. AI Assistant &amp; Receipt Scanning Protocol</h2>
      <ul>
        <li><strong>Zero Training Retention:</strong> Receipt images and prompt transcripts sent to the AI proxy are never used to train public machine learning models.</li>
        <li><strong>Strict Financial Boundary:</strong> The AI assistant is restricted exclusively to personal financial records and shift scheduling.</li>
        <li><strong>Local Confirmation:</strong> Financial actions generated by AI execute directly against your local Drift database with explicit confirmation cards.</li>
      </ul>

      <h2>4. Third-Party Infrastructure Providers</h2>
      <ul>
        <li><strong>Google Firebase (Authentication &amp; App Check):</strong> Handles federated Google/Apple sign-in and device integrity verification.</li>
        <li><strong>Google Gemini 2.5 Flash:</strong> Powers bill OCR scanning and financial reasoning.</li>
        <li><strong>RevenueCat, Google Play Billing &amp; Apple IAP:</strong> Manages Hyprwise Pro subscriptions; payment cards are never visible to Hyprwise.</li>
        <li><strong>Cloudflare Workers &amp; D1:</strong> Edge infrastructure hosting API endpoints, legal portals, and optional Pro sync records.</li>
      </ul>

      <h2>5. User Rights &amp; Account Deletion</h2>
      <div class="callout callout-warning">
        <p><strong>Deletion Options:</strong> You may permanently delete your account immediately inside the app (<em>Settings → Danger Zone → Delete Account</em>) or submit a web deletion request at <a href="/delete-account" style="color: var(--ink); font-weight: 700;">/delete-account</a> with a 30-day cancellable grace period.</p>
      </div>

      <h2>6. Contact &amp; Privacy Officer</h2>
      <p>
        For privacy inquiries or data safety requests: <code>privacy@hyprwise.app</code>
      </p>
    </div>
  `;
  return wrapHtml({ title: 'Privacy Policy', bodyContent: content, activeNav: 'privacy' });
}

// 2. Terms of Service Page
export function renderTermsOfServicePage(): string {
  const content = `
    <div class="content-card">
      <span class="section-eyebrow">Legal Terms</span>
      <h1>Hyprwise Terms of Service</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: November 26, 2026 · Version 1.4.0</p>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By creating an account, downloading, or using Hyprwise (<code>com.hypr.hyprwise</code>), you agree to these Terms of Service.
      </p>

      <h2>2. Financial Information Disclaimer</h2>
      <div class="callout">
        <p><strong>Informational Tool Only:</strong> Hyprwise assists with personal budgeting, shift wage estimation, and multi-currency tracking. It does not provide formal financial, investment, tax, or legal advice.</p>
      </div>

      <h2>3. Subscriptions &amp; Billing (Hyprwise Pro)</h2>
      <ul>
        <li><strong>Billing Cycle:</strong> Recurring subscriptions renew automatically unless cancelled at least 24 hours before period end via Google Play or Apple App Store settings.</li>
        <li><strong>Refunds:</strong> Managed according to Google Play or Apple App Store policies.</li>
      </ul>

      <h2>4. Acceptable Use</h2>
      <p>You agree not to abuse, reverse engineer, or attempt unauthorized access against Hyprwise edge infrastructure or other users' records.</p>

      <h2>5. Termination &amp; Data Deletion</h2>
      <p>You may delete your account anytime in-app or via <a href="/delete-account" style="color: var(--ink); font-weight: 700;">/delete-account</a>.</p>

      <h2>6. Legal Contact</h2>
      <p>Questions regarding these terms: <code>legal@hyprwise.app</code></p>
    </div>
  `;
  return wrapHtml({ title: 'Terms of Service', bodyContent: content, activeNav: 'terms' });
}

// 3. Account Deletion Portal
export function renderAccountDeletionPage(opts?: {
  status?: 'email_sent' | 'confirmed' | 'cancelled';
  error?: string;
  email?: string;
  scheduledPurgeDate?: string;
  token?: string;
}): string {
  const content = `
    <div class="content-card">
      <span class="section-eyebrow" style="color: var(--red);">Google Play &amp; Apple Data Safety Portal</span>
      <h1>Account &amp; Data Deletion</h1>
      <p class="subtitle">Request permanent erasure of your Hyprwise account, cloud sync vaults, and server records.</p>

      ${
        opts?.status === 'email_sent'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Request Recorded:</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              A deletion request has been registered for <strong>${escapeHtml(opts.email)}</strong>${opts.token ? ` — <a href="/delete-account/confirm?token=${encodeURIComponent(opts.token)}" style="color: inherit; font-weight: 700; text-decoration: underline;">confirm deletion now</a>` : ''}.
            </p>
            <p style="margin: 6px 0 0; font-size: 0.85rem; color: inherit;">
              Confirmation activates a <strong>30-day grace period</strong> during which you can cancel anytime before permanent erasure.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.status === 'confirmed'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Confirmed — 30-Day Grace Window Active</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              Account deletion for <strong>${escapeHtml(opts.email)}</strong> is scheduled for permanent purge on <strong>${escapeHtml(opts.scheduledPurgeDate || 'in 30 days')}</strong>.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.status === 'cancelled'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Cancelled:</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              Pending deletion requests for <strong>${escapeHtml(opts.email)}</strong> have been cancelled. Your account remains active.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.error
          ? `<div class="alert alert-error"><strong>Error:</strong> ${escapeHtml(opts.error)}</div>`
          : ''
      }

      <div class="callout callout-warning">
        <p><strong>30-Day Protected Deletion:</strong> Submitting your email creates a verification step followed by a 30-day grace period before permanent server purge. For immediate deletion, open Hyprwise → <em>Settings → Danger Zone → Delete Account</em>.</p>
      </div>

      <h2>Request Account Deletion</h2>
      <form method="POST" action="/delete-account" style="margin-bottom: 28px;">
        <div class="form-group">
          <label for="email">Account Email Address</label>
          <input type="email" id="email" name="email" required placeholder="name@example.com" value="${escapeHtml(opts?.email || '')}">
        </div>

        <div class="form-group">
          <label for="reason">Reason for Deletion (Optional)</label>
          <select id="reason" name="reason">
            <option value="no_longer_needed">No longer needed</option>
            <option value="switching_device">Switching devices</option>
            <option value="privacy_preference">Privacy preferences</option>
            <option value="other">Other reason</option>
          </select>
        </div>

        <div class="form-group">
          <label style="display: flex; align-items: flex-start; gap: 10px; cursor: pointer; font-weight: 500; color: var(--muted);">
            <input type="checkbox" required style="width: 17px; height: 17px; margin-top: 2px; accent-color: var(--ink);">
            <span>I understand that confirming this request schedules permanent deletion of my server account and cloud backups after 30 days.</span>
          </label>
        </div>

        <button type="submit" class="btn btn-danger">Request Account Deletion</button>
      </form>

      <div style="border-top: 1px solid var(--border); padding-top: 22px;">
        <h2 style="margin-top: 0;">Cancel a Pending Deletion</h2>
        <p style="font-size: 0.875rem;">Changed your mind during the 30-day window? Cancel your request below:</p>
        <form method="POST" action="/delete-account/cancel" style="display: flex; gap: 10px; flex-wrap: wrap;">
          <input type="email" name="email" required placeholder="Registered email address" style="flex: 1; min-width: 240px;" value="${escapeHtml(opts?.email || '')}">
          <button type="submit" class="btn btn-outline">Cancel Pending Deletion</button>
        </form>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Delete Account', bodyContent: content, activeNav: 'delete' });
}
