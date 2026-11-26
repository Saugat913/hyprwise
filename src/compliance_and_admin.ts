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
    --border: #E5E7EB;
    --fill: #F1F2F3;
    --brand: #FF6500;
    --brand-text: #B84400;
    --brand-bg: #FFF3EB;
    --green: #1F7A45;
    --green-bg: #ECF7F0;
    --red: #B42318;
    --red-bg: #FEF1F0;
    --amber: #9A5B00;
    --amber-bg: #FEF6E7;
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
    line-height: 1.65;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    -webkit-font-smoothing: antialiased;
  }
`;

// Public HTML Wrapper — clean editorial architecture, ZERO decorative pills, ZERO admin links
export function wrapHtml({
  title,
  bodyContent,
  activeNav = '',
  wide = false,
}: {
  title: string;
  bodyContent: string;
  activeNav?: '' | 'privacy' | 'terms' | 'delete';
  wide?: boolean;
}): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)} — Hyprwise</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    ${HYPRWISE_SHARED_CSS}
    header {
      background: rgba(255, 255, 255, 0.96);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .nav-container {
      max-width: 1040px;
      margin: 0 auto;
      padding: 15px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }
    .logo {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: var(--ink);
      font-weight: 800;
      font-size: 1.15rem;
      letter-spacing: -0.03em;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 24px;
    }
    .nav-link {
      color: var(--muted);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 600;
      padding: 4px 0;
      border-bottom: 2px solid transparent;
      transition: color 0.15s ease, border-color 0.15s ease;
    }
    .nav-link:hover { color: var(--ink); }
    .nav-link.active {
      color: var(--ink);
      border-bottom-color: var(--brand);
    }

    main {
      flex: 1;
      max-width: ${wide ? '1040px' : '820px'};
      width: 100%;
      margin: 0 auto;
      padding: 40px 24px 80px;
    }

    /* ===== LANDING HERO & SECTIONS ===== */
    .hero-block {
      background: var(--hero);
      color: #FFFFFF;
      border-radius: 16px;
      padding: 52px 44px;
      margin-bottom: 48px;
      border: 1px solid #232329;
    }
    .hero-brand-mark { margin-bottom: 20px; }
    .hero-title {
      color: #FFFFFF;
      font-size: 2.35rem;
      font-weight: 800;
      letter-spacing: -0.035em;
      line-height: 1.15;
      max-width: 680px;
      margin-bottom: 16px;
    }
    .hero-lead {
      color: #A1A3B0;
      font-size: 1.02rem;
      line-height: 1.65;
      max-width: 620px;
      margin-bottom: 28px;
    }
    .hero-actions {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }

    .section-block { margin-bottom: 48px; }
    .section-block:last-child { margin-bottom: 0; }
    .section-header { margin-bottom: 20px; }
    .section-header h2 {
      font-size: 1.35rem;
      font-weight: 800;
      letter-spacing: -0.025em;
      color: var(--ink);
      margin: 0 0 6px;
    }
    .section-header p {
      font-size: 0.94rem;
      color: var(--muted);
      margin: 0;
    }

    .feature-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
    }
    .feature-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
    }
    .feature-card h3 {
      font-size: 1rem;
      font-weight: 700;
      color: var(--ink);
      margin: 0 0 8px;
    }
    .feature-card p {
      font-size: 0.885rem;
      color: var(--muted);
      line-height: 1.6;
      margin: 0;
    }

    .trust-list {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      overflow: hidden;
    }
    .trust-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 20px;
      padding: 22px 24px;
      text-decoration: none;
      border-bottom: 1px solid var(--border);
      transition: background 0.14s ease;
    }
    .trust-row:last-child { border-bottom: none; }
    .trust-row:hover { background: #FAFAFB; }
    .trust-row h3 {
      font-size: 1rem;
      font-weight: 700;
      color: var(--ink);
      margin: 0 0 4px;
    }
    .trust-row p {
      font-size: 0.875rem;
      color: var(--muted);
      margin: 0;
    }
    .trust-arrow {
      font-size: 0.85rem;
      font-weight: 700;
      color: var(--ink);
      white-space: nowrap;
    }
    .trust-arrow-danger { color: var(--red); }

    /* ===== LEGAL & PORTAL DOCUMENTS ===== */
    .doc-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 40px 44px;
    }
    .doc-header {
      padding-bottom: 24px;
      margin-bottom: 28px;
      border-bottom: 1px solid var(--border);
    }
    .doc-header h1 {
      font-size: 2rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      color: var(--ink);
      margin-bottom: 8px;
      line-height: 1.2;
    }
    .doc-meta {
      color: var(--muted);
      font-size: 0.875rem;
      margin: 0;
    }
    .doc-card h2 {
      font-size: 1.15rem;
      font-weight: 700;
      margin: 30px 0 10px;
      color: var(--ink);
      letter-spacing: -0.015em;
    }
    .doc-card p, .doc-card ul {
      color: var(--muted);
      font-size: 0.94rem;
      margin-bottom: 14px;
      line-height: 1.72;
    }
    .doc-card ul { padding-left: 20px; }
    .doc-card li { margin-bottom: 7px; }
    strong { color: var(--ink); font-weight: 600; }
    a.inline-link { color: var(--ink); font-weight: 600; text-decoration: underline; text-underline-offset: 3px; }
    a.inline-link:hover { color: var(--brand-text); }
    .mono-text { font-family: var(--font-mono); font-size: 0.86em; color: var(--ink); }

    .note-box {
      background: #FAFAFB;
      border: 1px solid var(--border);
      border-left: 3px solid var(--ink);
      border-radius: var(--radius-sm);
      padding: 16px 20px;
      margin: 22px 0;
    }
    .note-box p { margin: 0; color: var(--ink); font-size: 0.9rem; line-height: 1.65; }
    .note-box-green { border-left-color: var(--green); background: var(--green-bg); border-color: #CFE9D9; }
    .note-box-amber { border-left-color: var(--amber); background: var(--amber-bg); border-color: #F2DFB6; }

    .data-table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 10px;
      margin: 18px 0 24px;
    }
    table.flat-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 0.875rem; }
    table.flat-table th {
      background: #FAFAFB;
      color: var(--ink);
      font-weight: 700;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
      font-size: 0.78rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    table.flat-table td {
      padding: 13px 16px;
      border-bottom: 1px solid var(--border);
      color: var(--muted);
      vertical-align: top;
    }
    table.flat-table tr:last-child td { border-bottom: none; }

    /* ===== BUTTONS & FORMS ===== */
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 18px;
      border-radius: var(--radius-sm);
      font-weight: 700;
      font-size: 0.875rem;
      text-decoration: none;
      cursor: pointer;
      border: 1px solid transparent;
      font-family: inherit;
      transition: background 0.15s ease, border-color 0.15s ease;
    }
    .btn-primary { background: var(--ink); color: #FFFFFF; }
    .btn-primary:hover { background: #26262B; }
    .btn-light { background: #FFFFFF; color: var(--ink); }
    .btn-light:hover { background: #ECEEF0; }
    .btn-ghost-dark { background: transparent; color: #E5E7EB; border-color: #34343C; }
    .btn-ghost-dark:hover { background: #1F1F24; color: #FFFFFF; }
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
      border-radius: var(--radius-sm);
      color: var(--ink);
      font-family: inherit;
      font-size: 0.9rem;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--ink);
      box-shadow: 0 0 0 3px rgba(15, 15, 17, 0.08);
    }
    .alert {
      padding: 14px 18px;
      border-radius: var(--radius-sm);
      margin-bottom: 22px;
      font-size: 0.885rem;
      line-height: 1.55;
    }
    .alert-success { background: var(--green-bg); border: 1px solid #CFE9D9; color: var(--green); }
    .alert-error { background: var(--red-bg); border: 1px solid #F5C2BE; color: var(--red); }

    /* ===== FOOTER ===== */
    footer {
      border-top: 1px solid var(--border);
      padding: 28px 24px;
      background: var(--surface);
      margin-top: auto;
    }
    .footer-container {
      max-width: 1040px;
      margin: 0 auto;
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      color: var(--muted);
      font-size: 0.84rem;
    }
    .footer-links { display: flex; gap: 22px; flex-wrap: wrap; }
    .footer-links a { color: var(--muted); text-decoration: none; font-weight: 500; }
    .footer-links a:hover { color: var(--ink); }

    @media (max-width: 780px) {
      .hero-block { padding: 36px 24px; }
      .hero-title { font-size: 1.8rem; }
      .feature-grid { grid-template-columns: 1fr; }
      .trust-row { flex-direction: column; align-items: flex-start; gap: 8px; }
      .doc-card { padding: 26px 20px; }
      .doc-header h1 { font-size: 1.65rem; }
      .nav-links { gap: 16px; }
    }
  </style>
</head>
<body>
  <header>
    <div class="nav-container">
      <a href="/" class="logo">
        ${getHyprwiseIconSvg(26)}
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
      <div>© 2026 Hyprwise · Personal Finance &amp; Shift Tracking</div>
      <div class="footer-links">
        <a href="/privacy">Privacy Policy</a>
        <a href="/terms">Terms of Service</a>
        <a href="/delete-account">Account Deletion</a>
      </div>
    </div>
  </footer>
</body>
</html>`;
}

// 1. Privacy Policy Page
export function renderPrivacyPolicyPage(): string {
  const content = `
    <article class="doc-card">
      <div class="doc-header">
        <h1>Privacy Policy</h1>
        <p class="doc-meta">Effective January 1, 2026 · Last updated November 26, 2026 · Application ID: <span class="mono-text">com.hypr.hyprwise</span></p>
      </div>

      <div class="note-box note-box-green">
        <p><strong>Local-First Guarantee:</strong> Hyprwise stores your financial accounts, transactions, shift logs, hourly rates, and budgets directly on your device in an encrypted SQLite database. We never sell, rent, or broker your personal financial data.</p>
      </div>

      <h2>1. Scope</h2>
      <p>
        This Privacy Policy explains how Hyprwise ("we", "our", or "the App") collects, processes, and protects information across our Android and iOS mobile applications and supporting cloud services.
      </p>

      <h2>2. Data Architecture</h2>
      <div class="data-table-container">
        <table class="flat-table">
          <thead>
            <tr>
              <th>Category</th>
              <th>Storage Location</th>
              <th>Security Controls</th>
              <th>Purpose</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Financial Accounts &amp; Shifts</strong></td>
              <td>On-device SQLite (Drift)</td>
              <td>OS sandbox storage encryption</td>
              <td>Shift wage tracking, multi-currency budgeting, balance forecasting</td>
            </tr>
            <tr>
              <td><strong>Account Profile</strong></td>
              <td>Firebase Auth &amp; Cloudflare D1</td>
              <td>TLS 1.3, RS256 JWKS &amp; HMAC-SHA256 verification</td>
              <td>Sign-in, cross-device sync, and Pro entitlement restoration</td>
            </tr>
            <tr>
              <td><strong>Optional Cloud Backups</strong></td>
              <td>Cloudflare D1 (Pro opt-in)</td>
              <td>Authenticated per-user isolation over HTTPS</td>
              <td>Multi-device sync and backup recovery</td>
            </tr>
            <tr>
              <td><strong>Receipt OCR Scans</strong></td>
              <td>Ephemeral request memory</td>
              <td>Single-request processing; images are not retained</td>
              <td>Extracting line items and totals via Gemini 2.5 Flash</td>
            </tr>
            <tr>
              <td><strong>Diagnostics</strong></td>
              <td>Hyprwise Telemetry</td>
              <td>Automatic redaction of tokens and credentials</td>
              <td>Crash resolution and app stability monitoring</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h2>3. AI Assistant &amp; Receipt Scanning</h2>
      <ul>
        <li><strong>No Model Training:</strong> Receipt photos and financial queries are never used to train third-party machine learning models.</li>
        <li><strong>Scoped Assistance:</strong> HyprAI operates strictly on your personal finance and shift scheduling workflows.</li>
        <li><strong>User Confirmation:</strong> AI-suggested transactions or shifts are written locally only after your confirmation.</li>
      </ul>

      <h2>4. Infrastructure Subprocessors</h2>
      <ul>
        <li><strong>Google Firebase:</strong> Federated Google/Apple authentication and App Check integrity verification.</li>
        <li><strong>Google Gemini:</strong> Receipt OCR parsing and conversational budget analysis.</li>
        <li><strong>RevenueCat, Google Play &amp; Apple App Store:</strong> Subscription billing and receipt validation; payment card details are never accessible to Hyprwise.</li>
        <li><strong>Cloudflare Workers &amp; D1:</strong> Edge API hosting, legal portals, and opt-in Pro backup storage.</li>
      </ul>

      <h2>5. Account &amp; Data Deletion</h2>
      <div class="note-box note-box-amber">
        <p>You can delete your account immediately inside the mobile app under <strong>Settings → Danger Zone → Delete Account</strong>, or submit a request via the <a href="/delete-account" class="inline-link">Account Deletion Portal</a> with a 30-day cancellable grace period.</p>
      </div>

      <h2>6. Contact</h2>
      <p>
        For privacy inquiries or data access requests, contact <a href="mailto:privacy@hyprwise.app" class="inline-link">privacy@hyprwise.app</a>.
      </p>
    </article>
  `;
  return wrapHtml({ title: 'Privacy Policy', bodyContent: content, activeNav: 'privacy' });
}

// 2. Terms of Service Page
export function renderTermsOfServicePage(): string {
  const content = `
    <article class="doc-card">
      <div class="doc-header">
        <h1>Terms of Service</h1>
        <p class="doc-meta">Effective January 1, 2026 · Last updated November 26, 2026 · Application ID: <span class="mono-text">com.hypr.hyprwise</span></p>
      </div>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By downloading, accessing, or using Hyprwise, you agree to be bound by these Terms of Service and our <a href="/privacy" class="inline-link">Privacy Policy</a>.
      </p>

      <h2>2. Informational Purpose Only</h2>
      <div class="note-box">
        <p>Hyprwise is a personal productivity tool for budgeting, multi-currency tracking, and shift wage estimation. It does not constitute formal financial, tax, accounting, or legal advice.</p>
      </div>

      <h2>3. Hyprwise Pro Subscriptions</h2>
      <ul>
        <li><strong>Renewal:</strong> Recurring subscriptions renew automatically unless cancelled at least 24 hours before the end of the current billing period through Google Play or Apple App Store settings.</li>
        <li><strong>Refunds:</strong> Billing disputes and refunds are handled directly by Google Play or Apple under their respective store policies.</li>
      </ul>

      <h2>4. Acceptable Use</h2>
      <p>
        You agree not to misuse, reverse engineer, disrupt, or attempt unauthorized access to Hyprwise servers, APIs, or another user's data.
      </p>

      <h2>5. Account Termination</h2>
      <p>
        You may stop using Hyprwise and permanently delete your server account at any time in-app or via the <a href="/delete-account" class="inline-link">Account Deletion Portal</a>.
      </p>

      <h2>6. Legal Contact</h2>
      <p>
        Questions regarding these terms may be sent to <a href="mailto:legal@hyprwise.app" class="inline-link">legal@hyprwise.app</a>.
      </p>
    </article>
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
    <article class="doc-card">
      <div class="doc-header">
        <h1>Account &amp; Data Deletion</h1>
        <p class="doc-meta">Permanently erase your Hyprwise account profile, cloud sync backups, and server records.</p>
      </div>

      ${
        opts?.status === 'email_sent'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Request Recorded</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              A deletion request has been registered for <strong>${escapeHtml(opts.email)}</strong>${opts.token ? ` — <a href="/delete-account/confirm?token=${encodeURIComponent(opts.token)}" style="color: inherit; font-weight: 700; text-decoration: underline;">confirm deletion now</a>` : ''}.
            </p>
            <p style="margin: 6px 0 0; font-size: 0.85rem; color: inherit;">
              Once confirmed, a 30-day grace window begins during which you may cancel at any time before permanent erasure.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.status === 'confirmed'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Confirmed</strong>
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
            <strong>Deletion Cancelled</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              Pending deletion requests for <strong>${escapeHtml(opts.email)}</strong> have been cancelled and your account remains active.
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

      <div class="note-box note-box-amber">
        <p><strong>30-Day Grace Period:</strong> Web deletion requests enter a 30-day window before permanent server erasure. For immediate deletion, open Hyprwise and go to <strong>Settings → Danger Zone → Delete Account</strong>.</p>
      </div>

      <h2>Request Account Deletion</h2>
      <form method="POST" action="/delete-account" style="margin-bottom: 32px;">
        <div class="form-group">
          <label for="email">Account Email Address</label>
          <input type="email" id="email" name="email" required placeholder="name@example.com" value="${escapeHtml(opts?.email || '')}">
        </div>

        <div class="form-group">
          <label for="reason">Reason for Leaving (Optional)</label>
          <select id="reason" name="reason">
            <option value="no_longer_needed">No longer needed</option>
            <option value="switching_device">Switching devices</option>
            <option value="privacy_preference">Privacy preferences</option>
            <option value="other">Other</option>
          </select>
        </div>

        <div class="form-group">
          <label style="display: flex; align-items: flex-start; gap: 10px; cursor: pointer; font-weight: 500; color: var(--muted);">
            <input type="checkbox" required style="width: 16px; height: 16px; margin-top: 3px; accent-color: var(--ink); flex-shrink: 0;">
            <span>I understand that confirming this request schedules permanent deletion of my server account and cloud backups after 30 days.</span>
          </label>
        </div>

        <button type="submit" class="btn btn-danger">Request Account Deletion</button>
      </form>

      <div style="border-top: 1px solid var(--border); padding-top: 24px;">
        <h2 style="margin-top: 0;">Cancel a Pending Deletion</h2>
        <p style="font-size: 0.885rem;">Enter your email address below to cancel an active deletion request before the 30-day purge date:</p>
        <form method="POST" action="/delete-account/cancel" style="display: flex; gap: 10px; flex-wrap: wrap;">
          <input type="email" name="email" required placeholder="Registered email address" style="flex: 1; min-width: 240px;" value="${escapeHtml(opts?.email || '')}">
          <button type="submit" class="btn btn-outline">Cancel Request</button>
        </form>
      </div>
    </article>
  `;
  return wrapHtml({ title: 'Delete Account', bodyContent: content, activeNav: 'delete' });
}
