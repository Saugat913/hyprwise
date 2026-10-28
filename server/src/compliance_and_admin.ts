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
    appVersion: '0.1.0+1',
    createdAt: Date.now() - 3600000,
  },
  {
    id: 'evt_init_2',
    userId: 'usr_pixel_demo',
    eventType: 'action',
    eventName: 'app_launch',
    details: JSON.stringify({ locale: 'en', currency: 'USD', isPro: false }),
    deviceInfo: 'Google Pixel 8 (Android 15)',
    appVersion: '0.1.0+1',
    createdAt: Date.now() - 1800000,
  },
  {
    id: 'evt_init_3',
    userId: 'usr_pixel_demo',
    eventType: 'action',
    eventName: 'shift_created',
    details: JSON.stringify({ job: 'Barista', hours: 7.5, hourlyRate: 26.5, overtimeMultiplier: 1.5 }),
    deviceInfo: 'Google Pixel 8 (Android 15)',
    appVersion: '0.1.0+1',
    createdAt: Date.now() - 1200000,
  },
  {
    id: 'evt_init_4',
    userId: 'usr_iphone_demo',
    eventType: 'action',
    eventName: 'transaction_added',
    details: JSON.stringify({ type: 'expense', category: 'Groceries', amount: 48.75, currency: 'USD' }),
    deviceInfo: 'iPhone 15 Pro (iOS 18.1)',
    appVersion: '0.1.0+1',
    createdAt: Date.now() - 600000,
  },
];

export const ADMIN_PASSWORD = 'P@ssword123';
export const ADMIN_COOKIE_NAME = 'hyprwise_admin_auth';
export const ADMIN_AUTH_TOKEN = 'hypr_adm_token_p92817x8';

// Base HTML Page Wrapper with Hyprwise styling
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
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090d16;
      --surface: #111827;
      --surface-elevated: #1e293b;
      --border: #334155;
      --primary: #0A84FF;
      --primary-hover: #0070df;
      --accent-green: #10B981;
      --accent-red: #EF4444;
      --accent-amber: #F59E0B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
      --radius: 12px;
      --font: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      --font-mono: 'JetBrains Mono', monospace;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: var(--font);
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    header {
      background: rgba(17, 24, 39, 0.85);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border);
      position: sticky;
      top: 0;
      z-index: 50;
    }
    .nav-container {
      max-width: 1100px;
      margin: 0 auto;
      padding: 14px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: var(--text);
      font-weight: 800;
      font-size: 1.25rem;
      letter-spacing: -0.02em;
    }
    .logo-badge {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #0A84FF 0%, #10B981 100%);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 900;
      font-size: 16px;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 20px;
    }
    .nav-link {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 0.9rem;
      font-weight: 500;
      transition: color 0.15s;
    }
    .nav-link:hover, .nav-link.active {
      color: var(--primary);
    }
    main {
      flex: 1;
      max-width: 900px;
      width: 100%;
      margin: 0 auto;
      padding: 48px 24px 80px;
    }
    .content-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 40px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    }
    h1 {
      font-size: 2.2rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin-bottom: 8px;
      background: linear-gradient(135deg, #FFFFFF 0%, #94A3B8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .subtitle {
      color: var(--text-muted);
      font-size: 0.95rem;
      margin-bottom: 32px;
    }
    h2 {
      font-size: 1.35rem;
      font-weight: 700;
      margin: 32px 0 12px;
      color: var(--text);
      letter-spacing: -0.01em;
      border-bottom: 1px solid var(--border);
      padding-bottom: 8px;
    }
    h3 {
      font-size: 1.1rem;
      font-weight: 600;
      margin: 20px 0 8px;
      color: #E2E8F0;
    }
    p, ul {
      color: #CBD5E1;
      font-size: 0.95rem;
      margin-bottom: 16px;
    }
    ul {
      padding-left: 20px;
    }
    li {
      margin-bottom: 6px;
    }
    strong {
      color: var(--text);
    }
    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 6px;
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .badge-blue { background: rgba(10, 132, 255, 0.15); color: var(--primary); border: 1px solid rgba(10, 132, 255, 0.3); }
    .badge-green { background: rgba(16, 185, 129, 0.15); color: var(--accent-green); border: 1px solid rgba(16, 185, 129, 0.3); }
    .badge-red { background: rgba(239, 68, 68, 0.15); color: var(--accent-red); border: 1px solid rgba(239, 68, 68, 0.3); }
    .badge-amber { background: rgba(245, 158, 11, 0.15); color: var(--accent-amber); border: 1px solid rgba(245, 158, 11, 0.3); }
    
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 12px 20px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 0.95rem;
      text-decoration: none;
      cursor: pointer;
      border: none;
      transition: all 0.15s;
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
      background: #dc2626;
    }
    .btn-outline {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--text);
    }
    .btn-outline:hover {
      background: var(--surface-elevated);
    }
    .form-group {
      margin-bottom: 20px;
    }
    label {
      display: block;
      margin-bottom: 6px;
      font-size: 0.85rem;
      font-weight: 600;
      color: #E2E8F0;
    }
    input, select, textarea {
      width: 100%;
      padding: 12px 14px;
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 8px;
      color: var(--text);
      font-family: inherit;
      font-size: 0.95rem;
      transition: border-color 0.15s;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(10, 132, 255, 0.2);
    }
    .alert {
      padding: 14px 18px;
      border-radius: 8px;
      margin-bottom: 24px;
      font-size: 0.9rem;
      display: flex;
      align-items: flex-start;
      gap: 12px;
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
    .alert-info {
      background: rgba(10, 132, 255, 0.1);
      border: 1px solid rgba(10, 132, 255, 0.3);
      color: #60A5FA;
    }
    footer {
      border-top: 1px solid var(--border);
      padding: 32px 24px;
      background: var(--surface);
      margin-top: auto;
    }
    .footer-container {
      max-width: 1100px;
      margin: 0 auto;
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      color: var(--text-muted);
      font-size: 0.85rem;
    }
    .footer-links {
      display: flex;
      gap: 18px;
    }
    .footer-links a {
      color: var(--text-muted);
      text-decoration: none;
    }
    .footer-links a:hover {
      color: var(--text);
    }
    @media (max-width: 640px) {
      .content-card { padding: 24px 16px; }
      h1 { font-size: 1.75rem; }
    }
  </style>
</head>
<body>
  <header>
    <div class="nav-container">
      <a href="/" class="logo">
        <div class="logo-badge">H</div>
        <span>Hyprwise</span>
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
      <div>© 2026 Hyprwise Technologies. All rights reserved. Package: <code>com.hypr.hyprwise</code></div>
      <div class="footer-links">
        <a href="/privacy">Privacy Policy</a>
        <a href="/terms">Terms of Service</a>
        <a href="/delete-account">Account & Data Deletion</a>
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
      <span class="badge badge-blue">Official Legal Policy</span>
      <h1 style="margin-top: 12px;">Hyprwise Privacy Policy</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026</p>

      <div class="alert alert-info">
        <strong>Privacy-First & Local-First Philosophy:</strong> Hyprwise is engineered to keep your financial logs, hourly shift rates, bank accounts, and budgets on your device inside an encrypted SQLite database. We do not sell your personal data.
      </div>

      <h2>1. Overview & Scope</h2>
      <p>
        This Privacy Policy describes how Hyprwise ("we", "our", or "the App", Android application ID: <code>com.hypr.hyprwise</code>) collects, uses, protects, and discloses your information when you download, install, and interact with our mobile application and backend services.
      </p>

      <h2>2. Information We Collect</h2>
      <h3>A. Local On-Device Financial Data</h3>
      <p>
        The core function of Hyprwise is to track personal finances, multiple jobs, hourly shifts, penalty rates, and savings goals. This data (accounts, transactions, wage logs, and category rules) is stored locally on your device in a secure SQLite database. By default, this data never leaves your device unless you choose to enable cloud backup.
      </p>

      <h3>B. Account & Authentication Information</h3>
      <p>
        If you choose to sign in using Google Sign-In or Apple Sign-In:
      </p>
      <ul>
        <li>We collect your verified user ID (Firebase UID), display name, and email address.</li>
        <li>We do not store your Google or Apple passwords.</li>
        <li>Authentication is verified via Firebase Authentication and Google Identity Services.</li>
      </ul>

      <h3>C. Cloud Backup & Synchronization (Optional)</h3>
      <p>
        If you enable Hyprwise Cloud Sync, your encrypted local database payload is transmitted securely via HTTPS (TLS 1.3) to our Cloudflare D1 encrypted database to allow seamless synchronization across your authorized devices.
      </p>

      <h3>D. Gemini AI Financial Assistant</h3>
      <p>
        Hyprwise provides an intelligent assistant powered by Google Gemini (Gemini 2.5 Flash). When you interact with the AI assistant or scan receipts:
      </p>
      <ul>
        <li>Only the specific query, relevant contextual ledger summaries, or receipt images are transmitted to Google Gemini API for processing.</li>
        <li>We do not use your private financial records or receipt photos to train public generative AI models.</li>
      </ul>

      <h3>E. Diagnostic & Telemetry Data</h3>
      <p>
        To ensure app stability and debug issues:
      </p>
      <ul>
        <li>We collect anonymized crash reports, unhandled exceptions, app version, OS platform, and aggregated interaction events (such as whether a shift was created or CSV exported).</li>
        <li>Diagnostic events are tracked via Firebase Analytics and Hyprwise Telemetry.</li>
      </ul>

      <h2>3. Third-Party Service Providers</h2>
      <p>
        We partner with trusted industry-standard infrastructure providers strictly to execute app functionality:
      </p>
      <ul>
        <li><strong>Google Firebase (Firebase Auth & Analytics):</strong> Used for secure authentication and crash reporting.</li>
        <li><strong>Google Gemini AI:</strong> Used to interpret natural language queries, bill scanner images, and provide budgeting guidance.</li>
        <li><strong>RevenueCat & Google Play Billing:</strong> Used to manage in-app subscriptions (Hyprwise Pro) securely without exposing your credit card details to us.</li>
        <li><strong>Cloudflare Workers & D1:</strong> Provides our encrypted server gateway and synchronization layer.</li>
      </ul>

      <h2>4. Zero Data Selling & Advertising</h2>
      <p>
        We strictly <strong>never sell, lease, or monetize</strong> your personal financial transactions, hourly wages, or user profiles to data brokers, advertisers, or any third party. Hyprwise is supported entirely by optional Pro subscriptions.
      </p>

      <h2>5. Your Rights: Data Deletion & Export</h2>
      <p>
        You have complete ownership of your data at all times:
      </p>
      <ul>
        <li><strong>In-App Export:</strong> You can export all your financial transactions and shifts to CSV or JSON from Settings at any time.</li>
        <li><strong>In-App Wipe:</strong> You can clear all data instantly by tapping <em>Settings &gt; Danger Zone &gt; Erase All Data</em>.</li>
        <li><strong>Remote Account & Cloud Deletion:</strong> You may submit an instant deletion request for your cloud records and account profile on our <a href="/delete-account" style="color: var(--primary);">Account Deletion Page</a>.</li>
      </ul>

      <h2>6. Security Measures</h2>
      <p>
        We implement industry-grade security protocols, including TLS 1.3 encryption for data in transit, encrypted SQLite storage on-device, and restricted backend API tokens.
      </p>

      <h2>7. Contact Us</h2>
      <p>
        If you have any questions or data privacy inquiries regarding Hyprwise, contact our privacy officer at:
      </p>
      <p>
        <strong>Email:</strong> <a href="mailto:privacy@hyprwise.app" style="color: var(--primary);">privacy@hyprwise.app</a> or <a href="mailto:support@hyprwise.app" style="color: var(--primary);">support@hyprwise.app</a><br>
        <strong>Developer:</strong> Hyprwise Team
      </p>
    </div>
  `;
  return wrapHtml({ title: 'Privacy Policy', bodyContent: content, activeNav: 'privacy' });
}

// 2. Terms of Service Page
export function renderTermsOfServicePage(): string {
  const content = `
    <div class="content-card">
      <span class="badge badge-blue">User Agreement</span>
      <h1 style="margin-top: 12px;">Hyprwise Terms of Service</h1>
      <p class="subtitle">Effective Date: January 1, 2026 · Last Updated: October 28, 2026</p>

      <h2>1. Acceptance of Terms</h2>
      <p>
        By installing, registering, or using the Hyprwise mobile application (Application ID: <code>com.hypr.hyprwise</code>) or related backend services, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not install or use the app.
      </p>

      <h2>2. Financial Disclaimer — Not Certified Financial Advice</h2>
      <div class="alert alert-amber">
        <strong>Disclaimer:</strong> Hyprwise is a financial tracking, hourly shift planning, and budgeting organizational tool. Hyprwise does not provide certified financial planning, tax accounting, or legal investment advice. Always consult a certified financial planner, accountant, or tax professional for critical personal finance decisions.
      </div>

      <h2>3. Subscriptions & Billing (Hyprwise Pro)</h2>
      <p>
        Hyprwise offers optional premium features ("Hyprwise Pro"), including unlimited AI assistant queries, receipt scanning OCR, multi-currency auto conversion, and cloud synchronization.
      </p>
      <ul>
        <li><strong>Billing:</strong> Subscriptions (Monthly, Annual, or Lifetime) are processed via Google Play In-App Billing and managed through RevenueCat.</li>
        <li><strong>Auto-Renewal:</strong> Subscriptions automatically renew unless cancelled at least 24 hours prior to the end of the billing period in Google Play Store settings.</li>
        <li><strong>Refunds:</strong> Refund requests are governed by Google Play standard refund policies.</li>
      </ul>

      <h2>4. User Accounts & Responsibilities</h2>
      <p>
        You are responsible for maintaining the confidentiality of your mobile device, login credentials, and local data backups. You agree not to reverse engineer or abuse the API endpoints, AI query gateways, or services provided.
      </p>

      <h2>5. Termination & Data Deletion</h2>
      <p>
        You may terminate your account at any time by erasing your data in the mobile app or submitting an account deletion request via <a href="/delete-account" style="color: var(--primary);">hyprwise.app/delete-account</a>. We reserve the right to suspend accounts that abuse our AI gateway or breach our terms.
      </p>

      <h2>6. Contact Information</h2>
      <p>
        For inquiries regarding these Terms: <a href="mailto:support@hyprwise.app" style="color: var(--primary);">support@hyprwise.app</a>.
      </p>
    </div>
  `;
  return wrapHtml({ title: 'Terms of Service', bodyContent: content, activeNav: 'terms' });
}

// 3. Account Deletion Page (Google Play Compliance)
export function renderAccountDeletionPage(opts?: {
  error?: string;
  success?: boolean;
  identifier?: string;
}): string {
  const content = `
    <div class="content-card">
      <span class="badge badge-red">Google Play Data Safety Compliance</span>
      <h1 style="margin-top: 12px;">Account & Data Deletion</h1>
      <p class="subtitle">Request permanent erasure of your Hyprwise account, cloud backups, and telemetry records.</p>

      ${opts?.error ? `<div class="alert alert-error"><strong>Error:</strong> ${opts.error}</div>` : ''}
      ${
        opts?.success
          ? `<div class="alert alert-success">
              <strong>Deletion Request Processed Successfully:</strong>
              Your account (${opts.identifier || 'user'}), associated cloud backups, and telemetry records have been permanently erased from Hyprwise servers. You may now uninstall the app or clear its local storage.
            </div>`
          : ''
      }

      <div class="alert alert-info">
        <strong>What gets deleted:</strong>
        <ul style="margin: 8px 0 0 16px;">
          <li>Your user account profile (Google UID, email, display name, subscription links).</li>
          <li>All cloud-synchronized SQLite backups stored on Hyprwise servers.</li>
          <li>All remote telemetry events and error logs associated with your user ID.</li>
        </ul>
      </div>

      <p>
        In accordance with Google Play Developer Policies on User Data and Account Deletion, users who registered an account or used cloud backup may request the complete deletion of their account and data without requiring the mobile application to be installed.
      </p>

      <form method="POST" action="/delete-account" style="margin-top: 28px;">
        <div class="form-group">
          <label for="identifier">Email Address or Firebase User ID</label>
          <input type="text" id="identifier" name="identifier" required placeholder="e.g. your.email@gmail.com or usr_..." value="${opts?.identifier || ''}">
        </div>

        <div class="form-group">
          <label for="reason">Reason for Deletion (Optional)</label>
          <select id="reason" name="reason">
            <option value="no_longer_needed">No longer using the app</option>
            <option value="privacy_preference">Privacy preference</option>
            <option value="switching_device">Switching device / fresh start</option>
            <option value="troubleshooting">Troubleshooting sync issues</option>
            <option value="other">Other reason</option>
          </select>
        </div>

        <div class="form-group" style="display: flex; align-items: flex-start; gap: 10px; margin-top: 20px;">
          <input type="checkbox" id="confirm" name="confirm" required style="width: 20px; height: 20px; margin-top: 2px;">
          <label for="confirm" style="font-size: 0.9rem; font-weight: 500; cursor: pointer;">
            I understand that this action is irreversible. All cloud synchronization data, profile information, and backup snapshots will be permanently erased.
          </label>
        </div>

        <div style="margin-top: 24px; display: flex; gap: 14px;">
          <button type="submit" class="btn btn-danger">Permanently Delete My Account & Cloud Data</button>
          <a href="/" class="btn btn-outline">Cancel</a>
        </div>
      </form>

      <h2 style="margin-top: 48px;">Local On-Device Data</h2>
      <p>
        Note: Because Hyprwise is a local-first application, data stored inside your phone's local storage can be wiped directly on your phone:
      </p>
      <p style="background: var(--surface-elevated); padding: 12px 16px; border-radius: 8px; border: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.85rem;">
        Open Hyprwise App → Settings → Danger Zone → "Erase all data"
      </p>
    </div>
  `;
  return wrapHtml({ title: 'Account Deletion', bodyContent: content, activeNav: 'delete' });
}

// 4. Admin Login Page
export function renderAdminLoginPage(opts?: { error?: string }): string {
  const content = `
    <div style="max-width: 440px; margin: 40px auto;">
      <div class="content-card" style="text-align: center;">
        <div class="logo-badge" style="width: 48px; height: 48px; font-size: 24px; margin: 0 auto 16px;">H</div>
        <h1>Admin Console</h1>
        <p class="subtitle" style="margin-bottom: 24px;">Hyprwise Monitoring & Exception Dashboard</p>

        ${opts?.error ? `<div class="alert alert-error" style="text-align: left;">${opts.error}</div>` : ''}

        <form method="POST" action="/admin/login" style="text-align: left;">
          <div class="form-group">
            <label for="password">Admin Security Password</label>
            <input type="password" id="password" name="password" required placeholder="Enter admin password" autofocus>
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">Authenticate & Enter</button>
        </form>

        <p style="font-size: 0.75rem; color: var(--text-muted); margin-top: 24px;">
          Protected operations portal · Access is logged with IP and timestamp
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
    <div style="max-width: 1200px; margin: 0 auto;">
      <!-- Header -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; flex-wrap: wrap; gap: 16px;">
        <div>
          <div style="display: flex; align-items: center; gap: 10px;">
            <span class="badge badge-green">Live Production Status</span>
            <span style="color: var(--text-muted); font-size: 0.85rem;">Cloudflare Workers Edge · D1 DB Connected</span>
          </div>
          <h1 style="margin-top: 6px;">App Operations & Telemetry</h1>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/admin" class="btn btn-outline" style="font-size: 0.85rem; padding: 8px 14px;">↻ Refresh</a>
          <a href="/admin/logout" class="btn btn-outline" style="font-size: 0.85rem; padding: 8px 14px; color: var(--accent-red);">Logout</a>
        </div>
      </div>

      <!-- Metrics Grid -->
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 32px;">
        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase;">Registered Users</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalUsers}</div>
          <div style="font-size: 0.8rem; color: var(--accent-green);">Pro: ${metrics.proUsers} (${metrics.conversionRate})</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase;">Cloud Backups</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalBackups}</div>
          <div style="font-size: 0.8rem; color: var(--primary);">Active synchronized devices</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase;">Logged Exceptions</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: ${metrics.totalExceptions > 0 ? 'var(--accent-red)' : 'var(--accent-green)'};">
            ${metrics.totalExceptions}
          </div>
          <div style="font-size: 0.8rem; color: var(--text-muted);">Runtime & unhandled crash reports</div>
        </div>

        <div class="content-card" style="padding: 20px;">
          <div style="color: var(--text-muted); font-size: 0.8rem; font-weight: 600; text-transform: uppercase;">Customer Interactions</div>
          <div style="font-size: 2rem; font-weight: 800; margin: 6px 0; color: #FFF;">${metrics.totalInteractions}</div>
          <div style="font-size: 0.8rem; color: var(--text-muted);">Shifts, TXs, AI prompts</div>
        </div>
      </div>

      <!-- Section: App Exceptions & Bug Reports -->
      <div class="content-card" style="margin-bottom: 32px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0; border: none; padding: 0;">App Exceptions & Bug Monitor</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Live error stream reported from client devices and backend</p>
          </div>
          <span class="badge ${exceptions.length > 0 ? 'badge-red' : 'badge-green'}">${exceptions.length} Detected</span>
        </div>

        ${
          exceptions.length === 0
            ? `<div style="text-align: center; padding: 36px 0; color: var(--text-muted);">
                <div style="font-size: 28px; margin-bottom: 8px;">✓</div>
                <div>No app exceptions or crashes detected. All systems healthy.</div>
              </div>`
            : `
            <div style="overflow-x: auto;">
              <table style="width: 100%; border-collapse: collapse; font-size: 0.85rem; text-align: left;">
                <thead>
                  <tr style="border-bottom: 1px solid var(--border); color: var(--text-muted);">
                    <th style="padding: 10px 12px;">Type</th>
                    <th style="padding: 10px 12px;">Error Event</th>
                    <th style="padding: 10px 12px;">App Version / Device</th>
                    <th style="padding: 10px 12px;">Time</th>
                    <th style="padding: 10px 12px;">Details</th>
                  </tr>
                </thead>
                <tbody>
                  ${exceptions
                    .map(
                      (e) => `
                    <tr style="border-bottom: 1px solid rgba(255,255,255,0.05);">
                      <td style="padding: 12px;"><span class="badge badge-red">${e.eventType}</span></td>
                      <td style="padding: 12px; font-weight: 600; color: #FCA5A5;">${e.eventName}</td>
                      <td style="padding: 12px; color: var(--text-muted);">${e.appVersion || 'v0.1.0'} · ${e.deviceInfo || 'Unknown'}</td>
                      <td style="padding: 12px; color: var(--text-muted);">${new Date(e.createdAt).toLocaleTimeString()}</td>
                      <td style="padding: 12px;">
                        <pre style="background: var(--surface-elevated); padding: 6px 10px; border-radius: 6px; font-family: var(--font-mono); font-size: 0.75rem; max-width: 320px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${e.details || 'No stack trace'}</pre>
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

      <!-- Section: Customer Interaction Patterns -->
      <div class="content-card" style="margin-bottom: 32px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0; border: none; padding: 0;">Customer Interaction Patterns</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Events recorded via Firebase Analytics & Hyprwise Telemetry</p>
          </div>
          <span class="badge badge-blue">${interactions.length} Events Logged</span>
        </div>

        <div style="overflow-x: auto;">
          <table style="width: 100%; border-collapse: collapse; font-size: 0.85rem; text-align: left;">
            <thead>
              <tr style="border-bottom: 1px solid var(--border); color: var(--text-muted);">
                <th style="padding: 10px 12px;">Event Name</th>
                <th style="padding: 10px 12px;">User ID</th>
                <th style="padding: 10px 12px;">Device / Client</th>
                <th style="padding: 10px 12px;">Payload</th>
                <th style="padding: 10px 12px;">Timestamp</th>
              </tr>
            </thead>
            <tbody>
              ${interactions
                .slice(0, 50)
                .map(
                  (e) => `
                <tr style="border-bottom: 1px solid rgba(255,255,255,0.05);">
                  <td style="padding: 10px 12px;"><span class="badge badge-blue">${e.eventName}</span></td>
                  <td style="padding: 10px 12px; font-family: var(--font-mono); font-size: 0.8rem; color: #93C5FD;">${e.userId || 'anonymous'}</td>
                  <td style="padding: 10px 12px; color: var(--text-muted); font-size: 0.8rem;">${e.deviceInfo || 'Mobile'}</td>
                  <td style="padding: 10px 12px; font-family: var(--font-mono); font-size: 0.75rem; color: #A7F3D0; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                    ${e.details || '-'}
                  </td>
                  <td style="padding: 10px 12px; color: var(--text-muted); font-size: 0.8rem;">${new Date(e.createdAt).toLocaleTimeString()}</td>
                </tr>
              `
                )
                .join('')}
            </tbody>
          </table>
        </div>
      </div>

      <!-- Section: User Accounts Table -->
      <div class="content-card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
          <div>
            <h2 style="margin: 0; border: none; padding: 0;">Registered Users & Subscriptions</h2>
            <p style="color: var(--text-muted); font-size: 0.85rem; margin: 0;">Cloud accounts managed via Firebase and RevenueCat</p>
          </div>
          <span class="badge badge-green">${users.length} Users</span>
        </div>

        <div style="overflow-x: auto;">
          <table style="width: 100%; border-collapse: collapse; font-size: 0.85rem; text-align: left;">
            <thead>
              <tr style="border-bottom: 1px solid var(--border); color: var(--text-muted);">
                <th style="padding: 10px 12px;">UID</th>
                <th style="padding: 10px 12px;">Display Name</th>
                <th style="padding: 10px 12px;">Email</th>
                <th style="padding: 10px 12px;">Provider</th>
                <th style="padding: 10px 12px;">Pro Plan</th>
                <th style="padding: 10px 12px;">Created</th>
                <th style="padding: 10px 12px; text-align: right;">Actions</th>
              </tr>
            </thead>
            <tbody>
              ${
                users.length === 0
                  ? `<tr><td colspan="7" style="text-align: center; padding: 24px; color: var(--text-muted);">No cloud user records yet.</td></tr>`
                  : users
                      .map(
                        (u) => `
                    <tr style="border-bottom: 1px solid rgba(255,255,255,0.05);">
                      <td style="padding: 10px 12px; font-family: var(--font-mono); font-size: 0.75rem; color: #94A3B8;">${u.id}</td>
                      <td style="padding: 10px 12px; font-weight: 600;">${u.displayName || 'User'}</td>
                      <td style="padding: 10px 12px; color: var(--text-muted);">${u.email}</td>
                      <td style="padding: 10px 12px;"><span class="badge badge-blue">${u.provider}</span></td>
                      <td style="padding: 10px 12px;">
                        <span class="badge ${u.isPro ? 'badge-green' : 'badge-amber'}">${u.isPro ? 'PRO ACTIVE' : 'FREE'}</span>
                      </td>
                      <td style="padding: 10px 12px; color: var(--text-muted); font-size: 0.8rem;">
                        ${new Date(u.createdAt).toLocaleDateString()}
                      </td>
                      <td style="padding: 10px 12px; text-align: right;">
                        <form method="POST" action="/delete-account" onsubmit="return confirm('Permanently delete user ${u.email} and all cloud backup data?');" style="display: inline;">
                          <input type="hidden" name="identifier" value="${u.id}">
                          <input type="hidden" name="confirm" value="on">
                          <button type="submit" class="btn btn-outline" style="padding: 4px 8px; font-size: 0.75rem; color: var(--accent-red); border-color: rgba(239, 68, 68, 0.4);">
                            Delete
                          </button>
                        </form>
                      </td>
                    </tr>
                  `
                      )
                      .join('')
              }
            </tbody>
          </table>
        </div>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Admin Operations Console', bodyContent: content, activeNav: 'admin' });
}
