// Compliance pages & Admin Monitoring Dashboard for Hyprwise
// Supports Google Play Data Safety, Account Deletion, Privacy Policy, Terms,
// and real-time Telemetry & Crash Monitoring.

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
    details: JSON.stringify({ version: '1.3.0', status: 'ready', cloud: 'cloudflare-workers' }),
    deviceInfo: 'Edge Runtime',
    appVersion: '0.1.2+3',
    createdAt: Date.now() - 3600000,
  },
  {
    id: 'evt_init_2',
    userId: 'usr_pixel_demo',
    eventType: 'action',
    eventName: 'app_launch',
    details: JSON.stringify({ locale: 'en', currency: 'USD', isPro: false }),
    deviceInfo: 'Google Pixel 8 (Android 15)',
    appVersion: '0.1.2+3',
    createdAt: Date.now() - 1800000,
  },
  {
    id: 'evt_init_3',
    userId: 'usr_pixel_demo',
    eventType: 'action',
    eventName: 'shift_created',
    details: JSON.stringify({ job: 'Barista', hours: 7.5, hourlyRate: 26.5, overtimeMultiplier: 1.5 }),
    deviceInfo: 'Google Pixel 8 (Android 15)',
    appVersion: '0.1.2+3',
    createdAt: Date.now() - 1200000,
  },
  {
    id: 'evt_init_4',
    userId: 'usr_iphone_demo',
    eventType: 'action',
    eventName: 'transaction_added',
    details: JSON.stringify({ type: 'expense', category: 'Groceries', amount: 48.75, currency: 'USD' }),
    deviceInfo: 'iPhone 15 Pro (iOS 18.1)',
    appVersion: '0.1.2+3',
    createdAt: Date.now() - 600000,
  },
];

export const ADMIN_PASSWORD = 'P@ssword123';
export const ADMIN_COOKIE_NAME = 'hyprwise_admin_auth';
export const ADMIN_AUTH_TOKEN = 'hypr_adm_token_p92817x8';

// SVG Hyprwise Logo Brand Icon
const HYPRWISE_LOGO_SVG = `
<svg width="28" height="28" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" rx="12" fill="#0F172A"/>
  <path d="M12 14L22 24L12 34" stroke="#6366F1" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M22 14L32 24L22 34" stroke="#38BDF8" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="36" cy="24" r="3" fill="#10B981"/>
</svg>
`;

// Base HTML Page Wrapper with Hyprwise Flat Modern Aesthetic
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
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090D14;
      --surface: #101726;
      --surface-elevated: #162032;
      --surface-hover: #1E293B;
      --border: rgba(255, 255, 255, 0.08);
      --border-focus: #6366F1;
      --primary: #6366F1;
      --primary-hover: #4F46E5;
      --accent-cyan: #38BDF8;
      --accent-green: #10B981;
      --accent-red: #EF4444;
      --accent-amber: #F59E0B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --text-dim: #64748B;
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
      background: rgba(9, 13, 20, 0.85);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .nav-container {
      max-width: 1080px;
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
      font-size: 1.2rem;
      letter-spacing: -0.02em;
    }
    .logo-text {
      background: linear-gradient(135deg, #FFFFFF 0%, #E2E8F0 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .nav-link {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      padding: 6px 14px;
      border-radius: var(--radius-sm);
      transition: all 0.15s ease;
    }
    .nav-link:hover {
      color: var(--text);
      background: var(--surface-elevated);
    }
    .nav-link.active {
      color: #FFFFFF;
      background: rgba(99, 102, 241, 0.15);
      border: 1px solid rgba(99, 102, 241, 0.3);
    }
    main {
      flex: 1;
      max-width: 920px;
      width: 100%;
      margin: 0 auto;
      padding: 44px 24px 80px;
    }
    .content-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 36px;
      box-shadow: 0 4px 24px rgba(0, 0, 0, 0.25);
    }
    .hero-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 0.75rem;
      font-weight: 600;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      background: rgba(99, 102, 241, 0.12);
      color: #A5B4FC;
      border: 1px solid rgba(99, 102, 241, 0.25);
      margin-bottom: 16px;
    }
    h1 {
      font-size: 2.15rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 8px;
      color: #FFFFFF;
    }
    .subtitle {
      color: var(--text-muted);
      font-size: 0.95rem;
      margin-bottom: 32px;
      display: flex;
      align-items: center;
      gap: 8px;
      flex-wrap: wrap;
    }
    .pill-group {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 28px;
    }
    .pill {
      font-size: 0.8rem;
      font-weight: 600;
      padding: 4px 12px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: var(--surface-elevated);
      color: var(--text-muted);
    }
    .pill-indigo {
      background: rgba(99, 102, 241, 0.12);
      color: #A5B4FC;
      border-color: rgba(99, 102, 241, 0.25);
    }
    .pill-emerald {
      background: rgba(16, 185, 129, 0.12);
      color: #6EE7B7;
      border-color: rgba(16, 185, 129, 0.25);
    }
    .pill-cyan {
      background: rgba(56, 189, 248, 0.12);
      color: #7DD3FC;
      border-color: rgba(56, 189, 248, 0.25);
    }
    h2 {
      font-size: 1.25rem;
      font-weight: 700;
      margin: 36px 0 14px;
      color: #FFFFFF;
      letter-spacing: -0.015em;
      display: flex;
      align-items: center;
      gap: 10px;
    }
    h3 {
      font-size: 1rem;
      font-weight: 600;
      margin: 20px 0 8px;
      color: #E2E8F0;
    }
    p, ul {
      color: #94A3B8;
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
      color: #F8FAFC;
      font-weight: 600;
    }
    code {
      font-family: var(--font-mono);
      background: var(--surface-elevated);
      padding: 2px 6px;
      border-radius: 4px;
      font-size: 0.85em;
      color: #E2E8F0;
      border: 1px solid var(--border);
    }
    .callout {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-left: 3px solid var(--primary);
      border-radius: var(--radius-sm);
      padding: 16px 20px;
      margin: 24px 0;
    }
    .callout p {
      margin: 0;
      color: #CBD5E1;
      font-size: 0.9rem;
    }
    .callout-success {
      border-left-color: var(--accent-green);
    }
    .callout-danger {
      border-left-color: var(--accent-red);
    }
    .data-table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: var(--radius-sm);
      margin: 20px 0 28px;
    }
    table.flat-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 0.875rem;
    }
    table.flat-table th {
      background: var(--surface-elevated);
      color: #F1F5F9;
      font-weight: 600;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    table.flat-table td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border);
      color: #94A3B8;
    }
    table.flat-table tr:last-child td {
      border-bottom: none;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 11px 20px;
      border-radius: var(--radius-sm);
      font-weight: 600;
      font-size: 0.9rem;
      text-decoration: none;
      cursor: pointer;
      border: none;
      transition: all 0.15s ease;
    }
    .btn-primary {
      background: var(--primary);
      color: white;
    }
    .btn-primary:hover {
      background: var(--primary-hover);
    }
    .btn-danger {
      background: var(--accent-red);
      color: white;
    }
    .btn-danger:hover {
      background: #DC2626;
    }
    .btn-outline {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      color: var(--text);
    }
    .btn-outline:hover {
      background: var(--surface-hover);
      border-color: rgba(255, 255, 255, 0.15);
    }
    .form-group {
      margin-bottom: 18px;
    }
    label {
      display: block;
      margin-bottom: 6px;
      font-size: 0.825rem;
      font-weight: 600;
      color: #E2E8F0;
      letter-spacing: 0.01em;
    }
    input, select, textarea {
      width: 100%;
      padding: 11px 14px;
      background: var(--surface-elevated);
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
      box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.2);
    }
    .alert {
      padding: 14px 18px;
      border-radius: var(--radius-sm);
      margin-bottom: 24px;
      font-size: 0.875rem;
      display: flex;
      align-items: flex-start;
      gap: 12px;
      line-height: 1.5;
    }
    .alert-success {
      background: rgba(16, 185, 129, 0.1);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: #34D399;
    }
    .alert-error {
      background: rgba(239, 68, 68, 0.1);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #F87171;
    }
    .badge-pill {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 0.725rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .badge-red { background: rgba(239, 68, 68, 0.15); color: #FCA5A5; border: 1px solid rgba(239, 68, 68, 0.3); }
    .badge-green { background: rgba(16, 185, 129, 0.15); color: #6EE7B7; border: 1px solid rgba(16, 185, 129, 0.3); }
    .badge-indigo { background: rgba(99, 102, 241, 0.15); color: #A5B4FC; border: 1px solid rgba(99, 102, 241, 0.3); }
    .badge-amber { background: rgba(245, 158, 11, 0.15); color: #FCD34D; border: 1px solid rgba(245, 158, 11, 0.3); }
    footer {
      border-top: 1px solid var(--border);
      padding: 32px 24px;
      background: var(--surface);
      margin-top: auto;
    }
    .footer-container {
      max-width: 1080px;
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
      color: var(--text);
    }
    @media (max-width: 640px) {
      .content-card { padding: 24px 18px; }
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
        ${HYPRWISE_LOGO_SVG}
        <span class="logo-text">Hyprwise</span>
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

// 1. Privacy Policy Page
export function renderPrivacyPolicyPage(): string {
  const content = `
    <div class="content-card">
      <span class="hero-badge">Google Play Data Safety Verified</span>
      <h1>Hyprwise Privacy Policy</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026 · Version 1.3.0</p>

      <div class="pill-group">
        <span class="pill pill-emerald">✓ Encrypted Local SQLite</span>
        <span class="pill pill-indigo">✓ Zero Data Monetization</span>
        <span class="pill pill-cyan">✓ Local-First Architecture</span>
      </div>

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

      <h2>3. Third-Party Service Providers</h2>
      <p>We work exclusively with vetted enterprise infrastructure providers strictly required to deliver app functionality:</p>
      <ul>
        <li><strong>Google Firebase (Authentication & Analytics):</strong> Handles federated Google/Apple sign-in and anonymized performance telemetry.</li>
        <li><strong>Google Gemini 2.5 Flash:</strong> Powers receipt bill reading and the Hyprwise AI financial assistant. Prompts are never used to train public foundation models.</li>
        <li><strong>RevenueCat & Google Play Billing:</strong> Powers secure subscription billing (Hyprwise Pro). Payment card numbers are handled directly by Google Play / Apple and are never visible to Hyprwise.</li>
        <li><strong>Cloudflare Workers & D1:</strong> Edge computing infrastructure hosting API endpoints, legal portals, and encrypted sync records.</li>
      </ul>

      <h2>4. User Rights & Data Deletion</h2>
      <p>
        In accordance with Google Play Data Safety requirements and global privacy regulations (GDPR / CCPA):
      </p>
      <ul>
        <li>You retain 100% ownership of your data at all times.</li>
        <li>You can export complete backups in CSV and encrypted formats directly from <em>Settings &rarr; Data Management</em>.</li>
        <li>You can permanently delete all cloud backups and profile records instantly either in-app via <em>Settings &rarr; Danger Zone &rarr; Delete Account</em> or through our web-based portal at <a href="/delete-account" style="color: var(--accent-cyan); text-decoration: underline;">/delete-account</a>.</li>
      </ul>

      <h2>5. Contact & Privacy Officer</h2>
      <p>
        If you have questions regarding this Privacy Policy or wish to file a formal data safety request, contact our security team at:
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
      <span class="hero-badge">Terms of Service</span>
      <h1>Hyprwise Terms of Service</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026 · Version 1.3.0</p>

      <div class="pill-group">
        <span class="pill pill-indigo">Official User Agreement</span>
        <span class="pill pill-cyan">Fair Usage Policy</span>
        <span class="pill pill-emerald">Hyprwise Pro Billing Terms</span>
      </div>

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

      <h2>5. Termination & Data Deletion</h2>
      <p>You may terminate your account at any time. When you request account deletion, all cloud-synced backups, device tokens, and customer service records are permanently purged.</p>

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
export function renderAccountDeletionPage(opts?: { success?: boolean; error?: string; identifier?: string }): string {
  const content = `
    <div class="content-card">
      <span class="hero-badge" style="background: rgba(239, 68, 68, 0.12); color: #FCA5A5; border-color: rgba(239, 68, 68, 0.25);">Google Play Compliance Portal</span>
      <h1>Account & Data Deletion</h1>
      <p class="subtitle">Permanent Erasure of Hyprwise Account, Cloud Backups & Diagnostic Records</p>

      ${
        opts?.success
          ? `
          <div class="alert alert-success">
            <div>
              <strong>Account Erasure Initiated:</strong>
              <div style="margin-top: 4px;">Cloud synchronization records, telemetry logs, and profile identifiers associated with <strong>${opts.identifier || 'your account'}</strong> have been permanently deleted from Cloudflare D1 and Firebase systems.</div>
            </div>
          </div>
        `
          : ''
      }

      ${
        opts?.error
          ? `
          <div class="alert alert-error">
            <div>
              <strong>Error:</strong> ${opts.error}
            </div>
          </div>
        `
          : ''
      }

      <div class="callout callout-danger">
        <p><strong>Warning:</strong> Deleting your account will immediately and permanently erase all cloud synchronization backups, linked profile credentials, and server audit records. This action cannot be undone.</p>
      </div>

      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; margin: 28px 0;">
        <div style="background: var(--surface-elevated); padding: 20px; border-radius: var(--radius-sm); border: 1px solid var(--border);">
          <div style="color: var(--accent-green); font-weight: 700; margin-bottom: 6px;">1. In-App Deletion (Instant)</div>
          <p style="font-size: 0.85rem; margin: 0;">Open Hyprwise on your phone &rarr; <em>Settings</em> &rarr; <em>Danger Zone</em> &rarr; tap <strong>Delete Account & Data</strong> for instant cryptographic purge.</p>
        </div>
        <div style="background: var(--surface-elevated); padding: 20px; border-radius: var(--radius-sm); border: 1px solid var(--border);">
          <div style="color: var(--accent-cyan); font-weight: 700; margin-bottom: 6px;">2. Web-Based Deletion</div>
          <p style="font-size: 0.85rem; margin: 0;">Submit the form below. Our edge database immediately executes a deletion query across all D1 sync records and profile tables.</p>
        </div>
      </div>

      <form method="POST" action="/delete-account" style="margin-top: 24px;">
        <div class="form-group">
          <label for="identifier">Email Address or Firebase User ID</label>
          <input type="text" id="identifier" name="identifier" required placeholder="e.g. user@example.com or usr_abc123" value="${opts?.identifier || ''}">
        </div>

        <div class="form-group">
          <label for="reason">Reason for Deletion (Optional)</label>
          <select id="reason" name="reason">
            <option value="no_longer_needed">I no longer need the app</option>
            <option value="switching_device">Switching devices</option>
            <option value="privacy_preference">Privacy preferences</option>
            <option value="other">Other reason</option>
          </select>
        </div>

        <div class="form-group">
          <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; color: #CBD5E1;">
            <input type="checkbox" required style="width: 18px; height: 18px; accent-color: var(--accent-red);">
            <span>I confirm that I want to permanently delete all my cloud backups and account information.</span>
          </label>
        </div>

        <button type="submit" class="btn btn-danger" style="width: 100%; padding: 13px;">
          Permanently Erase My Account & Cloud Data
        </button>
      </form>
    </div>
  `;
  return wrapHtml({ title: 'Delete Account', bodyContent: content, activeNav: 'delete' });
}

// 4. Admin Login Page
export function renderAdminLoginPage(opts?: { error?: string }): string {
  const content = `
    <div style="max-width: 420px; margin: 40px auto;">
      <div class="content-card" style="text-align: center;">
        <div style="margin-bottom: 16px;">
          ${HYPRWISE_LOGO_SVG}
        </div>
        <h1 style="font-size: 1.5rem; margin-bottom: 6px;">Hyprwise Admin</h1>
        <p class="subtitle" style="margin-bottom: 24px; justify-content: center;">Operations, telemetry, and live exception monitor</p>

        ${opts?.error ? `<div class="alert alert-error" style="text-align: left;">${opts.error}</div>` : ''}

        <form method="POST" action="/admin/login" style="text-align: left;">
          <div class="form-group">
            <label for="password">Security Password</label>
            <input type="password" id="password" name="password" required placeholder="Enter admin password" autofocus>
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">Authenticate & Enter</button>
        </form>

        <p style="font-size: 0.75rem; color: var(--text-dim); margin-top: 24px;">
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
}): string {
  const exceptions = events.filter((e) => e.eventType === 'exception' || e.eventType === 'crash');
  const interactions = events.filter((e) => e.eventType === 'action' || e.eventType === 'screen_view');

  const content = `
    <div style="max-width: 1100px; margin: 0 auto;">
      <!-- Header -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; flex-wrap: wrap; gap: 16px;">
        <div>
          <div style="display: flex; align-items: center; gap: 10px;">
            <span class="badge-pill badge-green">● Live Edge Connected</span>
            <span style="color: var(--text-dim); font-size: 0.85rem;">Cloudflare Workers · D1 Database</span>
          </div>
          <h1 style="margin-top: 6px;">Operations & Telemetry</h1>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/admin" class="btn btn-outline" style="font-size: 0.85rem; padding: 8px 14px;">↻ Refresh</a>
          <a href="/admin/logout" class="btn btn-outline" style="font-size: 0.85rem; padding: 8px 14px; color: var(--accent-red);">Logout</a>
        </div>
      </div>

      <!-- Metrics Grid -->
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 14px; margin-bottom: 28px;">
        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.775rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Registered Users</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalUsers}</div>
          <div style="font-size: 0.8rem; color: var(--accent-green);">Pro: ${metrics.proUsers} (${metrics.conversionRate})</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.775rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Cloud Backups</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalBackups}</div>
          <div style="font-size: 0.8rem; color: var(--accent-cyan);">Active synchronized vaults</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.775rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Logged Exceptions</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: ${metrics.totalExceptions > 0 ? 'var(--accent-red)' : 'var(--accent-green)'};">
            ${metrics.totalExceptions}
          </div>
          <div style="font-size: 0.8rem; color: var(--text-dim);">Unhandled crashes / errors</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.775rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em;">Telemetry Events</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalInteractions}</div>
          <div style="font-size: 0.8rem; color: var(--text-dim);">Shifts, TXs, Assistant prompts</div>
        </div>
      </div>

      <!-- Section: App Exceptions & Bug Reports -->
      <div class="content-card" style="margin-bottom: 28px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0;">App Exceptions & Crash Reports</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Live error ingestion reported from Flutter mobile client and backend</p>
          </div>
          <span class="badge-pill ${exceptions.length > 0 ? 'badge-red' : 'badge-green'}">${exceptions.length} Detected</span>
        </div>

        ${
          exceptions.length === 0
            ? `<div style="text-align: center; padding: 32px 0; color: var(--text-muted);">
                <div style="font-size: 24px; margin-bottom: 6px;">✓</div>
                <div>No app exceptions or crashes recorded. All systems operational.</div>
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
                    <th>Stack Details</th>
                  </tr>
                </thead>
                <tbody>
                  ${exceptions
                    .map(
                      (e) => `
                    <tr>
                      <td><span class="badge-pill badge-red">${e.eventType}</span></td>
                      <td style="font-weight: 600; color: #FCA5A5;">${e.eventName}</td>
                      <td>${e.appVersion || 'v0.1.2'} · ${e.deviceInfo || 'Unknown'}</td>
                      <td>${new Date(e.createdAt).toLocaleTimeString()}</td>
                      <td>
                        <pre style="background: var(--surface-elevated); padding: 4px 8px; border-radius: 4px; font-family: var(--font-mono); font-size: 0.75rem; max-width: 320px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${e.details || 'No stack trace'}</pre>
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
      <div class="content-card" style="margin-bottom: 28px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0;">Customer Interaction Stream</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Audited real-time feature usage patterns</p>
          </div>
          <span class="badge-pill badge-indigo">${interactions.length} Events</span>
        </div>

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
                .slice(0, 15)
                .map(
                  (e) => `
                <tr>
                  <td><span class="badge-pill badge-indigo">${e.eventName}</span></td>
                  <td><code>${e.userId || 'anonymous'}</code></td>
                  <td>${e.deviceInfo || 'Unknown'}</td>
                  <td>${new Date(e.createdAt).toLocaleTimeString()}</td>
                  <td>
                    <code style="font-size: 0.75rem; max-width: 280px; display: inline-block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${e.details || '-'}</code>
                  </td>
                </tr>
              `
                )
                .join('')}
            </tbody>
          </table>
        </div>
      </div>

      <!-- Section: Registered Users -->
      <div class="content-card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0;">Registered App Users</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Firebase Authentication & Pro Entitlement Directory</p>
          </div>
          <span class="badge-pill badge-green">${users.length} Active</span>
        </div>

        ${
          users.length === 0
            ? `<div style="text-align: center; padding: 32px 0; color: var(--text-muted);">No users in database yet.</div>`
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
                      <td><span class="badge-pill badge-cyan">${u.provider || 'google'}</span></td>
                      <td>
                        ${
                          u.isPro === 1
                            ? `<span class="badge-pill badge-amber">★ PRO</span>`
                            : `<span class="badge-pill badge-indigo">FREE</span>`
                        }
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
