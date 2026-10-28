// Compliance pages & Admin Monitoring Dashboard for Hyprwise
// Supports Google Play Data Safety, Account Deletion, Privacy Policy, Terms,
// and real-time Telemetry & Crash Monitoring.

import { getHyprwiseIconSvg } from './brand_assets';

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

// In-memory telemetry buffer (preserves last 1,000 events)
export const memoryEvents: TelemetryEvent[] = [
  {
    id: 'evt_init_1',
    userId: 'system',
    eventType: 'action',
    eventName: 'server_boot',
    details: JSON.stringify({ version: '1.4.0', status: 'ready', cloud: 'cloudflare-workers' }),
    deviceInfo: 'Edge Runtime',
    appVersion: '0.1.3',
    createdAt: Date.now(),
  },
];

export const ADMIN_PASSWORD = 'P@ssword123';
export const ADMIN_COOKIE_NAME = 'hyprwise_admin_auth';
export const ADMIN_AUTH_TOKEN = 'hypr_adm_token_p92817x8';

// Base HTML Page Wrapper with Hyprwise Clean Light Modern Aesthetic
function wrapHtml({
  title,
  bodyContent,
  activeNav = '',
}: {
  title: string;
  bodyContent: string;
  activeNav?: string;
}): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} | Hyprwise</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #F8FAF9;
      --surface: #FFFFFF;
      --surface-elevated: #F0F4F2;
      --surface-hover: #E6ECE8;
      --border: #DDE4E0;
      --border-focus: #FF6500;
      --primary: #FF6500;
      --primary-hover: #E05800;
      --primary-ink: #FFFFFF;
      --accent-green: #28A050;
      --accent-red: #D93829;
      --accent-amber: #B86E00;
      --text: #1F2726;
      --text-muted: #56645F;
      --text-dim: #7F8E89;
      --radius: 12px;
      --radius-sm: 8px;
      --font: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      --font-mono: 'JetBrains Mono', monospace;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: var(--font);
      line-height: 1.65;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      -webkit-font-smoothing: antialiased;
    }
    header {
      background: rgba(255, 255, 255, 0.94);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .nav-container {
      max-width: 1040px;
      margin: 0 auto;
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text);
      font-weight: 800;
      font-size: 1.25rem;
      letter-spacing: -0.03em;
    }
    .logo-text {
      color: #1F2726;
      font-weight: 800;
      letter-spacing: -0.03em;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .nav-link {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      padding: 6px 12px;
      border-radius: var(--radius-sm);
      transition: all 0.15s ease;
    }
    .nav-link:hover {
      color: var(--text);
      background: var(--surface-elevated);
    }
    .nav-link.active {
      color: var(--primary);
      font-weight: 600;
      background: rgba(40, 160, 80, 0.08);
      border: 1px solid rgba(40, 160, 80, 0.2);
    }
    main {
      flex: 1;
      max-width: 900px;
      width: 100%;
      margin: 0 auto;
      padding: 40px 24px 72px;
    }
    .content-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 36px;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04), 0 4px 16px rgba(31, 39, 38, 0.03);
    }
    h1 {
      font-size: 2.1rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 8px;
      color: var(--text);
    }
    .subtitle {
      color: var(--text-muted);
      font-size: 0.95rem;
      margin-bottom: 28px;
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .section-eyebrow {
      color: var(--primary);
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      margin-bottom: 6px;
      display: block;
    }
    h2 {
      font-size: 1.25rem;
      font-weight: 700;
      margin: 32px 0 12px;
      color: var(--text);
      letter-spacing: -0.015em;
    }
    h3 {
      font-size: 1rem;
      font-weight: 600;
      margin: 18px 0 8px;
      color: var(--text);
    }
    p, ul {
      color: var(--text-muted);
      font-size: 0.9375rem;
      margin-bottom: 16px;
      line-height: 1.7;
    }
    ul {
      padding-left: 20px;
    }
    li {
      margin-bottom: 6px;
    }
    strong {
      color: var(--text);
      font-weight: 600;
    }
    code {
      font-family: var(--font-mono);
      background: var(--surface-elevated);
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 0.85em;
      color: var(--text);
      border: 1px solid var(--border);
    }
    .callout {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-left: 3px solid var(--primary);
      border-radius: var(--radius-sm);
      padding: 16px 20px;
      margin: 22px 0;
    }
    .callout p {
      margin: 0;
      color: var(--text);
      font-size: 0.9rem;
    }
    .callout-success {
      border-left-color: var(--accent-green);
      background: #F4FBF6;
      border-color: #D2EEDB;
    }
    .callout-warning {
      border-left-color: var(--accent-amber);
      background: #FFFBF2;
      border-color: #F8E5BA;
    }
    .callout-danger {
      border-left-color: var(--accent-red);
      background: #FEF7F6;
      border-color: #F8D3CE;
    }
    .data-table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      margin: 18px 0 24px;
    }
    table.flat-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 0.875rem;
    }
    table.flat-table th {
      background: var(--surface-elevated);
      color: var(--text);
      font-weight: 600;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    table.flat-table td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      color: var(--text-muted);
    }
    table.flat-table tr:last-child td {
      border-bottom: none;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 10px 18px;
      border-radius: var(--radius-sm);
      font-weight: 600;
      font-size: 0.875rem;
      text-decoration: none;
      cursor: pointer;
      border: none;
      transition: all 0.15s ease;
    }
    .btn-primary {
      background: var(--primary);
      color: #FFFFFF;
    }
    .btn-primary:hover {
      background: var(--primary-hover);
    }
    .btn-danger {
      background: var(--accent-red);
      color: #FFFFFF;
    }
    .btn-danger:hover {
      background: #C22D1F;
    }
    .btn-outline {
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text);
    }
    .btn-outline:hover {
      background: var(--surface-elevated);
      border-color: #CAD5CE;
    }
    .form-group {
      margin-bottom: 18px;
    }
    label {
      display: block;
      margin-bottom: 6px;
      font-size: 0.825rem;
      font-weight: 600;
      color: var(--text);
      letter-spacing: 0.01em;
    }
    input, select, textarea {
      width: 100%;
      padding: 10px 14px;
      background: #FFFFFF;
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      color: var(--text);
      font-family: inherit;
      font-size: 0.9rem;
      transition: all 0.15s ease;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(40, 160, 80, 0.15);
    }
    .alert {
      padding: 14px 18px;
      border-radius: var(--radius-sm);
      margin-bottom: 22px;
      font-size: 0.875rem;
      line-height: 1.55;
    }
    .alert-success {
      background: #F2FBF5;
      border: 1px solid #C8EED4;
      color: #176536;
    }
    .alert-info {
      background: #F4F8F6;
      border: 1px solid #D1E3D9;
      color: #1F2726;
    }
    .alert-error {
      background: #FEF6F5;
      border: 1px solid #F9D4D0;
      color: #A92619;
    }
    .status-dot {
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--accent-green);
      margin-right: 6px;
    }
    footer {
      border-top: 1px solid var(--border);
      padding: 30px 24px;
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
      color: var(--text-dim);
      font-size: 0.825rem;
    }
    .footer-links {
      display: flex;
      gap: 18px;
      flex-wrap: wrap;
    }
    .footer-links a {
      color: var(--text-muted);
      text-decoration: none;
      transition: color 0.15s ease;
    }
    .footer-links a:hover {
      color: var(--primary);
    }
    @media (max-width: 640px) {
      .content-card { padding: 22px 18px; }
      h1 { font-size: 1.75rem; }
      .nav-links { gap: 4px; }
      .nav-link { font-size: 0.8rem; padding: 6px 10px; }
    }
  </style>
</head>
<body>
  <header>
    <div class="nav-container">
      <a href="/" class="logo">
        ${getHyprwiseIconSvg(30)}
        <span class="logo-text">hyprwise</span>
      </a>
      <div class="nav-links">
        <a href="/privacy" class="nav-link ${activeNav === 'privacy' ? 'active' : ''}">Privacy</a>
        <a href="/terms" class="nav-link ${activeNav === 'terms' ? 'active' : ''}">Terms</a>
        <a href="/delete-account" class="nav-link ${activeNav === 'delete' ? 'active' : ''}">Delete Account</a>
        <a href="/admin" class="nav-link ${activeNav === 'admin' ? 'active' : ''}">Admin</a>
      </div>
    </div>
  </header>
  <main>
    ${bodyContent}
  </main>
  <footer>
    <div class="footer-container">
      <div>© 2026 Hyprwise Technologies · Package: <code>com.hypr.hyprwise</code></div>
      <div class="footer-links">
        <a href="/privacy">Privacy Policy</a>
        <a href="/terms">Terms of Service</a>
        <a href="/delete-account">Account Deletion</a>
        <a href="/health">Health API</a>
      </div>
    </div>
  </footer>
</body>
</html>`;
}

// 0. Landing / Home Page
export function renderLandingPage(): string {
  const content = `
    <div style="text-align: center; margin-bottom: 44px;">
      <div style="display: inline-block; margin-bottom: 20px;">
        ${getHyprwiseIconSvg(68)}
      </div>
      <h1 style="font-size: 2.4rem; margin-bottom: 8px; letter-spacing: -0.04em;">hyprwise</h1>
      <p style="font-size: 1.05rem; color: var(--text-muted); max-width: 600px; margin: 0 auto 16px;">
        Personal finance, shift wage management & dual-currency budget intelligence. Built local-first for uncompromising privacy.
      </p>
      <div style="font-size: 0.85rem; color: var(--text-dim);">
        <span class="status-dot"></span>Cloudflare Edge Network Online &nbsp;·&nbsp; Version 1.3.0 &nbsp;·&nbsp; Package: <code>com.hypr.hyprwise</code>
      </div>
    </div>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; margin-bottom: 32px;">
      <a href="/privacy" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;" onmouseover="this.style.borderColor='var(--primary)'" onmouseout="this.style.borderColor='var(--border)'">
        <span class="section-eyebrow">Data Safety</span>
        <h2 style="font-size: 1.2rem; margin: 0 0 6px; color: var(--text);">Privacy Policy &rarr;</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0;">
          Google Play certified Data Safety. Zero data monetization, on-device Drift SQLite encryption, and 30-day deletion grace period.
        </p>
      </a>

      <a href="/terms" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;" onmouseover="this.style.borderColor='var(--primary)'" onmouseout="this.style.borderColor='var(--border)'">
        <span class="section-eyebrow">Legal</span>
        <h2 style="font-size: 1.2rem; margin: 0 0 6px; color: var(--text);">Terms of Service &rarr;</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0;">
          Software license, shift rate calculation disclaimers, and RevenueCat subscription terms.
        </p>
      </a>

      <a href="/delete-account" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;" onmouseover="this.style.borderColor='var(--accent-red)'" onmouseout="this.style.borderColor='var(--border)'">
        <span class="section-eyebrow" style="color: var(--accent-red);">User Rights</span>
        <h2 style="font-size: 1.2rem; margin: 0 0 6px; color: var(--text);">Delete Account &rarr;</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0;">
          Email verification required. 30-day protected grace period before permanent purge, with instant cancellation option.
        </p>
      </a>

      <a href="/admin" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;" onmouseover="this.style.borderColor='var(--primary)'" onmouseout="this.style.borderColor='var(--border)'">
        <span class="section-eyebrow">Operations</span>
        <h2 style="font-size: 1.2rem; margin: 0 0 6px; color: var(--text);">Admin Portal &rarr;</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0;">
          Live telemetry stream, exception monitor, cloud backup health, and performance telemetry.
        </p>
      </a>
    </div>

    <div class="content-card">
      <h3 style="font-size: 1.1rem; margin-top: 0; margin-bottom: 14px;">Hyprwise Core Principles</h3>
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px;">
        <div>
          <strong style="color: var(--primary); display: block; margin-bottom: 4px;">Local-First SQLite</strong>
          <p style="font-size: 0.85rem; margin: 0;">Full offline tracking. All shift wages, transactions, accounts, and budgets live in an on-device Drift SQLite vault.</p>
        </div>
        <div>
          <strong style="color: var(--primary); display: block; margin-bottom: 4px;">Dual-Currency Engine</strong>
          <p style="font-size: 0.85rem; margin: 0;">Adaptive native formatting for dual-currency earners and migrant workers with live rate conversions.</p>
        </div>
        <div>
          <strong style="color: var(--primary); display: block; margin-bottom: 4px;">Gemini 2.5 Intelligence</strong>
          <p style="font-size: 0.85rem; margin: 0;">On-device assisted receipt scanning and financial reasoning with verifiable database executions.</p>
        </div>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Overview', bodyContent: content, activeNav: '' });
}

// 1. Privacy Policy Page
export function renderPrivacyPolicyPage(): string {
  const content = `
    <div class="content-card">
      <span class="section-eyebrow">Google Play Data Safety Certified</span>
      <h1>Hyprwise Privacy Policy</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026 · Version 1.3.0</p>

      <div class="callout callout-success">
        <p><strong>Core Privacy Guarantee:</strong> Hyprwise is engineered local-first. Your financial logs, hourly shift rates, bank accounts, and budgets live in an encrypted on-device SQLite database via Drift. We never sell, monetize, or broker your personal financial records to third-party advertisers.</p>
      </div>

      <h2>1. Overview & Scope</h2>
      <p>
        This Privacy Policy outlines how Hyprwise ("we", "our", or "the App", Android & iOS Application ID: <code>com.hypr.hyprwise</code>) collects, handles, stores, and protects user information across mobile platforms and edge server infrastructure.
      </p>

      <h2>2. Data Collection & Processing Architecture</h2>
      
      <div class="data-table-container">
        <table class="flat-table">
          <thead>
            <tr>
              <th>Data Category</th>
              <th>Storage Location</th>
              <th>Encryption & Security</th>
              <th>Purpose</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Financial Accounts & Shifts</strong></td>
              <td>On-device local SQLite (Drift)</td>
              <td>On-device sandbox encryption</td>
              <td>Shift wage tracking, dual-currency budgeting, overdraft alerts</td>
            </tr>
            <tr>
              <td><strong>Authentication Profile</strong></td>
              <td>Firebase Auth & Edge D1</td>
              <td>TLS 1.3 & SHA-256 JWT validation</td>
              <td>Cross-device sync and Pro subscription restoration</td>
            </tr>
            <tr>
              <td><strong>Encrypted Cloud Backups</strong></td>
              <td>Cloudflare D1 (Optional user opt-in)</td>
              <td>End-to-end encrypted payload over HTTPS</td>
              <td>Disaster recovery & multi-device backup</td>
            </tr>
            <tr>
              <td><strong>Receipt OCR Scans</strong></td>
              <td>Transient memory buffer</td>
              <td>Ephemeral single-request inference</td>
              <td>Gemini 2.5 Flash receipt OCR extraction (never retained)</td>
            </tr>
            <tr>
              <td><strong>Anonymized Telemetry</strong></td>
              <td>Hyprwise Edge Telemetry</td>
              <td>Redacted parameters, zero account secrets</td>
              <td>Unhandled crash capture and performance optimization</td>
            </tr>
          </tbody>
        </table>
      </div>

      <h2>3. AI Assistant & Receipt Scanning Protocol</h2>
      <p>
        Hyprwise incorporates Gemini 2.5 Flash for natural language interaction and bill OCR scanning. All AI interactions adhere to strict guardrails:
      </p>
      <ul>
        <li><strong>Zero Training Retention:</strong> Receipt images and prompt transcripts sent to the AI proxy are never used to train global public machine learning models.</li>
        <li><strong>Strict Financial Boundary:</strong> The AI assistant is restricted exclusively to personal financial records and shift scheduling. It will refuse requests unrelated to your financial management.</li>
        <li><strong>Local Confirmation:</strong> Financial actions generated by AI execute directly against your local Drift database and are displayed with explicit confirmation cards.</li>
      </ul>

      <h2>4. Third-Party Service Providers</h2>
      <p>We work exclusively with vetted enterprise infrastructure providers strictly required to deliver app functionality:</p>
      <ul>
        <li><strong>Google Firebase (Authentication & Analytics):</strong> Handles federated Google/Apple sign-in and anonymized performance telemetry.</li>
        <li><strong>Google Gemini 2.5 Flash:</strong> Powers receipt bill reading and the Hyprwise AI financial assistant. Prompts are never used to train public foundation models.</li>
        <li><strong>RevenueCat & Google Play Billing:</strong> Powers secure subscription billing (Hyprwise Pro). Payment card numbers are handled directly by Google Play / Apple and are never visible to Hyprwise.</li>
        <li><strong>Cloudflare Workers & D1:</strong> Edge computing infrastructure hosting API endpoints, legal portals, and encrypted sync records.</li>
      </ul>

      <h2>5. User Rights & Account Deletion (30-Day Protected Grace Period)</h2>
      <div class="callout callout-warning">
        <p><strong>30-Day Safe Deletion Protocol:</strong> When you request account deletion through our web portal, a verification link is dispatched to your registered email address. Once confirmed, your account enters a mandatory <strong>30-day grace period</strong> during which your data remains protected and you can cancel the deletion at any time. Permanent cryptographic purge occurs only after the 30-day window has expired.</p>
      </div>
      <p>
        You have the complete right to export, modify, or permanently erase your data at any time:
      </p>
      <ul>
        <li><strong>In-App Deletion:</strong> Open Hyprwise &rarr; <em>Settings</em> &rarr; <em>Danger Zone</em> &rarr; <em>Delete Account</em>.</li>
        <li><strong>Web-Based Deletion:</strong> Visit <a href="/delete-account" style="color: var(--primary); font-weight: 600;">/delete-account</a> to initiate email-verified account and cloud backup deletion.</li>
        <li><strong>Cancellation:</strong> You can cancel any pending deletion during the 30-day grace period via the cancellation link sent to your email or on the <a href="/delete-account" style="color: var(--primary);">account deletion portal</a>.</li>
      </ul>

      <h2>6. Security Measures</h2>
      <p>
        All network communications utilize modern TLS 1.3 encryption. Internal administrative portals require password authorization and enforce edge IP access logging.
      </p>

      <h2>7. Contact & Privacy Officer</h2>
      <p>
        If you have questions regarding this Privacy Policy or wish to file a formal data safety request, contact our security team:
        <br>
        <strong>Email:</strong> <code>privacy@hyprwise.app</code> or <code>dev@hyprwise.app</code>
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
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026 · Version 1.3.0</p>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By creating an account, downloading, or using Hyprwise (application identifier <code>com.hypr.hyprwise</code>), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not install or use the App.
      </p>

      <h2>2. Financial Information & Guidance Disclaimer</h2>
      <div class="callout">
        <p><strong>Not Professional Financial or Legal Advice:</strong> Hyprwise is an informational tool built for personal budgeting, shift wage calculations, and currency tracking. Hyprwise does not provide formal financial, investment, accounting, or legal advice. Wage estimates and tax breakdowns are approximations.</p>
      </div>

      <h2>3. Subscriptions & Billing (Hyprwise Pro)</h2>
      <p>Hyprwise offers optional premium capabilities ("Hyprwise Pro") via monthly, annual, or lifetime subscriptions managed through Google Play In-App Billing or Apple In-App Purchase:</p>
      <ul>
        <li><strong>Billing Cycle:</strong> Recurring subscriptions renew automatically unless cancelled at least 24 hours before the end of the active billing period via Google Play Store / Apple App Store account settings.</li>
        <li><strong>Free Trials:</strong> If offered, unused trial days forfeit upon purchasing a standard recurring subscription.</li>
        <li><strong>Refunds:</strong> All refund requests are governed by Google Play or Apple App Store policies.</li>
      </ul>

      <h2>4. User Responsibilities & Acceptable Use</h2>
      <p>You agree to use Hyprwise solely for lawful personal or small-business shift management. You agree not to reverse engineer, decompile, or launch automated denial-of-service attempts against Hyprwise edge infrastructure.</p>

      <h2>5. Termination & Data Deletion (30-Day Policy)</h2>
      <p>You may request account deletion at any time. When you request deletion via our web portal, an email confirmation is sent, followed by a <strong>30-day grace period</strong> during which you may cancel at any time. Permanent purge of cloud backups and telemetry occurs automatically after 30 days.</p>

      <h2>6. Governing Law & Inquiries</h2>
      <p>
        These Terms are governed by applicable trade and electronic commerce laws. For legal questions:
        <br>
        <strong>Legal Contact:</strong> <code>legal@hyprwise.app</code>
      </p>
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
      <span class="section-eyebrow" style="color: var(--accent-red);">Google Play Data Safety Portal</span>
      <h1>Account & Data Deletion</h1>
      <p class="subtitle">Request permanent erasure of your Hyprwise account, cloud sync vaults, and server records.</p>

      ${
        opts?.status === 'email_sent'
          ? `
          <div class="alert alert-success">
            <strong>Verification Email Sent:</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              A confirmation link has been dispatched to <strong>${opts.email}</strong>. Please check your inbox and click the confirmation link to schedule your account deletion.
            </p>
            <p style="margin: 8px 0 0; font-size: 0.85rem; color: inherit;">
              <strong>Protection Note:</strong> Your data is NOT deleted immediately. Confirmation activates a <strong>30-day grace period</strong> during which your records are safely preserved, and you can cancel anytime.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.status === 'confirmed'
          ? `
          <div class="alert alert-success">
            <strong>Deletion Confirmed — 30-Day Grace Window Active:</strong>
            <p style="margin: 6px 0 0; color: inherit;">
              Account deletion for <strong>${opts.email}</strong> has been confirmed and scheduled for permanent purge.
            </p>
            <p style="margin: 8px 0; font-weight: 700; font-size: 1rem; color: inherit;">
              Scheduled Purge Date: ${opts.scheduledPurgeDate || 'In 30 days'}
            </p>
            <p style="margin: 8px 0 0; font-size: 0.85rem; color: inherit;">
              You have 30 days to change your mind. Use the cancellation form below or the cancel link in your email at any time to restore your active account.
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
              The pending deletion request for <strong>${opts.email}</strong> has been cancelled. Your account and cloud sync vaults remain active and protected.
            </p>
          </div>
        `
          : ''
      }

      ${
        opts?.error
          ? `
          <div class="alert alert-error">
            <strong>Error:</strong> ${opts.error}
          </div>
        `
          : ''
      }

      <div class="callout callout-warning">
        <strong style="display: block; margin-bottom: 6px; color: var(--text);">How Account Deletion Works (30-Day Safe Protocol):</strong>
        <p style="font-size: 0.875rem; line-height: 1.6; margin-bottom: 8px;">
          1. <strong>Email Verification:</strong> We email you a secure confirmation link to ensure no unauthorized or accidental deletion occurs.
        </p>
        <p style="font-size: 0.875rem; line-height: 1.6; margin-bottom: 8px;">
          2. <strong>30-Day Protection Window:</strong> Once you confirm, your data is retained safely for <strong>30 days</strong>. Nothing is deleted right away.
        </p>
        <p style="font-size: 0.875rem; line-height: 1.6; margin: 0;">
          3. <strong>Cancel Anytime:</strong> If you change your mind, submit your email below or click the cancel link in your email during the 30-day period to restore full active access.
        </p>
      </div>

      <h2 style="font-size: 1.15rem; margin-top: 28px; margin-bottom: 10px;">Step 1: Request Deletion Verification Email</h2>
      <p style="font-size: 0.875rem; color: var(--text-muted); margin-bottom: 16px;">
        Enter your registered email address. We will send a confirmation link to start the 30-day grace period.
      </p>

      <form method="POST" action="/delete-account" style="margin-bottom: 32px;">
        <div class="form-group">
          <label for="email">Account Email Address</label>
          <input type="email" id="email" name="email" required placeholder="e.g. name@example.com" value="${opts?.email || ''}">
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
          <label style="display: flex; align-items: flex-start; gap: 10px; cursor: pointer; font-size: 0.85rem; font-weight: normal; color: var(--text-muted);">
            <input type="checkbox" required style="width: 17px; height: 17px; margin-top: 2px; accent-color: var(--primary);">
            <span>I understand that a confirmation email will be sent and that I have 30 days to cancel before data is permanently deleted.</span>
          </label>
        </div>

        <button type="submit" class="btn btn-primary" style="padding: 10px 20px;">
          Send Deletion Confirmation Email
        </button>
      </form>

      <div style="border-top: 1px solid var(--border); padding-top: 24px;">
        <h2 style="font-size: 1.15rem; margin-top: 0; margin-bottom: 8px;">Cancel a Pending Deletion</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin-bottom: 14px;">
          If you previously confirmed a deletion request and wish to keep your account within the 30-day grace period, enter your email below to cancel immediately.
        </p>

        <form method="POST" action="/delete-account/cancel" style="display: flex; gap: 10px; flex-wrap: wrap;">
          <input type="email" name="email" required placeholder="Your registered email address" style="flex: 1; min-width: 240px;" value="${opts?.email || ''}">
          <button type="submit" class="btn btn-outline" style="padding: 10px 18px;">
            Cancel Deletion & Keep Account
          </button>
        </form>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Delete Account', bodyContent: content, activeNav: 'delete' });
}

// 4. Admin Login Page
export function renderAdminLoginPage(opts?: { error?: string }): string {
  const content = `
    <div style="max-width: 400px; margin: 40px auto;">
      <div class="content-card" style="text-align: center;">
        <div style="margin-bottom: 18px; display: inline-block;">
          ${getHyprwiseIconSvg(52)}
        </div>
        <h1 style="font-size: 1.45rem; margin-bottom: 6px; letter-spacing: -0.03em;">hyprwise admin</h1>
        <p class="subtitle" style="margin-bottom: 22px; justify-content: center; font-size: 0.875rem;">Edge telemetry and live operational monitor</p>

        ${opts?.error ? `<div class="alert alert-error" style="text-align: left;">${opts.error}</div>` : ''}

        <form method="POST" action="/admin/login" style="text-align: left;">
          <div class="form-group">
            <label for="password">Security Password</label>
            <input type="password" id="password" name="password" required placeholder="Enter admin password" autofocus>
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%; padding: 11px; margin-top: 6px;">Authenticate & Enter</button>
        </form>

        <p style="font-size: 0.75rem; color: var(--text-dim); margin-top: 20px; margin-bottom: 0;">
          Protected operations portal · Access is logged with edge IP and timestamp
        </p>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Admin Login', bodyContent: content, activeNav: 'admin' });
}

// 5. Admin Monitoring Dashboard
export function renderAdminDashboard({
  metrics,
  events,
  users,
  deletions = [],
}: {
  metrics: {
    totalUsers: number;
    proUsers: number;
    conversionRate: string;
    totalBackups: number;
    totalExceptions: number;
    totalInteractions: number;
    uptime: string;
  };
  events: TelemetryEvent[];
  users: any[];
  deletions?: any[];
}): string {
  const exceptions = events.filter((e) => e.eventType === 'exception' || e.eventType === 'crash');
  const interactions = events.filter((e) => e.eventType === 'action' || e.eventType === 'screen_view');

  const content = `
    <div style="max-width: 1040px; margin: 0 auto;">
      <!-- Header -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 14px;">
        <div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span class="status-dot"></span>
            <span style="font-weight: 600; font-size: 0.85rem; color: var(--primary);">Live Edge Connected</span>
            <span style="color: var(--text-dim); font-size: 0.85rem;">· Cloudflare Workers · D1 Database</span>
          </div>
          <h1 style="margin-top: 4px; font-size: 1.85rem;">Operations & Telemetry</h1>
        </div>
        <div style="display: flex; gap: 8px;">
          <a href="/admin" class="btn btn-outline" style="font-size: 0.825rem; padding: 7px 12px;">↻ Refresh</a>
          <a href="/admin/logout" class="btn btn-outline" style="font-size: 0.825rem; padding: 7px 12px; color: var(--accent-red);">Logout</a>
        </div>
      </div>

      <!-- Metrics Grid -->
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 12px; margin-bottom: 24px;">
        <div class="content-card" style="padding: 18px;">
          <div style="color: var(--text-muted); font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Registered Users</div>
          <div style="font-size: 1.85rem; font-weight: 800; margin: 4px 0; color: var(--text);">${metrics.totalUsers}</div>
          <div style="font-size: 0.8rem; color: var(--primary);">Pro: ${metrics.proUsers} (${metrics.conversionRate})</div>
        </div>

        <div class="content-card" style="padding: 18px;">
          <div style="color: var(--text-muted); font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Cloud Backups</div>
          <div style="font-size: 1.85rem; font-weight: 800; margin: 4px 0; color: var(--text);">${metrics.totalBackups}</div>
          <div style="font-size: 0.8rem; color: var(--text-muted);">Active sync vaults</div>
        </div>

        <div class="content-card" style="padding: 18px;">
          <div style="color: var(--text-muted); font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Logged Exceptions</div>
          <div style="font-size: 1.85rem; font-weight: 800; margin: 4px 0; color: ${metrics.totalExceptions > 0 ? 'var(--accent-red)' : 'var(--primary)'};">
            ${metrics.totalExceptions}
          </div>
          <div style="font-size: 0.8rem; color: var(--text-dim);">Unhandled crashes</div>
        </div>

        <div class="content-card" style="padding: 18px;">
          <div style="color: var(--text-muted); font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Telemetry Events</div>
          <div style="font-size: 1.85rem; font-weight: 800; margin: 4px 0; color: var(--text);">${metrics.totalInteractions}</div>
          <div style="font-size: 0.8rem; color: var(--text-dim);">Logged client actions</div>
        </div>
      </div>

      <!-- Section: 30-Day Account Deletion Queue -->
      <div class="content-card" style="margin-bottom: 24px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
          <div>
            <h2 style="margin: 0; font-size: 1.15rem;">Pending Account Deletion Queue (30-Day Window)</h2>
            <p style="color: var(--text-muted); font-size: 0.825rem; margin: 0;">Verified deletion requests undergoing 30-day grace retention</p>
          </div>
          <span style="font-size: 0.8rem; font-weight: 600; color: var(--text-muted);">${deletions.length} Pending</span>
        </div>

        ${
          deletions.length === 0
            ? `<div style="text-align: center; padding: 24px 0; color: var(--text-muted); font-size: 0.875rem;">
                No pending deletion requests.
              </div>`
            : `
            <div class="data-table-container" style="margin: 0;">
              <table class="flat-table">
                <thead>
                  <tr>
                    <th>Email</th>
                    <th>Status</th>
                    <th>Requested</th>
                    <th>Scheduled Purge Date</th>
                    <th>Token</th>
                  </tr>
                </thead>
                <tbody>
                  ${deletions
                    .map(
                      (d) => `
                    <tr>
                      <td><strong>${d.email}</strong></td>
                      <td>
                        <span style="font-weight: 600; font-size: 0.8rem; color: ${d.status === 'confirmed' ? 'var(--accent-red)' : 'var(--accent-amber)'};">
                          ${d.status}
                        </span>
                      </td>
                      <td>${new Date(d.requestedAt).toLocaleDateString()}</td>
                      <td><strong>${new Date(d.scheduledPurgeAt).toLocaleDateString()}</strong></td>
                      <td><code>${String(d.token).substring(0, 10)}...</code></td>
                    </tr>
                  `
                    )
                    .join('')}
                </tbody>
              </table>
            </div>
          `
        }
      </div>

      <!-- Section: App Exceptions & Bug Reports -->
      <div class="content-card" style="margin-bottom: 24px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
          <div>
            <h2 style="margin: 0; font-size: 1.15rem;">App Exceptions & Crash Reports</h2>
            <p style="color: var(--text-muted); font-size: 0.825rem; margin: 0;">Live error ingestion reported from Flutter mobile client and edge</p>
          </div>
          <span style="font-size: 0.8rem; font-weight: 600; color: ${exceptions.length > 0 ? 'var(--accent-red)' : 'var(--primary)'};">
            ${exceptions.length} Recorded
          </span>
        </div>

        ${
          exceptions.length === 0
            ? `<div style="text-align: center; padding: 28px 0; color: var(--text-muted); font-size: 0.875rem;">
                ✓ No app exceptions or crashes recorded. All systems operational.
              </div>`
            : `
            <div class="data-table-container" style="margin: 0;">
              <table class="flat-table">
                <thead>
                  <tr>
                    <th>Type</th>
                    <th>Error Event</th>
                    <th>App Version / Device</th>
                    <th>Time</th>
                    <th>Details</th>
                  </tr>
                </thead>
                <tbody>
                  ${exceptions
                    .map(
                      (e) => `
                    <tr>
                      <td style="font-weight: 600; font-size: 0.8rem; color: var(--accent-red);">${e.eventType}</td>
                      <td style="font-weight: 600; color: var(--text);">${e.eventName}</td>
                      <td>${e.appVersion || 'v0.1.2'} · ${e.deviceInfo || 'Unknown'}</td>
                      <td>${new Date(e.createdAt).toLocaleTimeString()}</td>
                      <td>
                        <code style="font-size: 0.75rem; max-width: 260px; display: inline-block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${e.details || '-'}</code>
                      </td>
                    </tr>
                  `
                    )
                    .join('')}
                </tbody>
              </table>
            </div>
          `
        }
      </div>

      <!-- Section: Live Customer Interaction Stream -->
      <div class="content-card" style="margin-bottom: 24px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
          <div>
            <h2 style="margin: 0; font-size: 1.15rem;">Customer Interaction Stream</h2>
            <p style="color: var(--text-muted); font-size: 0.825rem; margin: 0;">Audited real-time feature usage patterns</p>
          </div>
          <span style="font-size: 0.8rem; color: var(--text-muted);">${interactions.length} Events</span>
        </div>

        ${
          interactions.length === 0
            ? `<div style="text-align: center; padding: 24px 0; color: var(--text-muted); font-size: 0.875rem;">No customer interaction events recorded yet.</div>`
            : `
            <div class="data-table-container" style="margin: 0;">
              <table class="flat-table">
                <thead>
                  <tr>
                    <th>Event Action</th>
                    <th>User Identifier</th>
                    <th>Device Platform</th>
                    <th>Timestamp</th>
                    <th>Parameters</th>
                  </tr>
                </thead>
                <tbody>
                  ${interactions
                    .slice(0, 25)
                    .map(
                      (e) => `
                    <tr>
                      <td style="font-weight: 600; color: var(--text);">${e.eventName}</td>
                      <td><code>${e.userId || 'anonymous'}</code></td>
                      <td>${e.deviceInfo || 'Unknown'}</td>
                      <td>${new Date(e.createdAt).toLocaleTimeString()}</td>
                      <td>
                        <code style="font-size: 0.75rem; max-width: 260px; display: inline-block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${e.details || '-'}</code>
                      </td>
                    </tr>
                  `
                    )
                    .join('')}
                </tbody>
              </table>
            </div>
          `
        }
      </div>

      <!-- Section: Registered Users -->
      <div class="content-card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
          <div>
            <h2 style="margin: 0; font-size: 1.15rem;">Registered App Users</h2>
            <p style="color: var(--text-muted); font-size: 0.825rem; margin: 0;">Firebase Authentication & Pro Entitlement Directory</p>
          </div>
          <span style="font-size: 0.8rem; color: var(--text-muted);">${users.length} Active</span>
        </div>

        ${
          users.length === 0
            ? `<div style="text-align: center; padding: 24px 0; color: var(--text-muted); font-size: 0.875rem;">No users in database yet.</div>`
            : `
            <div class="data-table-container" style="margin: 0;">
              <table class="flat-table">
                <thead>
                  <tr>
                    <th>User ID</th>
                    <th>Email</th>
                    <th>Provider</th>
                    <th>Tier</th>
                    <th>Joined</th>
                  </tr>
                </thead>
                <tbody>
                  ${users
                    .slice(0, 25)
                    .map(
                      (u) => `
                    <tr>
                      <td><code>${u.id}</code></td>
                      <td>${u.email || 'guest@offline.local'}</td>
                      <td>${u.provider || 'google'}</td>
                      <td>
                        <strong style="color: ${u.isPro === 1 ? 'var(--primary)' : 'var(--text-muted)'}; font-size: 0.8rem;">
                          ${u.isPro === 1 ? 'PRO' : 'FREE'}
                        </strong>
                      </td>
                      <td>${new Date(u.createdAt || Date.now()).toLocaleDateString()}</td>
                    </tr>
                  `
                    )
                    .join('')}
                </tbody>
              </table>
            </div>
          `
        }
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Admin Dashboard', bodyContent: content, activeNav: 'admin' });
}
