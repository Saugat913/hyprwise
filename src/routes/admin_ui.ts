// Production Admin Console UI for Hyprwise (Path-only at /admin, zero client JS -> strict CSP script-src 'none')
// Uses exact Hyprwise WCAG AA design tokens, 12px border radius, and tabular monospace typography.

import { getHyprwiseIconSvg } from '../brand_assets';
import { escapeHtml, HYPRWISE_SHARED_CSS, type TelemetryEvent } from '../compliance_and_admin';

export type AdminTab =
  | 'overview'
  | 'users'
  | 'backups'
  | 'deletions'
  | 'telemetry'
  | 'audit'
  | 'danger';

export interface AdminUserView {
  id: string;
  email: string;
  displayName: string;
  provider: string;
  isPro: number;
  proExpiresAt: number | null;
  activePro: boolean;
  expiredPro: boolean;
  dailyAiQueriesUsed: number;
  createdAt: number;
  backupVersion: number | null;
  backupBytes: number | null;
  backupUpdatedAt: number | null;
}

export interface AdminBackupView {
  userId: string;
  email: string | null;
  version: number;
  sizeBytes: number;
  lastSyncedAt: number;
}

export interface AdminAuditRow {
  id: string;
  action: string;
  target: string | null;
  details: string | null;
  ipAddress: string | null;
  createdAt: number;
}

export interface AdminHealthCheck {
  label: string;
  ok: boolean;
  detail: string;
  critical?: boolean;
}

export interface AdminDashboardProps {
  tab: AdminTab;
  csrfToken: string;
  flashOk?: string;
  flashErr?: string;
  usingDefaultPassword: boolean;
  usingDefaultSecret: boolean;
  searchQuery: string;
  tierFilter: string;
  metrics: {
    totalUsers: number;
    activeProUsers: number;
    expiredProUsers: number;
    conversionRate: string;
    totalBackups: number;
    totalBackupBytes: number;
    totalExceptions: number;
    totalEvents: number;
    aiQueriesToday: number;
    pendingDeletions: number;
  };
  users: AdminUserView[];
  backups: AdminBackupView[];
  deletions: any[];
  events: TelemetryEvent[];
  auditLogs: AdminAuditRow[];
  healthChecks: AdminHealthCheck[];
  analyticsHtml: string;
}

function formatBytes(bytes: number | null | undefined): string {
  const b = Number(bytes || 0);
  if (b <= 0) return '0 B';
  if (b < 1024) return `${b} B`;
  if (b < 1024 * 1024) return `${(b / 1024).toFixed(1)} KB`;
  return `${(b / (1024 * 1024)).toFixed(2)} MB`;
}

function formatDate(ts: number | string | null | undefined): string {
  if (!ts) return '—';
  const d = new Date(Number(ts));
  if (Number.isNaN(d.getTime())) return '—';
  return d.toISOString().slice(0, 10);
}

function formatDateTime(ts: number | string | null | undefined): string {
  if (!ts) return '—';
  const d = new Date(Number(ts));
  if (Number.isNaN(d.getTime())) return '—';
  return d.toISOString().replace('T', ' ').slice(0, 16) + ' UTC';
}

const ADMIN_CSS = `
  ${HYPRWISE_SHARED_CSS}
  .admin-bar {
    background: var(--hero);
    color: #FFFFFF;
    border-bottom: 1px solid #27272A;
    position: sticky;
    top: 0;
    z-index: 60;
  }
  .admin-bar-inner {
    max-width: 1200px;
    margin: 0 auto;
    padding: 12px 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }
  .brand-group {
    display: flex;
    align-items: center;
    gap: 10px;
    text-decoration: none;
    color: #FFFFFF;
    font-weight: 800;
    font-size: 1.05rem;
    letter-spacing: -0.02em;
  }
  .console-pill {
    font-family: var(--font-mono);
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    background: rgba(255, 101, 0, 0.16);
    color: #FF8533;
    border: 1px solid rgba(255, 101, 0, 0.35);
    padding: 3px 8px;
    border-radius: 6px;
  }
  .bar-actions { display: flex; align-items: center; gap: 8px; }
  .bar-btn {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 7px 12px;
    border-radius: var(--radius-sm);
    font-size: 0.8rem;
    font-weight: 600;
    text-decoration: none;
    cursor: pointer;
    border: 1px solid #2E2E34;
    background: #1C1C20;
    color: #F4F4F6;
    font-family: inherit;
  }
  .bar-btn:hover { background: #27272C; }
  .bar-btn-danger { color: #F2766B; border-color: rgba(242, 118, 107, 0.35); }
  .tabs-wrap {
    background: var(--surface);
    border-bottom: 1px solid var(--border);
  }
  .tabs-inner {
    max-width: 1200px;
    margin: 0 auto;
    padding: 8px 20px;
    display: flex;
    gap: 6px;
    overflow-x: auto;
  }
  .tab-link {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 7px 12px;
    border-radius: var(--radius-sm);
    text-decoration: none;
    font-size: 0.825rem;
    font-weight: 600;
    color: var(--muted);
    white-space: nowrap;
    border: 1px solid transparent;
  }
  .tab-link:hover { color: var(--ink); background: var(--fill); }
  .tab-link.active { color: #FFFFFF; background: var(--ink); }
  .tab-link.danger-tab.active { background: var(--red); color: #FFFFFF; }
  .tab-link.danger-tab { color: var(--red); }
  .tab-count {
    font-family: var(--font-mono);
    font-size: 0.72rem;
    padding: 1px 6px;
    border-radius: 6px;
    background: rgba(15, 15, 17, 0.08);
  }
  .tab-link.active .tab-count { background: rgba(255, 255, 255, 0.18); color: #FFFFFF; }
  .wrap {
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    padding: 24px 20px 64px;
    flex: 1;
  }
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 20px;
    margin-bottom: 18px;
  }
  .card-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 14px;
    flex-wrap: wrap;
  }
  .eyebrow {
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--muted);
    margin-bottom: 3px;
  }
  .card-title { font-size: 1.05rem; font-weight: 800; color: var(--ink); letter-spacing: -0.015em; }
  .kpi-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(175px, 1fr));
    gap: 12px;
    margin-bottom: 20px;
  }
  .kpi {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 16px;
  }
  .kpi-val {
    font-family: var(--font-mono);
    font-size: 1.65rem;
    font-weight: 800;
    color: var(--ink);
    margin: 4px 0 2px;
    line-height: 1.15;
  }
  .kpi-sub { font-size: 0.78rem; color: var(--muted); }
  .grid-2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 14px; }
  .grid-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 14px; }
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 8px;
    border-radius: 6px;
    font-size: 0.72rem;
    font-weight: 700;
    font-family: var(--font-mono);
    white-space: nowrap;
  }
  .badge-green { background: var(--green-bg); color: var(--green); }
  .badge-red { background: var(--red-bg); color: var(--red); }
  .badge-amber { background: var(--amber-bg); color: var(--amber); }
  .badge-brand { background: var(--brand-bg); color: var(--brand-text); }
  .badge-neutral { background: var(--fill); color: var(--muted); }
  .banner {
    padding: 12px 16px;
    border-radius: var(--radius);
    margin-bottom: 16px;
    font-size: 0.86rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    flex-wrap: wrap;
  }
  .banner-ok { background: var(--green-bg); color: var(--green); border: 1px solid #BFE6CE; }
  .banner-err { background: var(--red-bg); color: var(--red); border: 1px solid #F5C2BE; }
  .banner-warn { background: var(--amber-bg); color: var(--amber); border: 1px solid #F3DBA8; }
  .table-wrap {
    overflow-x: auto;
    border: 1px solid var(--border);
    border-radius: var(--radius);
  }
  table { width: 100%; border-collapse: collapse; font-size: 0.84rem; text-align: left; }
  th {
    background: var(--fill);
    color: var(--ink);
    font-weight: 700;
    padding: 10px 12px;
    border-bottom: 1px solid var(--border);
    white-space: nowrap;
    font-size: 0.76rem;
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }
  td {
    padding: 11px 12px;
    border-bottom: 1px solid var(--border);
    vertical-align: top;
    color: var(--ink);
  }
  tr:last-child td { border-bottom: none; }
  .mono { font-family: var(--font-mono); font-size: 0.78rem; }
  .muted { color: var(--muted); font-size: 0.78rem; }
  .form-row { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-bottom: 12px; }
  label { display: block; font-size: 0.76rem; font-weight: 700; color: var(--ink); margin-bottom: 5px; }
  input, select {
    width: 100%;
    padding: 9px 12px;
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    background: var(--surface);
    color: var(--ink);
    font-family: inherit;
    font-size: 0.86rem;
  }
  input:focus, select:focus { outline: none; border-color: var(--ink); }
  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 8px 14px;
    border-radius: var(--radius-sm);
    font-size: 0.82rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    border: 1px solid transparent;
    text-decoration: none;
    white-space: nowrap;
  }
  .btn-sm { padding: 5px 10px; font-size: 0.76rem; }
  .btn-primary { background: var(--ink); color: #FFFFFF; }
  .btn-primary:hover { background: #262629; }
  .btn-brand { background: var(--brand); color: #FFFFFF; }
  .btn-brand:hover { background: #E05800; }
  .btn-outline { background: var(--surface); color: var(--ink); border-color: var(--border); }
  .btn-outline:hover { background: var(--fill); }
  .btn-danger { background: var(--red); color: #FFFFFF; }
  .btn-danger:hover { background: #961D14; }
  .btn-danger-soft { background: var(--red-bg); color: var(--red); border-color: #F5C2BE; }
  .btn-danger-soft:hover { background: #FADAD7; }
  details.action-drawer { position: relative; }
  details.action-drawer summary {
    list-style: none;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    padding: 5px 10px;
    border-radius: var(--radius-sm);
    border: 1px solid var(--border);
    background: var(--surface);
    font-size: 0.76rem;
    font-weight: 700;
    color: var(--ink);
  }
  details.action-drawer summary::-webkit-details-marker { display: none; }
  details.action-drawer[open] summary { background: var(--ink); color: #FFFFFF; border-color: var(--ink); }
  .drawer-body {
    margin-top: 8px;
    padding: 12px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    min-width: 260px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .inline-btns { display: flex; flex-wrap: wrap; gap: 6px; }
  .empty-inline { text-align: center; padding: 28px 12px; color: var(--muted); font-size: 0.875rem; }
  .danger-card {
    border: 1px solid #F5C2BE;
    background: #FFFDFD;
    border-radius: var(--radius);
    padding: 18px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .check-label {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.8rem;
    font-weight: 500;
    color: var(--muted);
    cursor: pointer;
    margin: 0;
  }
  .check-label input[type="checkbox"] { width: 16px; height: 16px; margin-top: 2px; accent-color: var(--red); flex-shrink: 0; }
`;

export function renderAdminLoginPage(opts?: { error?: string }): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex,nofollow">
  <title>Hyprwise Console · Sign In</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=JetBrains+Mono:wght@500;600;700&display=swap" rel="stylesheet">
  <style>${ADMIN_CSS}</style>
</head>
<body style="justify-content: center; align-items: center; padding: 24px;">
  <div style="width: 100%; max-width: 400px;">
    <div class="card" style="padding: 0; overflow: hidden;">
      <div style="background: var(--hero); padding: 28px 24px; text-align: center; border-bottom: 1px solid #27272A;">
        <div style="display: inline-block; margin-bottom: 12px;">${getHyprwiseIconSvg(44)}</div>
        <div style="color: #FFFFFF; font-size: 1.35rem; font-weight: 800; letter-spacing: -0.03em;">hyprwise console</div>
        <div style="color: #9B9BA6; font-size: 0.82rem; margin-top: 4px;">Restricted operations &amp; subscription control</div>
      </div>
      <div style="padding: 24px;">
        ${opts?.error ? `<div class="banner banner-err" style="margin-bottom: 16px;">${escapeHtml(opts.error)}</div>` : ''}
        <form method="POST" action="/admin/login">
          <div style="margin-bottom: 14px;">
            <label for="password">Administrator Password</label>
            <input type="password" id="password" name="password" required autocomplete="current-password" placeholder="Enter password" autofocus>
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%; padding: 11px;">Sign In to Console</button>
        </form>
        <div class="muted" style="text-align: center; margin-top: 16px; font-size: 0.74rem;">
          Signed HMAC-SHA256 session · CSRF &amp; rate-limit enforced
        </div>
      </div>
    </div>
  </div>
</body>
</html>`;
}

export function renderAdminDashboard(p: AdminDashboardProps): string {
  const csrfInput = `<input type="hidden" name="_csrf" value="${escapeHtml(p.csrfToken)}">`;

  const tabLink = (id: AdminTab, label: string, count?: number, isDanger = false) => `
    <a href="/admin?tab=${id}" class="tab-link ${p.tab === id ? 'active' : ''} ${isDanger ? 'danger-tab' : ''}">
      <span>${label}</span>
      ${count !== undefined ? `<span class="tab-count">${count}</span>` : ''}
    </a>
  `;

  let tabContent = '';

  if (p.tab === 'overview') {
    const healthRows = p.healthChecks
      .map(
        (h) => `
        <tr>
          <td><strong>${escapeHtml(h.label)}</strong></td>
          <td>
            <span class="badge ${h.ok ? 'badge-green' : h.critical ? 'badge-red' : 'badge-amber'}">
              ${h.ok ? 'CONFIGURED' : h.critical ? 'ACTION NEEDED' : 'OPTIONAL'}
            </span>
          </td>
          <td class="muted">${escapeHtml(h.detail)}</td>
        </tr>`
      )
      .join('');

    tabContent = `
      <div class="kpi-grid">
        <div class="kpi">
          <div class="eyebrow">Registered Users</div>
          <div class="kpi-val">${p.metrics.totalUsers}</div>
          <div class="kpi-sub">${p.metrics.conversionRate} active Pro</div>
        </div>
        <div class="kpi">
          <div class="eyebrow">Active Pro</div>
          <div class="kpi-val" style="color: var(--green);">${p.metrics.activeProUsers}</div>
          <div class="kpi-sub">${p.metrics.expiredProUsers} expired</div>
        </div>
        <div class="kpi">
          <div class="eyebrow">Cloud Backups</div>
          <div class="kpi-val">${p.metrics.totalBackups}</div>
          <div class="kpi-sub">${formatBytes(p.metrics.totalBackupBytes)} stored</div>
        </div>
        <div class="kpi">
          <div class="eyebrow">Crashes / Errors</div>
          <div class="kpi-val" style="color: ${p.metrics.totalExceptions > 0 ? 'var(--red)' : 'var(--green)'};">${p.metrics.totalExceptions}</div>
          <div class="kpi-sub">${p.metrics.totalEvents} total events</div>
        </div>
        <div class="kpi">
          <div class="eyebrow">AI Queries Today</div>
          <div class="kpi-val">${p.metrics.aiQueriesToday}</div>
          <div class="kpi-sub">Gemini 2.5 Flash proxy</div>
        </div>
        <div class="kpi">
          <div class="eyebrow">Deletion Queue</div>
          <div class="kpi-val" style="color: ${p.metrics.pendingDeletions > 0 ? 'var(--amber)' : 'var(--ink)'};">${p.metrics.pendingDeletions}</div>
          <div class="kpi-sub">30-day grace window</div>
        </div>
      </div>

      ${p.analyticsHtml}

      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Production Readiness</div>
            <div class="card-title">Security &amp; Environment Posture</div>
          </div>
          <div class="inline-btns">
            <a href="/privacy" target="_blank" class="btn btn-outline btn-sm">Privacy ↗</a>
            <a href="/terms" target="_blank" class="btn btn-outline btn-sm">Terms ↗</a>
            <a href="/delete-account" target="_blank" class="btn btn-outline btn-sm">Delete Portal ↗</a>
            <a href="/health" target="_blank" class="btn btn-outline btn-sm">Health JSON ↗</a>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr><th>Check</th><th>Status</th><th>Details</th></tr>
            </thead>
            <tbody>${healthRows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'users') {
    const userRows =
      p.users.length === 0
        ? `<tr><td colspan="6" class="empty-inline">No matching users found. Use the form above to manually provision a user or Pro subscription.</td></tr>`
        : p.users
            .map((u) => {
              const tierBadge = u.activePro
                ? `<span class="badge badge-green">PRO · ${u.proExpiresAt ? `Ends ${formatDate(u.proExpiresAt)}` : 'Lifetime'}</span>`
                : u.expiredPro
                ? `<span class="badge badge-amber">EXPIRED · ${formatDate(u.proExpiresAt)}</span>`
                : `<span class="badge badge-neutral">FREE</span>`;

              const backupCell = u.backupVersion
                ? `<span class="mono">v${u.backupVersion} · ${formatBytes(u.backupBytes)}</span><div class="muted">${formatDate(u.backupUpdatedAt)}</div>`
                : `<span class="muted">None</span>`;

              return `
                <tr>
                  <td>
                    <div style="font-weight: 700;">${escapeHtml(u.displayName)}</div>
                    <div class="mono muted">${escapeHtml(u.email)}</div>
                    <div class="mono" style="font-size: 0.7rem; color: var(--muted);">${escapeHtml(u.id)}</div>
                  </td>
                  <td><span class="badge badge-neutral">${escapeHtml(u.provider)}</span></td>
                  <td>${tierBadge}</td>
                  <td>${backupCell}</td>
                  <td class="mono">${u.dailyAiQueriesUsed} / ${u.activePro ? '∞' : '5'}<div class="muted">Joined ${formatDate(u.createdAt)}</div></td>
                  <td>
                    <details class="action-drawer">
                      <summary>Manage ▾</summary>
                      <div class="drawer-body">
                        <div class="eyebrow" style="margin: 0;">Pro Subscription</div>
                        <div class="inline-btns">
                          <form method="POST" action="/admin/users/subscription">
                            ${csrfInput}
                            <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                            <input type="hidden" name="plan" value="pro_30d">
                            <button type="submit" class="btn btn-outline btn-sm">+30d Pro</button>
                          </form>
                          <form method="POST" action="/admin/users/subscription">
                            ${csrfInput}
                            <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                            <input type="hidden" name="plan" value="pro_365d">
                            <button type="submit" class="btn btn-outline btn-sm">+1yr Pro</button>
                          </form>
                          <form method="POST" action="/admin/users/subscription">
                            ${csrfInput}
                            <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                            <input type="hidden" name="plan" value="pro_lifetime">
                            <button type="submit" class="btn btn-brand btn-sm">Lifetime</button>
                          </form>
                        </div>

                        <form method="POST" action="/admin/users/subscription" style="display: flex; gap: 6px; align-items: center;">
                          ${csrfInput}
                          <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                          <input type="hidden" name="plan" value="pro_custom">
                          <input type="date" name="expiresDate" required style="padding: 5px 8px; font-size: 0.76rem;">
                          <button type="submit" class="btn btn-primary btn-sm">Set Expiry</button>
                        </form>

                        <div class="inline-btns" style="padding-top: 4px; border-top: 1px solid var(--border);">
                          ${
                            u.isPro === 1
                              ? `<form method="POST" action="/admin/users/subscription">
                                  ${csrfInput}
                                  <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                                  <input type="hidden" name="plan" value="free">
                                  <button type="submit" class="btn btn-outline btn-sm">Revoke Pro</button>
                                </form>`
                              : ''
                          }
                          <form method="POST" action="/admin/users/reset-quota">
                            ${csrfInput}
                            <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                            <button type="submit" class="btn btn-outline btn-sm">Reset AI Quota</button>
                          </form>
                        </div>

                        <form method="POST" action="/admin/users/delete" style="padding-top: 8px; border-top: 1px solid var(--border); display: flex; flex-direction: column; gap: 6px;">
                          ${csrfInput}
                          <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                          <label class="check-label">
                            <input type="checkbox" name="confirm" value="yes" required>
                            <span>Confirm permanent user &amp; backup purge</span>
                          </label>
                          <button type="submit" class="btn btn-danger-soft btn-sm">Delete User Permanently</button>
                        </form>
                      </div>
                    </details>
                  </td>
                </tr>`;
            })
            .join('');

    tabContent = `
      <!-- Manual Pro User Provisioning Card -->
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Manual Provisioning</div>
            <div class="card-title">Add User or Grant Pro Subscription</div>
          </div>
          <span class="badge badge-brand">Auto-links on Google / Apple sign-in</span>
        </div>
        <form method="POST" action="/admin/users/upsert">
          ${csrfInput}
          <div class="form-row">
            <div>
              <label for="u_email">Email Address *</label>
              <input id="u_email" name="email" type="email" required placeholder="customer@example.com">
            </div>
            <div>
              <label for="u_name">Display Name</label>
              <input id="u_name" name="displayName" type="text" placeholder="Optional full name">
            </div>
            <div>
              <label for="u_provider">Auth Provider</label>
              <select id="u_provider" name="provider">
                <option value="google">Google</option>
                <option value="apple">Apple</option>
                <option value="manual">Manual / Promo</option>
              </select>
            </div>
            <div>
              <label for="u_plan">Subscription Plan</label>
              <select id="u_plan" name="plan">
                <option value="pro_lifetime">Pro · Lifetime (No Expiry)</option>
                <option value="pro_365d">Pro · Yearly (+365 days)</option>
                <option value="pro_90d">Pro · Quarterly (+90 days)</option>
                <option value="pro_30d">Pro · Monthly (+30 days)</option>
                <option value="pro_custom">Pro · Custom Expiry Date</option>
                <option value="free">Free Tier</option>
              </select>
            </div>
            <div>
              <label for="u_exp">Custom Expiry (if selected)</label>
              <input id="u_exp" name="expiresDate" type="date">
            </div>
          </div>
          <button type="submit" class="btn btn-primary">Save User &amp; Apply Subscription</button>
        </form>
      </div>

      <!-- Directory Search & Users Table -->
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Directory</div>
            <div class="card-title">Users &amp; Entitlements (${p.users.length})</div>
          </div>
          <form method="GET" action="/admin" style="display: flex; gap: 8px; flex-wrap: wrap;">
            <input type="hidden" name="tab" value="users">
            <input type="text" name="q" value="${escapeHtml(p.searchQuery)}" placeholder="Search email, name, ID..." style="width: 220px;">
            <select name="tier" style="width: 140px;">
              <option value="all" ${p.tierFilter === 'all' ? 'selected' : ''}>All Tiers</option>
              <option value="pro" ${p.tierFilter === 'pro' ? 'selected' : ''}>Active Pro</option>
              <option value="expired" ${p.tierFilter === 'expired' ? 'selected' : ''}>Expired Pro</option>
              <option value="free" ${p.tierFilter === 'free' ? 'selected' : ''}>Free Only</option>
            </select>
            <button type="submit" class="btn btn-outline">Filter</button>
          </form>
        </div>

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Provider</th>
                <th>Subscription</th>
                <th>Cloud Vault</th>
                <th>AI Quota / Joined</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>${userRows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'backups') {
    const rows =
      p.backups.length === 0
        ? `<tr><td colspan="5" class="empty-inline">No cloud sync vaults stored in D1.</td></tr>`
        : p.backups
            .map(
              (b) => `
          <tr>
            <td>
              <div style="font-weight: 700;">${escapeHtml(b.email || 'Unlinked user')}</div>
              <div class="mono muted">${escapeHtml(b.userId)}</div>
            </td>
            <td class="mono">v${b.version}</td>
            <td class="mono">${formatBytes(b.sizeBytes)}</td>
            <td class="mono muted">${formatDateTime(b.lastSyncedAt)}</td>
            <td>
              <form method="POST" action="/admin/backups/delete" style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                ${csrfInput}
                <input type="hidden" name="userId" value="${escapeHtml(b.userId)}">
                <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Confirm</span></label>
                <button type="submit" class="btn btn-danger-soft btn-sm">Delete Vault</button>
              </form>
            </td>
          </tr>`
            )
            .join('');

    tabContent = `
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Cloud Sync Storage</div>
            <div class="card-title">Encrypted Sync Vaults (${p.backups.length} · ${formatBytes(p.metrics.totalBackupBytes)})</div>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Version</th><th>Payload Size</th><th>Last Synced</th><th>Action</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'deletions') {
    const rows =
      p.deletions.length === 0
        ? `<tr><td colspan="5" class="empty-inline">No account deletion requests recorded.</td></tr>`
        : p.deletions
            .map((d) => {
              const badgeCls =
                d.status === 'confirmed'
                  ? 'badge-red'
                  : d.status === 'pending_confirmation'
                  ? 'badge-amber'
                  : d.status === 'purged'
                  ? 'badge-neutral'
                  : 'badge-green';
              const active = d.status === 'pending_confirmation' || d.status === 'confirmed';
              return `
                <tr>
                  <td>
                    <div style="font-weight: 700;">${escapeHtml(d.email)}</div>
                    <div class="muted">${escapeHtml(d.reason || 'No reason provided')}</div>
                  </td>
                  <td><span class="badge ${badgeCls}">${escapeHtml(d.status)}</span></td>
                  <td class="mono muted">${formatDate(d.requestedAt)}</td>
                  <td class="mono">${formatDate(d.scheduledPurgeAt)}</td>
                  <td>
                    ${
                      active
                        ? `<div class="inline-btns">
                            <form method="POST" action="/admin/deletions/cancel">
                              ${csrfInput}
                              <input type="hidden" name="id" value="${escapeHtml(d.id)}">
                              <button type="submit" class="btn btn-outline btn-sm">Cancel</button>
                            </form>
                            <form method="POST" action="/admin/deletions/purge" style="display: inline-flex; align-items: center; gap: 6px;">
                              ${csrfInput}
                              <input type="hidden" name="id" value="${escapeHtml(d.id)}">
                              <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Sure</span></label>
                              <button type="submit" class="btn btn-danger btn-sm">Purge Now</button>
                            </form>
                          </div>`
                        : `<span class="muted">Closed</span>`
                    }
                  </td>
                </tr>`;
            })
            .join('');

    tabContent = `
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Google Play &amp; Apple Compliance</div>
            <div class="card-title">Account Deletion Requests (${p.deletions.length})</div>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Account</th><th>Status</th><th>Requested</th><th>Scheduled Purge</th><th>Actions</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'telemetry') {
    const crashes = p.events.filter((e) => e.eventType === 'crash' || e.eventType === 'exception');
    const actions = p.events.filter((e) => e.eventType !== 'crash' && e.eventType !== 'exception');

    const crashRows =
      crashes.length === 0
        ? `<tr><td colspan="5" class="empty-inline">No crashes or unhandled exceptions logged.</td></tr>`
        : crashes
            .slice(0, 60)
            .map(
              (e) => `
          <tr>
            <td><span class="badge badge-red">${escapeHtml(e.eventType)}</span></td>
            <td><strong>${escapeHtml(e.eventName)}</strong></td>
            <td class="mono muted">${escapeHtml(e.appVersion || '—')} · ${escapeHtml(e.deviceInfo || '—')}</td>
            <td class="mono muted">${formatDateTime(e.createdAt)}</td>
            <td class="mono" style="max-width: 320px; word-break: break-word;">${escapeHtml(e.details || '—')}</td>
          </tr>`
            )
            .join('');

    const actionRows =
      actions.length === 0
        ? `<tr><td colspan="5" class="empty-inline">No telemetry events recorded yet.</td></tr>`
        : actions
            .slice(0, 60)
            .map(
              (e) => `
          <tr>
            <td><span class="badge badge-neutral">${escapeHtml(e.eventType)}</span></td>
            <td><strong>${escapeHtml(e.eventName)}</strong></td>
            <td class="mono muted">${escapeHtml(e.userId || 'anonymous')}</td>
            <td class="mono muted">${formatDateTime(e.createdAt)}</td>
            <td class="mono" style="max-width: 320px; word-break: break-word;">${escapeHtml(e.details || '—')}</td>
          </tr>`
            )
            .join('');

    tabContent = `
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Error Monitoring</div>
            <div class="card-title">Crashes &amp; Exceptions (${crashes.length})</div>
          </div>
          <form method="POST" action="/admin/telemetry/clear" style="display: flex; align-items: center; gap: 8px;">
            ${csrfInput}
            <input type="hidden" name="scope" value="crashes">
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Confirm</span></label>
            <button type="submit" class="btn btn-danger-soft btn-sm">Clear Crashes</button>
          </form>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Type</th><th>Event</th><th>Version / Device</th><th>Time</th><th>Details</th></tr></thead>
            <tbody>${crashRows}</tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Client Stream</div>
            <div class="card-title">Recent Telemetry Actions (${actions.length})</div>
          </div>
          <form method="POST" action="/admin/telemetry/clear" style="display: flex; align-items: center; gap: 8px;">
            ${csrfInput}
            <input type="hidden" name="scope" value="all">
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Confirm</span></label>
            <button type="submit" class="btn btn-outline btn-sm">Clear All Telemetry</button>
          </form>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Type</th><th>Event</th><th>User</th><th>Time</th><th>Details</th></tr></thead>
            <tbody>${actionRows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'audit') {
    const rows =
      p.auditLogs.length === 0
        ? `<tr><td colspan="5" class="empty-inline">No administrative audit entries yet.</td></tr>`
        : p.auditLogs
            .map(
              (a) => `
          <tr>
            <td class="mono muted">${formatDateTime(a.createdAt)}</td>
            <td><span class="badge badge-neutral">${escapeHtml(a.action)}</span></td>
            <td class="mono">${escapeHtml(a.target || '—')}</td>
            <td class="muted">${escapeHtml(a.details || '—')}</td>
            <td class="mono muted">${escapeHtml(a.ipAddress || '—')}</td>
          </tr>`
            )
            .join('');

    tabContent = `
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Immutable Operations Trail</div>
            <div class="card-title">Admin Audit Log (${p.auditLogs.length})</div>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Timestamp</th><th>Action</th><th>Target</th><th>Details</th><th>IP</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  } else if (p.tab === 'danger') {
    tabContent = `
      <div class="banner banner-warn">
        <span>Destructive operations execute immediately against Cloudflare D1 and cannot be undone. Every wipe requires CSRF verification and an exact confirmation phrase.</span>
      </div>

      <div class="grid-3">
        <div class="danger-card">
          <div>
            <div class="eyebrow" style="color: var(--amber);">Scoped Cleanup</div>
            <div class="card-title">Clear Telemetry &amp; Crashes</div>
            <p class="muted" style="margin-top: 6px;">Deletes all rows in <code>telemetry_events</code> and clears the edge memory ring buffer. Users &amp; backups remain intact.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}
            <input type="hidden" name="scope" value="telemetry">
            <div>
              <label>Type <code>CLEAR TELEMETRY</code> to confirm</label>
              <input type="text" name="phrase" required placeholder="CLEAR TELEMETRY" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>I understand telemetry logs will be permanently deleted.</span></label>
            <button type="submit" class="btn btn-danger-soft">Clear All Telemetry</button>
          </form>
        </div>

        <div class="danger-card">
          <div>
            <div class="eyebrow" style="color: var(--amber);">Storage Reset</div>
            <div class="card-title">Delete All Cloud Backups</div>
            <p class="muted" style="margin-top: 6px;">Deletes every vault in <code>sync_records</code> across all users. User accounts &amp; Pro subscriptions remain intact.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}
            <input type="hidden" name="scope" value="backups">
            <div>
              <label>Type <code>DELETE BACKUPS</code> to confirm</label>
              <input type="text" name="phrase" required placeholder="DELETE BACKUPS" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>I understand all cloud sync vaults will be permanently erased.</span></label>
            <button type="submit" class="btn btn-danger-soft">Delete All Backups</button>
          </form>
        </div>

        <div class="danger-card" style="border-color: var(--red); background: #FFF8F7;">
          <div>
            <div class="eyebrow" style="color: var(--red);">Factory Server Wipe</div>
            <div class="card-title" style="color: var(--red);">Delete ALL Server Data</div>
            <p class="muted" style="margin-top: 6px;">Permanently wipes <strong>all users, Pro subscriptions, cloud sync backups, user preferences, telemetry logs, and deletion requests</strong> in D1.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}
            <input type="hidden" name="scope" value="all">
            <div>
              <label>Type <code>DELETE ALL DATA</code> to confirm</label>
              <input type="text" name="phrase" required placeholder="DELETE ALL DATA" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>I permanently confirm wiping every user and database table.</span></label>
            <button type="submit" class="btn btn-danger">Delete ALL Data Permanently</button>
          </form>
        </div>
      </div>
    `;
  }

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="robots" content="noindex,nofollow">
  <title>Hyprwise Console · ${escapeHtml(p.tab)}</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=JetBrains+Mono:wght@500;600;700&display=swap" rel="stylesheet">
  <style>${ADMIN_CSS}</style>
</head>
<body>
  <header class="admin-bar">
    <div class="admin-bar-inner">
      <a href="/admin" class="brand-group">
        ${getHyprwiseIconSvg(26)}
        <span>hyprwise</span>
        <span class="console-pill">Console</span>
      </a>
      <div class="bar-actions">
        <a href="/admin?tab=${p.tab}" class="bar-btn">↻ Refresh</a>
        <form method="POST" action="/admin/logout" style="margin: 0;">
          ${csrfInput}
          <button type="submit" class="bar-btn bar-btn-danger">Sign Out</button>
        </form>
      </div>
    </div>
  </header>

  <nav class="tabs-wrap" aria-label="Console Sections">
    <div class="tabs-inner">
      ${tabLink('overview', 'Overview')}
      ${tabLink('users', 'Users & Pro', p.metrics.totalUsers)}
      ${tabLink('backups', 'Cloud Backups', p.metrics.totalBackups)}
      ${tabLink('deletions', 'Deletions', p.metrics.pendingDeletions)}
      ${tabLink('telemetry', 'Telemetry & Crashes', p.metrics.totalExceptions)}
      ${tabLink('audit', 'Audit Log')}
      ${tabLink('danger', 'Danger Zone', undefined, true)}
    </div>
  </nav>

  <main class="wrap">
    ${
      p.usingDefaultPassword || p.usingDefaultSecret
        ? `<div class="banner banner-warn">
            <span>Security Notice: ${p.usingDefaultPassword ? 'Default ADMIN_PASSWORD is active. ' : ''}${p.usingDefaultSecret ? 'SESSION_SECRET is not set. ' : ''}Rotate via <code>wrangler secret put</code> before production traffic.</span>
          </div>`
        : ''
    }
    ${p.flashOk ? `<div class="banner banner-ok">✓ ${escapeHtml(p.flashOk)}</div>` : ''}
    ${p.flashErr ? `<div class="banner banner-err">⚠ ${escapeHtml(p.flashErr)}</div>` : ''}
    ${tabContent}
  </main>
</body>
</html>`;
}
