// Modern Sidebar Operations Console UI for Hyprwise
// Path-only at /admin, zero client JS (strict CSP script-src 'none'), WCAG AA Hyprwise design tokens.

import { getHyprwiseIconSvg } from '../brand_assets';
import { escapeHtml, HYPRWISE_SHARED_CSS, type TelemetryEvent } from '../compliance_and_admin';

export type AdminTab =
  | 'overview'
  | 'users'
  | 'backups'
  | 'data'
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
  baseCurrency: string | null;
  locale: string | null;
  onboarded: boolean | null;
}

export interface AdminUserInspect {
  user: AdminUserView;
  vaultSummary: Array<{ key: string; count: string }>;
  recentEvents: TelemetryEvent[];
}

export interface AdminBackupView {
  userId: string;
  email: string | null;
  displayName: string | null;
  version: number;
  sizeBytes: number;
  lastSyncedAt: number;
}

export interface AdminBackupInspect {
  userId: string;
  email: string | null;
  displayName: string | null;
  version: number;
  sizeBytes: number;
  lastSyncedAt: number;
  summary: Array<{ key: string; count: string }>;
  prettyJson: string;
  truncated: boolean;
}

export interface AdminPrefRow {
  userId: string;
  email: string | null;
  displayName: string | null;
  locale: string;
  baseCurrency: string;
  onboarded: boolean;
  updatedAt: number;
}

export interface AdminAuditRow {
  id: string;
  action: string;
  target: string | null;
  details: string | null;
  ipAddress: string | null;
  createdAt: number;
}

export interface AdminTableStat {
  table: string;
  rows: number;
  description: string;
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
  dbConnected: boolean;
  searchQuery: string;
  tierFilter: string;
  eventTypeFilter: string;
  openCreate: boolean;
  metrics: {
    totalUsers: number;
    activeProUsers: number;
    expiredProUsers: number;
    freeUsers: number;
    conversionRate: string;
    totalBackups: number;
    totalBackupBytes: number;
    totalExceptions: number;
    totalEvents: number;
    crashFreeRate: string;
    aiQueriesToday: number;
    pendingDeletions: number;
  };
  users: AdminUserView[];
  allUsersCompact: Array<{ id: string; email: string; displayName: string }>;
  inspectedUser: AdminUserInspect | null;
  backups: AdminBackupView[];
  inspectedBackup: AdminBackupInspect | null;
  preferences: AdminPrefRow[];
  deletions: any[];
  events: TelemetryEvent[];
  auditLogs: AdminAuditRow[];
  tableStats: AdminTableStat[];
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

function initials(name: string, email: string): string {
  const src = (name || email || '?').trim();
  const parts = src.split(/[\s@._-]+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return src.slice(0, 2).toUpperCase();
}

const ICONS = {
  overview: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></svg>`,
  telemetry: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>`,
  users: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
  backups: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>`,
  data: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><ellipse cx="12" cy="5" rx="9" ry="3"/><path d="M3 5v14a9 3 0 0 0 18 0V5"/><path d="M3 12a9 3 0 0 0 18 0"/></svg>`,
  deletions: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>`,
  audit: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>`,
  danger: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`,
  search: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  plus: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  refresh: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 16h5v5"/></svg>`,
  logout: `<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>`,
  download: `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`,
  menu: `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
};

const TAB_META: Record<AdminTab, { title: string; subtitle: string }> = {
  overview: {
    title: 'Overview',
    subtitle: 'Live metrics, Pro adoption, 7-day edge telemetry, and production health',
  },
  telemetry: {
    title: 'App Monitoring',
    subtitle: 'Crash-free rate, filtered client telemetry stream, and error diagnostics',
  },
  users: {
    title: 'Users & Subscriptions',
    subtitle: 'Provision accounts, manage Pro entitlements, edit profiles, quotas, and preferences',
  },
  backups: {
    title: 'Cloud Sync Vaults',
    subtitle: 'Inspect, download, edit, or delete user cloud backup JSON records in D1',
  },
  data: {
    title: 'Data & Preferences',
    subtitle: 'Cloudflare D1 table footprint and direct user preference overrides',
  },
  deletions: {
    title: 'Deletion Queue',
    subtitle: '30-day compliance deletion workflow for Google Play & Apple App Store',
  },
  audit: {
    title: 'Audit Log',
    subtitle: 'Immutable trail of every administrative login, edit, export, and wipe',
  },
  danger: {
    title: 'Danger Zone',
    subtitle: 'Scoped resets and full D1 factory wipe protected by CSRF and confirmation phrases',
  },
};

const ADMIN_CSS = `
  ${HYPRWISE_SHARED_CSS}
  :root {
    --sidebar-w: 256px;
    --sidebar-bg: #0F0F11;
    --sidebar-border: #202026;
    --sidebar-hover: #1B1B20;
    --sidebar-active: #222229;
    --sidebar-text: #A4A6B3;
    --sidebar-bright: #FFFFFF;
  }

  body {
    background: var(--bg);
    color: var(--ink);
    min-height: 100vh;
    display: block;
  }

  /* ===== APP SHELL ===== */
  .app-shell {
    display: flex;
    min-height: 100vh;
  }

  /* ===== SIDEBAR ===== */
  .sidebar {
    width: var(--sidebar-w);
    flex-shrink: 0;
    background: var(--sidebar-bg);
    color: var(--sidebar-text);
    border-right: 1px solid var(--sidebar-border);
    display: flex;
    flex-direction: column;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    z-index: 50;
  }
  .sb-brand {
    padding: 18px 18px 14px;
    border-bottom: 1px solid var(--sidebar-border);
  }
  .sb-brand-row {
    display: flex;
    align-items: center;
    gap: 10px;
    text-decoration: none;
    color: var(--sidebar-bright);
  }
  .sb-brand-name {
    font-weight: 800;
    font-size: 1.08rem;
    letter-spacing: -0.03em;
  }
  .sb-ops-pill {
    margin-left: auto;
    font-family: var(--font-mono);
    font-size: 0.66rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    background: rgba(255, 101, 0, 0.16);
    color: #FF8533;
    border: 1px solid rgba(255, 101, 0, 0.32);
    padding: 2px 7px;
    border-radius: 6px;
  }
  .sb-status {
    margin-top: 12px;
    display: flex;
    align-items: center;
    gap: 7px;
    font-family: var(--font-mono);
    font-size: 0.72rem;
    color: #B4B6C2;
    background: #17171B;
    border: 1px solid #24242B;
    padding: 6px 10px;
    border-radius: 8px;
  }
  .status-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    flex-shrink: 0;
  }
  .dot-green { background: #22C55E; box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2); }
  .dot-red { background: #EF4444; box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.2); }

  .sb-nav {
    padding: 14px 12px;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 18px;
  }
  .sb-group-label {
    font-size: 0.66rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.09em;
    color: #6B6D7A;
    padding: 0 10px 6px;
  }
  .sb-list {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }
  .sb-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 9px 10px;
    border-radius: 9px;
    text-decoration: none;
    color: var(--sidebar-text);
    font-size: 0.85rem;
    font-weight: 600;
    transition: background 0.12s ease, color 0.12s ease;
  }
  .sb-item:hover {
    background: var(--sidebar-hover);
    color: var(--sidebar-bright);
  }
  .sb-item.active {
    background: var(--sidebar-active);
    color: var(--sidebar-bright);
    box-shadow: inset 3px 0 0 var(--brand);
  }
  .sb-item.active svg { color: #FF8533; }
  .sb-item.danger { color: #F2766B; }
  .sb-item.danger:hover { background: rgba(180, 35, 24, 0.18); color: #FCA5A5; }
  .sb-item.danger.active { background: rgba(180, 35, 24, 0.26); color: #FFFFFF; box-shadow: inset 3px 0 0 #EF4444; }
  .sb-count {
    margin-left: auto;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    font-weight: 700;
    padding: 2px 7px;
    border-radius: 99px;
    background: #1C1C22;
    color: #C7C9D3;
  }
  .sb-count.alert { background: rgba(239, 68, 68, 0.22); color: #FCA5A5; }
  .sb-count.brand { background: rgba(255, 101, 0, 0.22); color: #FF944D; }

  .sb-footer {
    padding: 12px;
    border-top: 1px solid var(--sidebar-border);
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .sb-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-family: var(--font-mono);
    font-size: 0.69rem;
    color: #7D8090;
    padding: 0 4px;
  }
  .sb-signout {
    width: 100%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 7px;
    padding: 8px 12px;
    border-radius: 8px;
    border: 1px solid #2A2A32;
    background: #17171C;
    color: #E4E4EA;
    font-family: inherit;
    font-size: 0.8rem;
    font-weight: 600;
    cursor: pointer;
  }
  .sb-signout:hover { background: #26191B; border-color: rgba(242, 118, 107, 0.4); color: #FCA5A5; }

  /* ===== MOBILE HEADER & DRAWER ===== */
  .mobile-bar {
    display: none;
    background: var(--sidebar-bg);
    color: #FFFFFF;
    padding: 12px 16px;
    border-bottom: 1px solid var(--sidebar-border);
    position: sticky;
    top: 0;
    z-index: 60;
  }
  .mobile-bar summary {
    list-style: none;
    display: flex;
    align-items: center;
    justify-content: space-between;
    cursor: pointer;
  }
  .mobile-bar summary::-webkit-details-marker { display: none; }
  .mobile-nav-panel {
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--sidebar-border);
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  /* ===== MAIN WORKSPACE ===== */
  .workspace {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
  }
  .topbar {
    position: sticky;
    top: 0;
    z-index: 40;
    background: rgba(255, 255, 255, 0.94);
    backdrop-filter: blur(8px);
    border-bottom: 1px solid var(--border);
    padding: 14px 28px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    flex-wrap: wrap;
  }
  .topbar-title h1 {
    font-size: 1.2rem;
    font-weight: 800;
    letter-spacing: -0.025em;
    color: var(--ink);
    line-height: 1.2;
  }
  .topbar-title p {
    font-size: 0.8rem;
    color: var(--muted);
    margin-top: 2px;
  }
  .topbar-actions {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
  }
  .quick-search {
    position: relative;
    display: flex;
    align-items: center;
  }
  .quick-search svg {
    position: absolute;
    left: 11px;
    color: var(--muted);
    pointer-events: none;
  }
  .quick-search input {
    width: 220px;
    padding: 7px 12px 7px 32px;
    border-radius: 8px;
    border: 1px solid var(--border);
    background: var(--bg);
    font-size: 0.82rem;
  }
  .quick-search input:focus { background: var(--surface); border-color: var(--ink); }

  .content {
    padding: 24px 28px 64px;
    max-width: 1360px;
    width: 100%;
  }

  /* ===== CARDS & SURFACES ===== */
  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 20px;
    margin-bottom: 18px;
    box-shadow: 0 1px 2px rgba(15, 15, 17, 0.03);
  }
  .card-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 16px;
    flex-wrap: wrap;
  }
  .eyebrow {
    font-size: 0.69rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.07em;
    color: var(--muted);
    margin-bottom: 3px;
  }
  .card-title { font-size: 1rem; font-weight: 800; color: var(--ink); letter-spacing: -0.015em; }

  /* ===== KPI CARDS ===== */
  .kpi-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
    margin-bottom: 18px;
  }
  .kpi-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 18px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    box-shadow: 0 1px 2px rgba(15, 15, 17, 0.03);
  }
  .kpi-top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
  }
  .kpi-val {
    font-family: var(--font-mono);
    font-size: 1.75rem;
    font-weight: 800;
    color: var(--ink);
    letter-spacing: -0.03em;
    line-height: 1.1;
  }
  .kpi-sub { font-size: 0.78rem; color: var(--muted); }

  .progress-track {
    background: var(--fill);
    height: 6px;
    border-radius: 99px;
    overflow: hidden;
    width: 100%;
  }
  .progress-fill {
    height: 100%;
    border-radius: 99px;
    background: var(--ink);
  }
  .metric-bar-row { margin-bottom: 11px; }
  .metric-bar-row:last-child { margin-bottom: 0; }
  .metric-bar-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
    font-size: 0.8rem;
    margin-bottom: 5px;
  }
  .legend-dot {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    font-size: 0.72rem;
    font-weight: 600;
    color: var(--muted);
  }
  .legend-dot i { width: 8px; height: 8px; border-radius: 2px; display: inline-block; }

  /* ===== GRIDS & SPLIT INSPECTOR ===== */
  .grid-2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
  .grid-3 { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; }
  .split-layout {
    display: grid;
    grid-template-columns: minmax(0, 1.35fr) minmax(360px, 1fr);
    gap: 18px;
    align-items: start;
  }
  .inspector-card {
    background: var(--surface);
    border: 1px solid #D4D7DD;
    border-top: 3px solid var(--brand);
    border-radius: var(--radius);
    padding: 20px;
    position: sticky;
    top: 84px;
    box-shadow: 0 8px 24px rgba(15, 15, 17, 0.06);
  }
  .inspector-section {
    padding-top: 16px;
    margin-top: 16px;
    border-top: 1px solid var(--border);
  }

  /* ===== BADGES, PILLS & AVATAR ===== */
  .avatar {
    width: 34px;
    height: 34px;
    border-radius: 9px;
    background: var(--ink);
    color: #FFFFFF;
    font-family: var(--font-mono);
    font-size: 0.74rem;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  .avatar-pro { background: linear-gradient(135deg, #FF6500, #B84400); }
  .user-cell { display: flex; align-items: center; gap: 10px; min-width: 0; }
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 8px;
    border-radius: 6px;
    font-size: 0.71rem;
    font-weight: 700;
    font-family: var(--font-mono);
    white-space: nowrap;
  }
  .badge-green { background: var(--green-bg); color: var(--green); }
  .badge-red { background: var(--red-bg); color: var(--red); }
  .badge-amber { background: var(--amber-bg); color: var(--amber); }
  .badge-brand { background: var(--brand-bg); color: var(--brand-text); }
  .badge-neutral { background: var(--fill); color: var(--muted); }

  .pill-tabs {
    display: inline-flex;
    background: var(--fill);
    padding: 3px;
    border-radius: 9px;
    gap: 2px;
    flex-wrap: wrap;
  }
  .pill-tab {
    padding: 6px 11px;
    border-radius: 7px;
    text-decoration: none;
    font-size: 0.78rem;
    font-weight: 700;
    color: var(--muted);
    white-space: nowrap;
  }
  .pill-tab:hover { color: var(--ink); }
  .pill-tab.active {
    background: var(--surface);
    color: var(--ink);
    box-shadow: 0 1px 2px rgba(15, 15, 17, 0.08);
  }

  .summary-chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
  .summary-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 9px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 7px;
    font-size: 0.75rem;
  }
  .summary-chip b { font-family: var(--font-mono); color: var(--ink); }

  /* ===== BANNERS ===== */
  .banner {
    padding: 12px 16px;
    border-radius: 10px;
    margin-bottom: 16px;
    font-size: 0.85rem;
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

  /* ===== TABLES ===== */
  .table-wrap {
    overflow-x: auto;
    border: 1px solid var(--border);
    border-radius: 10px;
  }
  table { width: 100%; border-collapse: collapse; font-size: 0.84rem; text-align: left; }
  th {
    background: #FAFAFB;
    color: var(--muted);
    font-weight: 700;
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
    white-space: nowrap;
    font-size: 0.71rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  td {
    padding: 12px 14px;
    border-bottom: 1px solid var(--border);
    vertical-align: middle;
    color: var(--ink);
  }
  tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: #FAFAFB; }
  tr.row-selected { background: #FFF7F2 !important; }
  tr.row-selected td:first-child { box-shadow: inset 3px 0 0 var(--brand); }

  .mono { font-family: var(--font-mono); font-size: 0.78rem; }
  .muted { color: var(--muted); font-size: 0.78rem; }

  /* ===== FORMS & BUTTONS ===== */
  .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); gap: 12px; margin-bottom: 12px; }
  .form-grid-2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; margin-bottom: 10px; }
  label { display: block; font-size: 0.74rem; font-weight: 700; color: var(--ink); margin-bottom: 5px; }
  input, select, textarea {
    width: 100%;
    padding: 8px 11px;
    border: 1px solid var(--border);
    border-radius: 8px;
    background: var(--surface);
    color: var(--ink);
    font-family: inherit;
    font-size: 0.84rem;
  }
  textarea.json-editor {
    font-family: var(--font-mono);
    font-size: 0.78rem;
    line-height: 1.5;
    min-height: 360px;
    background: #0F0F11;
    color: #E5E7EB;
    border-color: #27272A;
    padding: 14px;
    resize: vertical;
  }
  input:focus, select:focus, textarea:focus { outline: none; border-color: var(--ink); }
  textarea.json-editor:focus { border-color: var(--brand); }

  .btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 0.81rem;
    font-weight: 700;
    font-family: inherit;
    cursor: pointer;
    border: 1px solid transparent;
    text-decoration: none;
    white-space: nowrap;
  }
  .btn-sm { padding: 6px 10px; font-size: 0.76rem; }
  .btn-xs { padding: 4px 8px; font-size: 0.72rem; }
  .btn-primary { background: var(--ink); color: #FFFFFF; }
  .btn-primary:hover { background: #26262B; }
  .btn-brand { background: var(--brand); color: #FFFFFF; }
  .btn-brand:hover { background: #E05800; }
  .btn-outline { background: var(--surface); color: var(--ink); border-color: var(--border); }
  .btn-outline:hover { background: var(--fill); }
  .btn-danger { background: var(--red); color: #FFFFFF; }
  .btn-danger:hover { background: #961D14; }
  .btn-danger-soft { background: var(--red-bg); color: var(--red); border-color: #F5C2BE; }
  .btn-danger-soft:hover { background: #FADAD7; }
  .inline-btns { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }

  details.collapsible-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    margin-bottom: 18px;
    overflow: hidden;
  }
  details.collapsible-card summary {
    list-style: none;
    padding: 15px 20px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    font-weight: 800;
    font-size: 0.92rem;
    color: var(--ink);
  }
  details.collapsible-card summary::-webkit-details-marker { display: none; }
  details.collapsible-card[open] summary {
    border-bottom: 1px solid var(--border);
    background: #FAFAFB;
  }
  .collapsible-body { padding: 18px 20px; }

  .health-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 10px 0;
    border-bottom: 1px solid var(--border);
  }
  .health-row:last-child { border-bottom: none; padding-bottom: 0; }
  .health-row:first-child { padding-top: 0; }

  .empty-state {
    text-align: center;
    padding: 34px 16px;
    color: var(--muted);
  }
  .empty-title { font-weight: 700; color: var(--ink); font-size: 0.9rem; margin-bottom: 4px; }
  .empty-sub { font-size: 0.8rem; color: var(--muted); }

  .danger-card {
    border: 1px solid #F5C2BE;
    background: #FFFDFD;
    border-radius: var(--radius);
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .check-label {
    display: flex;
    align-items: flex-start;
    gap: 8px;
    font-size: 0.79rem;
    font-weight: 500;
    color: var(--muted);
    cursor: pointer;
    margin: 0;
  }
  .check-label input[type="checkbox"] { width: 15px; height: 15px; margin-top: 2px; accent-color: var(--red); flex-shrink: 0; }

  @media (max-width: 1180px) {
    .kpi-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    .split-layout { grid-template-columns: 1fr; }
    .inspector-card { position: static; }
  }
  @media (max-width: 960px) {
    .sidebar { display: none; }
    .mobile-bar { display: block; }
    .topbar { padding: 14px 16px; position: static; }
    .content { padding: 16px 16px 48px; }
    .grid-2, .grid-3 { grid-template-columns: 1fr; }
    .quick-search input { width: 160px; }
  }
  @media (max-width: 560px) {
    .kpi-grid { grid-template-columns: 1fr; }
    .form-grid-2 { grid-template-columns: 1fr; }
  }
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
<body style="display: flex; justify-content: center; align-items: center; padding: 24px; background: #0F0F11;">
  <div style="width: 100%; max-width: 410px;">
    <div style="background: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 24px 60px rgba(0,0,0,0.45);">
      <div style="background: #141417; padding: 30px 26px 24px; text-align: center; border-bottom: 1px solid #26262C;">
        <div style="display: inline-block; margin-bottom: 12px;">${getHyprwiseIconSvg(46)}</div>
        <div style="color: #FFFFFF; font-size: 1.35rem; font-weight: 800; letter-spacing: -0.03em;">hyprwise <span style="color: #FF6500;">ops</span></div>
        <div style="color: #9A9CA8; font-size: 0.82rem; margin-top: 4px;">Server control, subscriptions &amp; live monitoring</div>
      </div>
      <div style="padding: 26px;">
        ${opts?.error ? `<div class="banner banner-err" style="margin-bottom: 16px;">${escapeHtml(opts.error)}</div>` : ''}
        <form method="POST" action="/admin/login">
          <div style="margin-bottom: 16px;">
            <label for="password">Administrator Password</label>
            <input type="password" id="password" name="password" required autocomplete="current-password" placeholder="Enter console password" autofocus style="padding: 10px 12px;">
          </div>
          <button type="submit" class="btn btn-primary" style="width: 100%; padding: 11px; font-size: 0.88rem;">Sign In to Console</button>
        </form>
        <div class="muted" style="text-align: center; margin-top: 16px; font-size: 0.73rem;">
          HMAC-SHA256 cookie · CSRF token · Brute-force lockout active
        </div>
      </div>
    </div>
  </div>
</body>
</html>`;
}

export function renderAdminDashboard(p: AdminDashboardProps): string {
  const csrfInput = `<input type="hidden" name="_csrf" value="${escapeHtml(p.csrfToken)}">`;
  const meta = TAB_META[p.tab];

  const navItem = (
    id: AdminTab,
    label: string,
    icon: string,
    count?: number,
    badgeTone: 'default' | 'alert' | 'brand' = 'default',
    isDanger = false
  ) => `
    <a href="/admin?tab=${id}" class="sb-item ${p.tab === id ? 'active' : ''} ${isDanger ? 'danger' : ''}">
      ${icon}
      <span>${label}</span>
      ${
        count !== undefined
          ? `<span class="sb-count ${badgeTone !== 'default' ? badgeTone : ''}">${count}</span>`
          : ''
      }
    </a>
  `;

  const navGroupsHtml = `
    <div>
      <div class="sb-group-label">Monitor</div>
      <div class="sb-list">
        ${navItem('overview', 'Overview', ICONS.overview)}
        ${navItem('telemetry', 'App Monitoring', ICONS.telemetry, p.metrics.totalExceptions > 0 ? p.metrics.totalExceptions : undefined, p.metrics.totalExceptions > 0 ? 'alert' : 'default')}
      </div>
    </div>
    <div>
      <div class="sb-group-label">Data &amp; Users</div>
      <div class="sb-list">
        ${navItem('users', 'Users & Pro', ICONS.users, p.metrics.totalUsers, p.metrics.activeProUsers > 0 ? 'brand' : 'default')}
        ${navItem('backups', 'Cloud Vaults', ICONS.backups, p.metrics.totalBackups)}
        ${navItem('data', 'Data & Prefs', ICONS.data, p.preferences.length)}
      </div>
    </div>
    <div>
      <div class="sb-group-label">System</div>
      <div class="sb-list">
        ${navItem('deletions', 'Deletions', ICONS.deletions, p.metrics.pendingDeletions > 0 ? p.metrics.pendingDeletions : undefined, p.metrics.pendingDeletions > 0 ? 'alert' : 'default')}
        ${navItem('audit', 'Audit Log', ICONS.audit)}
        ${navItem('danger', 'Danger Zone', ICONS.danger, undefined, 'default', true)}
      </div>
    </div>
  `;

  const proPct =
    p.metrics.totalUsers > 0
      ? Math.round((p.metrics.activeProUsers / p.metrics.totalUsers) * 100)
      : 0;

  let mainContent = '';

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  if (p.tab === 'overview') {
    const healthRows = p.healthChecks
      .map(
        (h) => `
        <div class="health-row">
          <div>
            <div style="font-weight: 700; font-size: 0.84rem;">${escapeHtml(h.label)}</div>
            <div class="muted" style="font-size: 0.75rem;">${escapeHtml(h.detail)}</div>
          </div>
          <span class="badge ${h.ok ? 'badge-green' : h.critical ? 'badge-red' : 'badge-amber'}">
            ${h.ok ? 'ONLINE' : h.critical ? 'ACTION' : 'OPTIONAL'}
          </span>
        </div>`
      )
      .join('');

    const recentAudit =
      p.auditLogs.length === 0
        ? `<div class="empty-state"><div class="empty-title">No admin activity yet</div><div class="empty-sub">Actions you take will be logged here.</div></div>`
        : p.auditLogs
            .slice(0, 6)
            .map(
              (a) => `
          <div class="health-row">
            <div style="min-width: 0;">
              <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                <span class="badge badge-neutral">${escapeHtml(a.action)}</span>
                <span class="mono" style="font-weight: 600; color: var(--ink);">${escapeHtml(a.target || '—')}</span>
              </div>
              <div class="muted" style="margin-top: 2px; font-size: 0.74rem;">${escapeHtml(a.details || '')}</div>
            </div>
            <span class="mono muted" style="white-space: nowrap; font-size: 0.72rem;">${formatDateTime(a.createdAt).slice(5, 16)}</span>
          </div>`
            )
            .join('');

    mainContent = `
      <div class="kpi-grid">
        <div class="kpi-card">
          <div class="kpi-top">
            <div class="eyebrow" style="margin: 0;">Users &amp; Pro</div>
            <span class="badge badge-brand">${escapeHtml(p.metrics.conversionRate)} Pro</span>
          </div>
          <div class="kpi-val">${p.metrics.totalUsers}</div>
          <div class="progress-track"><div class="progress-fill" style="width: ${Math.max(proPct, p.metrics.activeProUsers > 0 ? 4 : 0)}%; background: var(--brand);"></div></div>
          <div class="kpi-sub">${p.metrics.activeProUsers} active Pro · ${p.metrics.freeUsers} Free · ${p.metrics.expiredProUsers} expired</div>
        </div>

        <div class="kpi-card">
          <div class="kpi-top">
            <div class="eyebrow" style="margin: 0;">Cloud Sync Vaults</div>
            <a href="/admin?tab=backups" class="muted" style="text-decoration: none; font-weight: 700;">Inspect →</a>
          </div>
          <div class="kpi-val">${p.metrics.totalBackups}</div>
          <div class="kpi-sub">${formatBytes(p.metrics.totalBackupBytes)} stored across D1 vaults</div>
        </div>

        <div class="kpi-card">
          <div class="kpi-top">
            <div class="eyebrow" style="margin: 0;">App Stability (7d)</div>
            <span class="badge ${p.metrics.totalExceptions > 0 ? 'badge-red' : 'badge-green'}">${escapeHtml(p.metrics.crashFreeRate)}</span>
          </div>
          <div class="kpi-val" style="color: ${p.metrics.totalExceptions > 0 ? 'var(--red)' : 'var(--green)'};">${p.metrics.totalExceptions}</div>
          <div class="kpi-sub">crashes/errors · ${p.metrics.totalEvents} total events</div>
        </div>

        <div class="kpi-card">
          <div class="kpi-top">
            <div class="eyebrow" style="margin: 0;">AI Queries Today</div>
            <span class="badge badge-neutral">Gemini 2.5</span>
          </div>
          <div class="kpi-val">${p.metrics.aiQueriesToday}</div>
          <div class="kpi-sub">${p.metrics.pendingDeletions} pending account deletions</div>
        </div>
      </div>

      ${p.analyticsHtml}

      <div class="grid-2">
        <div class="card" style="margin-bottom: 0;">
          <div class="card-head">
            <div>
              <div class="eyebrow">System Monitor</div>
              <div class="card-title">Production Health &amp; Secrets</div>
            </div>
            <a href="/health" target="_blank" class="btn btn-outline btn-xs">Health JSON ↗</a>
          </div>
          <div>${healthRows}</div>
        </div>

        <div class="card" style="margin-bottom: 0;">
          <div class="card-head">
            <div>
              <div class="eyebrow">Operations Stream</div>
              <div class="card-title">Recent Console Activity</div>
            </div>
            <a href="/admin?tab=audit" class="btn btn-outline btn-xs">Full Audit →</a>
          </div>
          <div>${recentAudit}</div>
        </div>
      </div>
    `;
  }

  // ==========================================
  // TAB 2: USERS & SUBSCRIPTIONS (WITH SPLIT-PANE INSPECTOR)
  // ==========================================
  else if (p.tab === 'users') {
    const inspected = p.inspectedUser;

    const userRows =
      p.users.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">No users match this filter</div><div class="empty-sub">Use "+ Provision New User / Pro" above to create an account or grant Pro.</div></div></td></tr>`
        : p.users
            .map((u) => {
              const isSelected = inspected?.user.id === u.id;
              const tierBadge = u.activePro
                ? `<span class="badge badge-green">PRO · ${u.proExpiresAt ? formatDate(u.proExpiresAt) : 'Lifetime'}</span>`
                : u.expiredPro
                ? `<span class="badge badge-amber">EXPIRED</span>`
                : `<span class="badge badge-neutral">FREE</span>`;

              const vaultMeta = u.backupVersion
                ? `<span class="mono">v${u.backupVersion}</span> <span class="muted">(${formatBytes(u.backupBytes)})</span>`
                : `<span class="muted">—</span>`;

              return `
                <tr class="${isSelected ? 'row-selected' : ''}">
                  <td>
                    <div class="user-cell">
                      <span class="avatar ${u.activePro ? 'avatar-pro' : ''}">${escapeHtml(initials(u.displayName, u.email))}</span>
                      <div style="min-width: 0;">
                        <div style="font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${escapeHtml(u.displayName)}</div>
                        <div class="mono muted" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${escapeHtml(u.email)}</div>
                      </div>
                    </div>
                  </td>
                  <td>${tierBadge}<div class="muted" style="margin-top: 2px;">${escapeHtml(u.provider)}${u.baseCurrency ? ` · ${escapeHtml(u.baseCurrency)}` : ''}</div></td>
                  <td>${vaultMeta}</td>
                  <td class="mono">${u.dailyAiQueriesUsed}/${u.activePro ? '∞' : '5'}<div class="muted">${formatDate(u.createdAt)}</div></td>
                  <td style="text-align: right;">
                    <a href="/admin?tab=users&inspect=${encodeURIComponent(u.id)}${p.tierFilter !== 'all' ? `&tier=${encodeURIComponent(p.tierFilter)}` : ''}${p.searchQuery ? `&q=${encodeURIComponent(p.searchQuery)}` : ''}" class="btn ${isSelected ? 'btn-brand' : 'btn-outline'} btn-xs">
                      ${isSelected ? 'Editing' : 'Inspect →'}
                    </a>
                  </td>
                </tr>`;
            })
            .join('');

    const inspectorHtml = inspected
      ? (() => {
          const u = inspected.user;
          const expInputVal = u.proExpiresAt ? formatDate(u.proExpiresAt) : '';
          const vaultChips =
            inspected.vaultSummary.length > 0
              ? `<div class="summary-chips">${inspected.vaultSummary
                  .map((s) => `<span class="summary-chip"><span>${escapeHtml(s.key)}</span><b>${escapeHtml(s.count)}</b></span>`)
                  .join('')}</div>`
              : '';
          const userEventsHtml =
            inspected.recentEvents.length === 0
              ? `<div class="muted" style="font-size: 0.78rem;">No recent telemetry recorded for this user.</div>`
              : inspected.recentEvents
                  .slice(0, 5)
                  .map(
                    (e) => `
                  <div style="display: flex; justify-content: space-between; gap: 8px; padding: 6px 0; border-bottom: 1px solid var(--border); font-size: 0.77rem;">
                    <span><span class="badge ${e.eventType === 'crash' || e.eventType === 'exception' ? 'badge-red' : 'badge-neutral'}" style="margin-right: 5px;">${escapeHtml(e.eventType)}</span><strong>${escapeHtml(e.eventName)}</strong></span>
                    <span class="mono muted">${formatDateTime(e.createdAt).slice(5, 16)}</span>
                  </div>`
                  )
                  .join('');

          return `
            <aside class="inspector-card">
              <div style="display: flex; align-items: flex-start; justify-content: space-between; gap: 10px;">
                <div class="user-cell">
                  <span class="avatar ${u.activePro ? 'avatar-pro' : ''}" style="width: 40px; height: 40px; font-size: 0.85rem;">${escapeHtml(initials(u.displayName, u.email))}</span>
                  <div>
                    <div style="font-weight: 800; font-size: 1rem;">${escapeHtml(u.displayName)}</div>
                    <div class="mono muted">${escapeHtml(u.email)}</div>
                    <div class="mono" style="font-size: 0.69rem; color: var(--muted);">${escapeHtml(u.id)}</div>
                  </div>
                </div>
                <a href="/admin?tab=users" class="btn btn-outline btn-xs">✕</a>
              </div>

              <!-- 1. Pro Subscription Controls -->
              <div class="inspector-section">
                <div class="eyebrow">Pro Subscription Control</div>
                <div style="margin: 6px 0 10px;">
                  ${
                    u.activePro
                      ? `<span class="badge badge-green">ACTIVE PRO · ${u.proExpiresAt ? `Expires ${formatDate(u.proExpiresAt)}` : 'Lifetime'}</span>`
                      : u.expiredPro
                      ? `<span class="badge badge-amber">EXPIRED PRO · ${formatDate(u.proExpiresAt)}</span>`
                      : `<span class="badge badge-neutral">FREE TIER</span>`
                  }
                </div>
                <div class="inline-btns" style="margin-bottom: 10px;">
                  <form method="POST" action="/admin/users/subscription">
                    ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="pro_30d">
                    <button type="submit" class="btn btn-outline btn-xs">+30d</button>
                  </form>
                  <form method="POST" action="/admin/users/subscription">
                    ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="pro_90d">
                    <button type="submit" class="btn btn-outline btn-xs">+90d</button>
                  </form>
                  <form method="POST" action="/admin/users/subscription">
                    ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="pro_365d">
                    <button type="submit" class="btn btn-outline btn-xs">+1yr</button>
                  </form>
                  <form method="POST" action="/admin/users/subscription">
                    ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="pro_lifetime">
                    <button type="submit" class="btn btn-brand btn-xs">Lifetime</button>
                  </form>
                  ${
                    u.isPro === 1
                      ? `<form method="POST" action="/admin/users/subscription">
                          ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="free">
                          <button type="submit" class="btn btn-danger-soft btn-xs">Revoke</button>
                        </form>`
                      : ''
                  }
                </div>
                <form method="POST" action="/admin/users/subscription" style="display: flex; gap: 6px;">
                  ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}"><input type="hidden" name="plan" value="pro_custom">
                  <input type="date" name="expiresDate" value="${escapeHtml(expInputVal)}" required style="padding: 6px 8px; font-size: 0.78rem;">
                  <button type="submit" class="btn btn-primary btn-xs">Set Expiry</button>
                </form>
              </div>

              <!-- 2. Edit Profile, Preferences & AI Quota -->
              <div class="inspector-section">
                <div class="eyebrow" style="margin-bottom: 10px;">Edit Server Record &amp; Preferences</div>
                <form method="POST" action="/admin/users/update">
                  ${csrfInput}
                  <input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                  <div class="form-grid-2">
                    <div>
                      <label>Display Name</label>
                      <input type="text" name="displayName" value="${escapeHtml(u.displayName)}" required>
                    </div>
                    <div>
                      <label>Provider</label>
                      <select name="provider">
                        <option value="google" ${u.provider === 'google' ? 'selected' : ''}>Google</option>
                        <option value="apple" ${u.provider === 'apple' ? 'selected' : ''}>Apple</option>
                        <option value="manual" ${u.provider === 'manual' ? 'selected' : ''}>Manual</option>
                      </select>
                    </div>
                  </div>
                  <div style="margin-bottom: 10px;">
                    <label>Email</label>
                    <input type="email" name="email" value="${escapeHtml(u.email)}" required>
                  </div>
                  <div class="form-grid-2">
                    <div>
                      <label>Base Currency</label>
                      <input type="text" name="baseCurrency" value="${escapeHtml(u.baseCurrency || '')}" placeholder="USD / NPR / AUD" maxlength="6">
                    </div>
                    <div>
                      <label>Locale</label>
                      <input type="text" name="locale" value="${escapeHtml(u.locale || '')}" placeholder="en / ne" maxlength="12">
                    </div>
                  </div>
                  <div class="form-grid-2">
                    <div>
                      <label>AI Queries Used Today</label>
                      <input type="number" name="dailyAiQueriesCount" min="0" max="10000" value="${u.dailyAiQueriesUsed}">
                    </div>
                    <div>
                      <label>Onboarded</label>
                      <select name="onboarded">
                        <option value="1" ${u.onboarded !== false ? 'selected' : ''}>Yes (1)</option>
                        <option value="0" ${u.onboarded === false ? 'selected' : ''}>No (0)</option>
                      </select>
                    </div>
                  </div>
                  <div class="inline-btns" style="margin-top: 6px;">
                    <button type="submit" class="btn btn-primary btn-sm">Save Changes</button>
                  </div>
                </form>
                <form method="POST" action="/admin/users/reset-quota" style="margin-top: 8px;">
                  ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                  <button type="submit" class="btn btn-outline btn-xs">Quick Reset AI Quota to 0</button>
                </form>
              </div>

              <!-- 3. Cloud Sync Vault Summary -->
              <div class="inspector-section">
                <div style="display: flex; justify-content: space-between; align-items: center; gap: 8px;">
                  <div>
                    <div class="eyebrow">Cloud Sync Vault</div>
                    <div class="mono" style="font-size: 0.8rem; font-weight: 700;">
                      ${u.backupVersion ? `v${u.backupVersion} · ${formatBytes(u.backupBytes)}` : 'No backup stored'}
                    </div>
                  </div>
                  ${
                    u.backupVersion
                      ? `<div class="inline-btns">
                          <a href="/admin?tab=backups&inspect=${encodeURIComponent(u.id)}" class="btn btn-outline btn-xs">Edit JSON</a>
                          <a href="/admin/backups/export?userId=${encodeURIComponent(u.id)}" class="btn btn-outline btn-xs">${ICONS.download}</a>
                        </div>`
                      : ''
                  }
                </div>
                ${vaultChips}
              </div>

              <!-- 4. Recent Telemetry -->
              <div class="inspector-section">
                <div class="eyebrow" style="margin-bottom: 6px;">Recent User Activity</div>
                ${userEventsHtml}
              </div>

              <!-- 5. Permanent Delete -->
              <div class="inspector-section">
                <form method="POST" action="/admin/users/delete" style="display: flex; flex-direction: column; gap: 8px;">
                  ${csrfInput}<input type="hidden" name="userId" value="${escapeHtml(u.id)}">
                  <label class="check-label">
                    <input type="checkbox" name="confirm" value="yes" required>
                    <span>Permanently delete user, cloud vault, preferences &amp; logs</span>
                  </label>
                  <button type="submit" class="btn btn-danger-soft btn-sm">Delete User Permanently</button>
                </form>
              </div>
            </aside>
          `;
        })()
      : '';

    const tierLink = (tier: string, label: string) =>
      `<a href="/admin?tab=users&tier=${tier}${p.searchQuery ? `&q=${encodeURIComponent(p.searchQuery)}` : ''}" class="pill-tab ${p.tierFilter === tier ? 'active' : ''}">${label}</a>`;

    mainContent = `
      <details class="collapsible-card" ${p.openCreate || p.metrics.totalUsers === 0 ? 'open' : ''}>
        <summary>
          <span style="display: inline-flex; align-items: center; gap: 8px;">
            <span style="display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 7px; background: var(--brand-bg); color: var(--brand-text);">${ICONS.plus}</span>
            Provision New User or Grant Pro Subscription
          </span>
          <span class="badge badge-brand">Auto-links on Google / Apple sign-in</span>
        </summary>
        <div class="collapsible-body">
          <form method="POST" action="/admin/users/upsert">
            ${csrfInput}
            <div class="form-grid">
              <div>
                <label for="u_email">Email Address *</label>
                <input id="u_email" name="email" type="email" required placeholder="customer@example.com">
              </div>
              <div>
                <label for="u_name">Display Name</label>
                <input id="u_name" name="displayName" type="text" placeholder="Optional name">
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
                  <option value="pro_lifetime">Pro · Lifetime</option>
                  <option value="pro_365d">Pro · Yearly (+365d)</option>
                  <option value="pro_90d">Pro · Quarterly (+90d)</option>
                  <option value="pro_30d">Pro · Monthly (+30d)</option>
                  <option value="pro_custom">Pro · Custom Date</option>
                  <option value="free">Free Tier</option>
                </select>
              </div>
              <div>
                <label for="u_exp">Custom Expiry Date</label>
                <input id="u_exp" name="expiresDate" type="date">
              </div>
              <div>
                <label for="u_cur">Base Currency</label>
                <input id="u_cur" name="baseCurrency" type="text" placeholder="USD / NPR / AUD" maxlength="6">
              </div>
            </div>
            <button type="submit" class="btn btn-primary">Save User &amp; Apply Plan</button>
          </form>
        </div>
      </details>

      <div class="${inspected ? 'split-layout' : ''}">
        <div class="card" style="margin-bottom: 0;">
          <div class="card-head">
            <div class="pill-tabs">
              ${tierLink('all', `All (${p.metrics.totalUsers})`)}
              ${tierLink('pro', `Active Pro (${p.metrics.activeProUsers})`)}
              ${tierLink('expired', `Expired (${p.metrics.expiredProUsers})`)}
              ${tierLink('free', `Free (${p.metrics.freeUsers})`)}
            </div>
            <div class="inline-btns">
              <form method="GET" action="/admin" style="display: flex; gap: 6px;">
                <input type="hidden" name="tab" value="users">
                <input type="hidden" name="tier" value="${escapeHtml(p.tierFilter)}">
                <input type="text" name="q" value="${escapeHtml(p.searchQuery)}" placeholder="Filter email, name, ID..." style="width: 190px; padding: 6px 10px; font-size: 0.8rem;">
                <button type="submit" class="btn btn-outline btn-sm">Search</button>
              </form>
              <a href="/admin/export/users.csv" class="btn btn-outline btn-sm">${ICONS.download} CSV</a>
            </div>
          </div>

          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>User</th>
                  <th>Tier / Provider</th>
                  <th>Cloud Vault</th>
                  <th>AI / Joined</th>
                  <th style="text-align: right;">Inspector</th>
                </tr>
              </thead>
              <tbody>${userRows}</tbody>
            </table>
          </div>
        </div>
        ${inspectorHtml}
      </div>
    `;
  }

  // ==========================================
  // TAB 3: CLOUD SYNC VAULTS (INSPECTOR + JSON EDITOR)
  // ==========================================
  else if (p.tab === 'backups') {
    const inspected = p.inspectedBackup;

    const rows =
      p.backups.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">No cloud sync vaults yet</div><div class="empty-sub">When Pro users sync their app data, their JSON vaults appear here for inspection and editing.</div></div></td></tr>`
        : p.backups
            .map((b) => {
              const isSelected = inspected?.userId === b.userId;
              return `
                <tr class="${isSelected ? 'row-selected' : ''}">
                  <td>
                    <div style="font-weight: 700;">${escapeHtml(b.email || 'Unlinked user')}</div>
                    <div class="mono muted">${escapeHtml(b.userId)}</div>
                  </td>
                  <td><span class="badge badge-neutral">v${b.version}</span></td>
                  <td class="mono">${formatBytes(b.sizeBytes)}</td>
                  <td class="mono muted">${formatDateTime(b.lastSyncedAt)}</td>
                  <td style="text-align: right;">
                    <div class="inline-btns" style="justify-content: flex-end;">
                      <a href="/admin?tab=backups&inspect=${encodeURIComponent(b.userId)}" class="btn ${isSelected ? 'btn-brand' : 'btn-outline'} btn-xs">${isSelected ? 'Editing' : 'Inspect / Edit'}</a>
                      <a href="/admin/backups/export?userId=${encodeURIComponent(b.userId)}" class="btn btn-outline btn-xs">${ICONS.download} JSON</a>
                    </div>
                  </td>
                </tr>`;
            })
            .join('');

    const editorHtml = inspected
      ? `
        <div class="card" style="border-top: 3px solid var(--brand);">
          <div class="card-head">
            <div>
              <div class="eyebrow">Live Vault JSON Editor · v${inspected.version} · ${formatBytes(inspected.sizeBytes)}</div>
              <div class="card-title">${escapeHtml(inspected.email || inspected.userId)}</div>
            </div>
            <div class="inline-btns">
              <a href="/admin/backups/export?userId=${encodeURIComponent(inspected.userId)}" class="btn btn-outline btn-sm">${ICONS.download} Download Full JSON</a>
              <a href="/admin?tab=backups" class="btn btn-outline btn-sm">Close</a>
            </div>
          </div>

          <div class="summary-chips" style="margin-bottom: 14px;">
            ${inspected.summary
              .map((s) => `<span class="summary-chip"><span>${escapeHtml(s.key)}</span><b>${escapeHtml(s.count)}</b></span>`)
              .join('')}
          </div>

          ${
            inspected.truncated
              ? `<div class="banner banner-warn">This payload exceeds 60 KB in-browser preview. Download full JSON before editing to avoid truncation.</div>`
              : ''
          }

          <form method="POST" action="/admin/backups/update">
            ${csrfInput}
            <input type="hidden" name="userId" value="${escapeHtml(inspected.userId)}">
            <label for="vault_json">Sync Payload JSON (validated before saving; increments version to v${inspected.version + 1})</label>
            <textarea id="vault_json" name="payload" class="json-editor" spellcheck="false" ${inspected.truncated ? 'readonly' : ''}>${escapeHtml(inspected.prettyJson)}</textarea>
            <div style="display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-top: 12px; flex-wrap: wrap;">
              ${
                inspected.truncated
                  ? `<span class="muted">In-browser save disabled for payloads over 60 KB.</span>`
                  : `<button type="submit" class="btn btn-primary">Validate &amp; Save Vault v${inspected.version + 1}</button>`
              }
            </div>
          </form>

          <div class="inspector-section">
            <form method="POST" action="/admin/backups/delete" style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
              ${csrfInput}
              <input type="hidden" name="userId" value="${escapeHtml(inspected.userId)}">
              <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Permanently delete this cloud sync vault</span></label>
              <button type="submit" class="btn btn-danger-soft btn-sm">Delete Vault</button>
            </form>
          </div>
        </div>
      `
      : '';

    mainContent = `
      ${editorHtml}
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Cloudflare D1 · sync_records</div>
            <div class="card-title">Stored Vaults (${p.backups.length} · ${formatBytes(p.metrics.totalBackupBytes)})</div>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Account</th><th>Version</th><th>Size</th><th>Last Synced</th><th style="text-align: right;">Actions</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================
  // TAB 4: DATA & PREFERENCES
  // ==========================================
  else if (p.tab === 'data') {
    const tableCards = p.tableStats
      .map(
        (t) => `
        <div class="kpi-card" style="padding: 15px;">
          <div class="kpi-top">
            <span class="mono" style="font-weight: 700; color: var(--ink);">${escapeHtml(t.table)}</span>
            <span class="badge badge-neutral">D1</span>
          </div>
          <div class="kpi-val" style="font-size: 1.45rem;">${t.rows}</div>
          <div class="kpi-sub">${escapeHtml(t.description)}</div>
        </div>`
      )
      .join('');

    const prefRows =
      p.preferences.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">No user preferences stored yet</div><div class="empty-sub">Use the form above to set base currency, locale, or onboarding state for any user.</div></div></td></tr>`
        : p.preferences
            .map(
              (pr) => `
            <tr>
              <td>
                <div style="font-weight: 700;">${escapeHtml(pr.email || pr.userId)}</div>
                <div class="mono muted">${escapeHtml(pr.userId)}</div>
              </td>
              <td colspan="4">
                <form method="POST" action="/admin/preferences/upsert" style="display: grid; grid-template-columns: 100px 100px 110px auto; gap: 8px; align-items: center;">
                  ${csrfInput}
                  <input type="hidden" name="userId" value="${escapeHtml(pr.userId)}">
                  <input type="text" name="baseCurrency" value="${escapeHtml(pr.baseCurrency)}" placeholder="USD" maxlength="6" style="padding: 6px 8px; font-size: 0.8rem;">
                  <input type="text" name="locale" value="${escapeHtml(pr.locale)}" placeholder="en" maxlength="12" style="padding: 6px 8px; font-size: 0.8rem;">
                  <select name="onboarded" style="padding: 6px 8px; font-size: 0.8rem;">
                    <option value="1" ${pr.onboarded ? 'selected' : ''}>Onboarded</option>
                    <option value="0" ${!pr.onboarded ? 'selected' : ''}>Pending</option>
                  </select>
                  <button type="submit" class="btn btn-outline btn-xs">Save</button>
                </form>
              </td>
            </tr>`
            )
            .join('');

    const userOptions = p.allUsersCompact
      .map(
        (u) =>
          `<option value="${escapeHtml(u.id)}">${escapeHtml(u.email)} (${escapeHtml(u.displayName)})</option>`
      )
      .join('');

    mainContent = `
      <div class="grid-3" style="margin-bottom: 18px;">${tableCards}</div>

      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Direct Server Override</div>
            <div class="card-title">Set or Update User Preferences</div>
          </div>
        </div>
        <form method="POST" action="/admin/preferences/upsert">
          ${csrfInput}
          <div class="form-grid">
            <div>
              <label for="p_uid">User Account *</label>
              ${
                p.allUsersCompact.length > 0
                  ? `<select id="p_uid" name="userId" required>${userOptions}</select>`
                  : `<input id="p_uid" name="userId" type="text" required placeholder="usr_g_...">`
              }
            </div>
            <div>
              <label for="p_cur">Base Currency</label>
              <input id="p_cur" name="baseCurrency" type="text" placeholder="USD / NPR / AUD / EUR" maxlength="6">
            </div>
            <div>
              <label for="p_loc">Locale</label>
              <input id="p_loc" name="locale" type="text" placeholder="en / ne" maxlength="12">
            </div>
            <div>
              <label for="p_onb">Onboarded</label>
              <select id="p_onb" name="onboarded">
                <option value="1">Yes (Completed)</option>
                <option value="0">No (Reset Onboarding)</option>
              </select>
            </div>
          </div>
          <button type="submit" class="btn btn-primary">Save Preferences</button>
        </form>
      </div>

      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Table · user_preferences</div>
            <div class="card-title">Stored Preferences (${p.preferences.length})</div>
          </div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Currency</th><th>Locale</th><th>Onboarded</th><th>Action</th></tr></thead>
            <tbody>${prefRows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================
  // TAB 5: APP MONITORING & TELEMETRY
  // ==========================================
  else if (p.tab === 'telemetry') {
    const etypeLink = (et: string, label: string) =>
      `<a href="/admin?tab=telemetry&etype=${et}${p.searchQuery ? `&q=${encodeURIComponent(p.searchQuery)}` : ''}" class="pill-tab ${p.eventTypeFilter === et ? 'active' : ''}">${label}</a>`;

    const eventRows =
      p.events.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">No telemetry events match</div><div class="empty-sub">Events and crash reports sent from the Hyprwise app stream here in real time.</div></div></td></tr>`
        : p.events
            .slice(0, 100)
            .map((e) => {
              const isErr = e.eventType === 'crash' || e.eventType === 'exception';
              return `
                <tr>
                  <td><span class="badge ${isErr ? 'badge-red' : e.eventType === 'screen_view' ? 'badge-brand' : 'badge-neutral'}">${escapeHtml(e.eventType)}</span></td>
                  <td>
                    <div style="font-weight: 700;">${escapeHtml(e.eventName)}</div>
                    <div class="mono muted">${escapeHtml(e.userId || 'anonymous')}</div>
                  </td>
                  <td class="mono muted">${escapeHtml(e.appVersion || '—')}<br>${escapeHtml(e.deviceInfo || '—')}</td>
                  <td class="mono muted" style="white-space: nowrap;">${formatDateTime(e.createdAt)}</td>
                  <td class="mono" style="max-width: 340px; word-break: break-word; font-size: 0.75rem;">${escapeHtml(e.details || '—')}</td>
                </tr>`;
            })
            .join('');

    mainContent = `
      ${p.analyticsHtml}

      <div class="card">
        <div class="card-head">
          <div class="pill-tabs">
            ${etypeLink('all', `All (${p.metrics.totalEvents})`)}
            ${etypeLink('crash', `Crashes & Errors (${p.metrics.totalExceptions})`)}
            ${etypeLink('action', 'Actions')}
            ${etypeLink('screen_view', 'Screens')}
          </div>
          <div class="inline-btns">
            <form method="GET" action="/admin" style="display: flex; gap: 6px;">
              <input type="hidden" name="tab" value="telemetry">
              <input type="hidden" name="etype" value="${escapeHtml(p.eventTypeFilter)}">
              <input type="text" name="q" value="${escapeHtml(p.searchQuery)}" placeholder="Search event, version, details..." style="width: 210px; padding: 6px 10px; font-size: 0.8rem;">
              <button type="submit" class="btn btn-outline btn-sm">Filter</button>
            </form>
          </div>
        </div>

        <div class="table-wrap">
          <table>
            <thead><tr><th>Type</th><th>Event / User</th><th>Version / Device</th><th>Timestamp</th><th>Details (Redacted)</th></tr></thead>
            <tbody>${eventRows}</tbody>
          </table>
        </div>

        <div style="display: flex; justify-content: flex-end; gap: 14px; flex-wrap: wrap; margin-top: 14px; padding-top: 14px; border-top: 1px solid var(--border);">
          <form method="POST" action="/admin/telemetry/clear" style="display: flex; align-items: center; gap: 8px;">
            ${csrfInput}<input type="hidden" name="scope" value="crashes">
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Confirm</span></label>
            <button type="submit" class="btn btn-danger-soft btn-xs">Clear Crashes</button>
          </form>
          <form method="POST" action="/admin/telemetry/clear" style="display: flex; align-items: center; gap: 8px;">
            ${csrfInput}<input type="hidden" name="scope" value="all">
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Confirm</span></label>
            <button type="submit" class="btn btn-outline btn-xs">Clear All Telemetry</button>
          </form>
        </div>
      </div>
    `;
  }

  // ==========================================
  // TAB 6: DELETIONS
  // ==========================================
  else if (p.tab === 'deletions') {
    const rows =
      p.deletions.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">Deletion queue is clear</div><div class="empty-sub">Requests submitted via the public /delete-account portal appear here.</div></div></td></tr>`
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
                              ${csrfInput}<input type="hidden" name="id" value="${escapeHtml(d.id)}">
                              <button type="submit" class="btn btn-outline btn-xs">Cancel</button>
                            </form>
                            <form method="POST" action="/admin/deletions/purge" style="display: inline-flex; align-items: center; gap: 6px;">
                              ${csrfInput}<input type="hidden" name="id" value="${escapeHtml(d.id)}">
                              <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Sure</span></label>
                              <button type="submit" class="btn btn-danger btn-xs">Purge Now</button>
                            </form>
                          </div>`
                        : `<span class="muted">Closed</span>`
                    }
                  </td>
                </tr>`;
            })
            .join('');

    mainContent = `
      <div class="card">
        <div class="card-head">
          <div>
            <div class="eyebrow">Store Compliance · 30-Day Grace Window</div>
            <div class="card-title">Account Deletion Requests (${p.deletions.length})</div>
          </div>
          <a href="/delete-account" target="_blank" class="btn btn-outline btn-sm">Open Public Portal ↗</a>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>Account</th><th>Status</th><th>Requested</th><th>Scheduled Purge</th><th>Actions</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ==========================================
  // TAB 7: AUDIT LOG
  // ==========================================
  else if (p.tab === 'audit') {
    const rows =
      p.auditLogs.length === 0
        ? `<tr><td colspan="5"><div class="empty-state"><div class="empty-title">No audit entries yet</div><div class="empty-sub">Every admin mutation and export is automatically recorded here.</div></div></td></tr>`
        : p.auditLogs
            .map((a) => {
              const cls = a.action.includes('wipe') || a.action.includes('delete') || a.action.includes('failed') || a.action.includes('purge')
                ? 'badge-red'
                : a.action.includes('pro') || a.action.includes('provisioned') || a.action.includes('login_success')
                ? 'badge-green'
                : 'badge-neutral';
              return `
                <tr>
                  <td class="mono muted" style="white-space: nowrap;">${formatDateTime(a.createdAt)}</td>
                  <td><span class="badge ${cls}">${escapeHtml(a.action)}</span></td>
                  <td class="mono">${escapeHtml(a.target || '—')}</td>
                  <td class="muted">${escapeHtml(a.details || '—')}</td>
                  <td class="mono muted">${escapeHtml(a.ipAddress || '—')}</td>
                </tr>`;
            })
            .join('');

    mainContent = `
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
  }

  // ==========================================
  // TAB 8: DANGER ZONE
  // ==========================================
  else if (p.tab === 'danger') {
    mainContent = `
      <div class="banner banner-warn">
        <span>Destructive operations execute immediately against live Cloudflare D1 and cannot be undone. Every wipe requires CSRF verification, checkbox consent, and an exact confirmation phrase.</span>
      </div>

      <div class="grid-3">
        <div class="danger-card">
          <div>
            <div class="eyebrow" style="color: var(--amber);">Scoped Cleanup</div>
            <div class="card-title">Clear Telemetry &amp; Crashes</div>
            <p class="muted" style="margin-top: 6px;">Deletes all rows in <code>telemetry_events</code> and resets edge memory logs. Users &amp; backups remain intact.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}<input type="hidden" name="scope" value="telemetry">
            <div>
              <label>Type <code>CLEAR TELEMETRY</code></label>
              <input type="text" name="phrase" required placeholder="CLEAR TELEMETRY" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Permanently clear all telemetry logs.</span></label>
            <button type="submit" class="btn btn-danger-soft">Clear All Telemetry</button>
          </form>
        </div>

        <div class="danger-card">
          <div>
            <div class="eyebrow" style="color: var(--amber);">Storage Reset</div>
            <div class="card-title">Delete All Cloud Vaults</div>
            <p class="muted" style="margin-top: 6px;">Deletes every backup in <code>sync_records</code> across all users. User accounts &amp; Pro subscriptions remain intact.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}<input type="hidden" name="scope" value="backups">
            <div>
              <label>Type <code>DELETE BACKUPS</code></label>
              <input type="text" name="phrase" required placeholder="DELETE BACKUPS" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>Permanently erase all cloud sync vaults.</span></label>
            <button type="submit" class="btn btn-danger-soft">Delete All Backups</button>
          </form>
        </div>

        <div class="danger-card" style="border-color: var(--red); background: #FFF8F7;">
          <div>
            <div class="eyebrow" style="color: var(--red);">Factory Server Wipe</div>
            <div class="card-title" style="color: var(--red);">Delete ALL Server Data</div>
            <p class="muted" style="margin-top: 6px;">Permanently wipes <strong>all users, Pro plans, cloud backups, user preferences, telemetry, and deletion requests</strong> in D1.</p>
          </div>
          <form method="POST" action="/admin/danger/wipe" style="display: flex; flex-direction: column; gap: 10px; margin-top: auto;">
            ${csrfInput}<input type="hidden" name="scope" value="all">
            <div>
              <label>Type <code>DELETE ALL DATA</code></label>
              <input type="text" name="phrase" required placeholder="DELETE ALL DATA" autocomplete="off">
            </div>
            <label class="check-label"><input type="checkbox" name="confirm" value="yes" required><span>I permanently confirm wiping every database table.</span></label>
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
  <title>Hyprwise Ops · ${escapeHtml(meta.title)}</title>
  <link rel="icon" type="image/svg+xml" href="/brand/favicon.svg">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=JetBrains+Mono:wght@500;600;700&display=swap" rel="stylesheet">
  <style>${ADMIN_CSS}</style>
</head>
<body>
  <!-- Mobile Navigation Drawer (Zero-JS CSS-only) -->
  <details class="mobile-bar">
    <summary>
      <span style="display: inline-flex; align-items: center; gap: 9px; font-weight: 800;">
        ${getHyprwiseIconSvg(24)}
        <span>hyprwise</span>
        <span class="sb-ops-pill">Ops</span>
      </span>
      <span style="display: inline-flex; align-items: center; gap: 6px; font-size: 0.8rem; color: #C7C9D3;">
        ${ICONS.menu} Menu
      </span>
    </summary>
    <div class="mobile-nav-panel">
      ${navGroupsHtml}
      <form method="POST" action="/admin/logout" style="margin-top: 10px;">
        ${csrfInput}
        <button type="submit" class="sb-signout">${ICONS.logout} Sign Out</button>
      </form>
    </div>
  </details>

  <div class="app-shell">
    <!-- Persistent Desktop Obsidian Sidebar -->
    <aside class="sidebar" aria-label="Operations Navigation">
      <div class="sb-brand">
        <a href="/admin" class="sb-brand-row">
          ${getHyprwiseIconSvg(26)}
          <span class="sb-brand-name">hyprwise</span>
          <span class="sb-ops-pill">Ops</span>
        </a>
        <div class="sb-status">
          <span class="status-dot ${p.dbConnected ? 'dot-green' : 'dot-red'}"></span>
          <span>${p.dbConnected ? 'Edge Online · D1 OK' : 'D1 Disconnected'}</span>
        </div>
      </div>

      <nav class="sb-nav">${navGroupsHtml}</nav>

      <div class="sb-footer">
        <div class="sb-meta">
          <span>HMAC-SHA256</span>
          <span>CSP Strict</span>
        </div>
        <form method="POST" action="/admin/logout" style="margin: 0;">
          ${csrfInput}
          <button type="submit" class="sb-signout">${ICONS.logout} Sign Out</button>
        </form>
      </div>
    </aside>

    <!-- Main Workspace -->
    <div class="workspace">
      <header class="topbar">
        <div class="topbar-title">
          <h1>${escapeHtml(meta.title)}</h1>
          <p>${escapeHtml(meta.subtitle)}</p>
        </div>
        <div class="topbar-actions">
          <form method="GET" action="/admin" class="quick-search">
            <input type="hidden" name="tab" value="users">
            ${ICONS.search}
            <input type="text" name="q" value="${p.tab === 'users' ? escapeHtml(p.searchQuery) : ''}" placeholder="Jump to user...">
          </form>
          <a href="/admin?tab=users&new=1" class="btn btn-brand btn-sm">${ICONS.plus} Add User</a>
          <a href="/admin?tab=${p.tab}" class="btn btn-outline btn-sm" title="Refresh">${ICONS.refresh}</a>
        </div>
      </header>

      <main class="content">
        ${
          p.usingDefaultPassword || p.usingDefaultSecret
            ? `<div class="banner banner-warn">
                <span>Security Notice: ${p.usingDefaultPassword ? 'Default ADMIN_PASSWORD is active. ' : ''}${p.usingDefaultSecret ? 'SESSION_SECRET is missing. ' : ''}Rotate via Cloudflare secrets before production traffic.</span>
              </div>`
            : ''
        }
        ${p.flashOk ? `<div class="banner banner-ok">✓ ${escapeHtml(p.flashOk)}</div>` : ''}
        ${p.flashErr ? `<div class="banner banner-err">⚠ ${escapeHtml(p.flashErr)}</div>` : ''}
        ${mainContent}
      </main>
    </div>
  </div>
</body>
</html>`;
}
