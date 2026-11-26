// Real Edge Telemetry & Activity Analytics Service for Hyprwise Admin Console
// Computes genuine 7-day metrics directly from stored events — zero fabricated numbers.

import { escapeHtml } from '../compliance_and_admin';

export interface AnalyticsSummary {
  totalEvents7d: number;
  uniqueActiveUsers7d: number;
  crashes7d: number;
  crashFreeRate: string;
  topEvents: { name: string; count: number; percentage: number }[];
  appVersions: { version: string; count: number; percentage: number }[];
  dailyTrend: { date: string; events: number; crashes: number }[];
  isConfigured: boolean;
}

export class FirebaseAnalyticsService {
  static async getAnalyticsSummary(opts: {
    propertyId?: string;
    events: Array<{
      eventName?: string;
      eventType?: string;
      userId?: string | null;
      appVersion?: string | null;
      createdAt?: number;
    }>;
    totalUsers: number;
  }): Promise<AnalyticsSummary> {
    const { propertyId, events } = opts;

    const now = new Date();
    const sevenDaysAgoMs = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const recentEvents = events.filter((e) => Number(e.createdAt || 0) >= sevenDaysAgoMs);

    const uniqueUsers = new Set<string>();
    const eventCounts: Record<string, number> = {};
    const versionCounts: Record<string, number> = {};
    let crashes7d = 0;

    for (const e of recentEvents) {
      if (e.userId && e.userId !== 'system' && e.userId !== 'anonymous') {
        uniqueUsers.add(e.userId);
      }
      if (e.eventType === 'crash' || e.eventType === 'exception') {
        crashes7d++;
      }
      const name = String(e.eventName || 'unknown').slice(0, 64);
      eventCounts[name] = (eventCounts[name] || 0) + 1;

      const ver = String(e.appVersion || 'unknown').trim() || 'unknown';
      versionCounts[ver] = (versionCounts[ver] || 0) + 1;
    }

    const totalRecent = recentEvents.length || 1;
    const topEvents = Object.entries(eventCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6)
      .map(([name, count]) => ({
        name,
        count,
        percentage: Math.round((count / totalRecent) * 100),
      }));

    const appVersions = Object.entries(versionCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([version, count]) => ({
        version,
        count,
        percentage: Math.round((count / totalRecent) * 100),
      }));

    const crashFreeRate =
      recentEvents.length === 0
        ? '100%'
        : `${Math.max(0, ((recentEvents.length - crashes7d) / recentEvents.length) * 100).toFixed(1)}%`;

    // Build genuine 7-day daily buckets from event.createdAt
    const dayBucketEvents = new Map<string, number>();
    const dayBucketCrashes = new Map<string, number>();
    for (const e of recentEvents) {
      const ts = Number(e.createdAt || 0);
      if (!ts) continue;
      const dayKey = new Date(ts).toISOString().slice(0, 10);
      dayBucketEvents.set(dayKey, (dayBucketEvents.get(dayKey) || 0) + 1);
      if (e.eventType === 'crash' || e.eventType === 'exception') {
        dayBucketCrashes.set(dayKey, (dayBucketCrashes.get(dayKey) || 0) + 1);
      }
    }

    const dailyTrend: { date: string; events: number; crashes: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setUTCDate(d.getUTCDate() - i);
      const dayFull = d.toISOString().slice(0, 10);
      dailyTrend.push({
        date: dayFull.slice(5), // MM-DD
        events: dayBucketEvents.get(dayFull) || 0,
        crashes: dayBucketCrashes.get(dayFull) || 0,
      });
    }

    return {
      totalEvents7d: recentEvents.length,
      uniqueActiveUsers7d: uniqueUsers.size,
      crashes7d,
      crashFreeRate,
      topEvents,
      appVersions,
      dailyTrend,
      isConfigured: Boolean(propertyId),
    };
  }

  static renderAnalyticsChartsHtml(summary: AnalyticsSummary): string {
    const trend = summary.dailyTrend;
    const maxVal = Math.max(...trend.map((t) => t.events), 4);
    const chartHeight = 160;
    const chartWidth = 480;
    const padBottom = 26;
    const padTop = 20;
    const plotH = chartHeight - padBottom - padTop;
    const colWidth = chartWidth / trend.length;

    const gridLines = [0, 0.5, 1]
      .map((ratio) => {
        const y = Math.round(padTop + plotH * (1 - ratio));
        return `<line x1="8" y1="${y}" x2="${chartWidth - 8}" y2="${y}" stroke="#E5E7EB" stroke-dasharray="3 3" stroke-width="1" />`;
      })
      .join('');

    const barsSvg = trend
      .map((t, idx) => {
        const h = t.events === 0 ? 4 : Math.max(8, Math.round((t.events / maxVal) * plotH));
        const crashH =
          t.crashes > 0 ? Math.max(4, Math.round((t.crashes / maxVal) * plotH)) : 0;
        const x = Math.round(idx * colWidth + 16);
        const barW = Math.round(colWidth - 32);
        const y = padTop + plotH - h;
        const crashY = padTop + plotH - crashH;
        const fill = t.events > 0 ? '#141417' : '#E5E7EB';

        return `
          <g>
            <rect x="${x}" y="${y}" width="${barW}" height="${h}" rx="5" fill="${fill}" />
            ${
              crashH > 0
                ? `<rect x="${x}" y="${crashY}" width="${barW}" height="${crashH}" rx="4" fill="#B42318" />`
                : ''
            }
            <text x="${x + barW / 2}" y="${y - 6}" text-anchor="middle" font-size="10" font-family="var(--font-mono)" fill="${t.events > 0 ? '#141417' : '#8A8F8C'}" font-weight="700">${t.events}</text>
            <text x="${x + barW / 2}" y="${chartHeight - 6}" text-anchor="middle" font-size="10" font-family="var(--font-mono)" fill="#59615D">${escapeHtml(t.date)}</text>
          </g>
        `;
      })
      .join('');

    const eventBarsHtml =
      summary.topEvents.length === 0
        ? `<div class="empty-state">
            <div class="empty-title">No events in the last 7 days</div>
            <div class="empty-sub">Telemetry will appear here as users interact with Hyprwise.</div>
          </div>`
        : summary.topEvents
            .map(
              (e) => `
          <div class="metric-bar-row">
            <div class="metric-bar-meta">
              <span class="mono" style="font-weight: 600; color: var(--ink); overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${escapeHtml(e.name)}</span>
              <span class="mono muted">${e.count} · ${e.percentage}%</span>
            </div>
            <div class="progress-track">
              <div class="progress-fill" style="width: ${Math.max(4, e.percentage)}%; background: var(--brand);"></div>
            </div>
          </div>
        `
            )
            .join('');

    const versionSummary =
      summary.appVersions.length === 0
        ? ''
        : `<div style="margin-top: 14px; padding-top: 12px; border-top: 1px solid var(--border); font-size: 0.76rem; color: var(--muted); display: flex; flex-wrap: wrap; gap: 12px;">
            <span style="font-weight: 700; color: var(--ink);">App Versions:</span>
            ${summary.appVersions
              .map(
                (v) =>
                  `<span class="mono">${escapeHtml(v.version)} (${v.percentage}%)</span>`
              )
              .join('')}
          </div>`;

    return `
      <div class="grid-2" style="margin-bottom: 18px;">
        <div class="card" style="margin-bottom: 0;">
          <div class="card-head">
            <div>
              <div class="eyebrow">7-Day Edge Telemetry</div>
              <div class="card-title">${summary.totalEvents7d} events · ${summary.uniqueActiveUsers7d} active users</div>
            </div>
            <div style="display: flex; align-items: center; gap: 10px;">
              <span class="legend-dot"><i style="background:#141417;"></i>Events</span>
              <span class="legend-dot"><i style="background:#B42318;"></i>Crashes</span>
            </div>
          </div>
          <svg viewBox="0 0 ${chartWidth} ${chartHeight}" style="width: 100%; height: auto; display: block; overflow: visible;">
            ${gridLines}
            ${barsSvg}
          </svg>
        </div>

        <div class="card" style="margin-bottom: 0; display: flex; flex-direction: column;">
          <div class="card-head">
            <div>
              <div class="eyebrow">App Telemetry Breakdown</div>
              <div class="card-title">Top Events &amp; Stability</div>
            </div>
            <span class="mono" style="font-size: 0.78rem; font-weight: 700; color: ${summary.crashes7d > 0 ? 'var(--red)' : 'var(--green)'};">
              ${escapeHtml(summary.crashFreeRate)} crash-free
            </span>
          </div>
          <div style="flex: 1;">${eventBarsHtml}</div>
          ${versionSummary}
        </div>
      </div>
    `;
  }
}
