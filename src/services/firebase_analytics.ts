// Real Edge Telemetry & Activity Analytics Service for Hyprwise Admin Console
// Computes genuine 7-day metrics directly from stored events — zero fabricated numbers.

import { escapeHtml } from '../compliance_and_admin';

export interface AnalyticsSummary {
  totalEvents7d: number;
  uniqueActiveUsers7d: number;
  crashes7d: number;
  topEvents: { name: string; count: number; percentage: number }[];
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
    }

    const sortedEvents = Object.entries(eventCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6);

    const totalRecent = recentEvents.length || 1;
    const topEvents = sortedEvents.map(([name, count]) => ({
      name,
      count,
      percentage: Math.round((count / totalRecent) * 100),
    }));

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
      topEvents,
      dailyTrend,
      isConfigured: Boolean(propertyId),
    };
  }

  static renderAnalyticsChartsHtml(summary: AnalyticsSummary): string {
    const trend = summary.dailyTrend;
    const maxVal = Math.max(...trend.map((t) => t.events), 4);
    const chartHeight = 132;
    const chartWidth = 460;
    const colWidth = chartWidth / trend.length;

    const barsSvg = trend
      .map((t, idx) => {
        const h = t.events === 0 ? 3 : Math.max(8, Math.round((t.events / maxVal) * (chartHeight - 36)));
        const x = idx * colWidth + 14;
        const barW = colWidth - 28;
        const y = chartHeight - h - 20;
        const fill =
          t.crashes > 0 ? 'var(--red)' : t.events > 0 ? 'var(--brand)' : 'var(--border)';
        return `
          <g>
            <rect x="${x}" y="${y}" width="${barW}" height="${h}" rx="4" fill="${fill}" />
            <text x="${x + barW / 2}" y="${y - 5}" text-anchor="middle" font-size="10" font-family="var(--font-mono)" fill="var(--muted)" font-weight="600">${t.events}</text>
            <text x="${x + barW / 2}" y="${chartHeight - 4}" text-anchor="middle" font-size="9.5" font-family="var(--font-mono)" fill="var(--muted)">${escapeHtml(t.date)}</text>
          </g>
        `;
      })
      .join('');

    const eventBarsHtml =
      summary.topEvents.length === 0
        ? `<div class="empty-inline">No telemetry events recorded in the past 7 days.</div>`
        : summary.topEvents
            .map(
              (e) => `
          <div style="margin-bottom: 10px;">
            <div style="display: flex; justify-content: space-between; font-size: 0.8rem; margin-bottom: 4px; gap: 8px;">
              <span style="font-weight: 600; color: var(--ink); font-family: var(--font-mono); overflow: hidden; text-overflow: ellipsis;">${escapeHtml(e.name)}</span>
              <span style="color: var(--muted); font-family: var(--font-mono); white-space: nowrap;">${e.count} (${e.percentage}%)</span>
            </div>
            <div style="background: var(--fill); height: 6px; border-radius: 99px; overflow: hidden;">
              <div style="background: var(--ink); width: ${e.percentage}%; height: 100%; border-radius: 99px;"></div>
            </div>
          </div>
        `
            )
            .join('');

    return `
      <div class="grid-2" style="margin-bottom: 20px;">
        <div class="card">
          <div class="card-head">
            <div>
              <div class="eyebrow">7-Day Edge Telemetry Volume</div>
              <div class="card-title">${summary.totalEvents7d} events · ${summary.uniqueActiveUsers7d} active users</div>
            </div>
            <span class="badge ${summary.isConfigured ? 'badge-green' : 'badge-neutral'}">
              ${summary.isConfigured ? 'GA4 + D1' : 'Live D1 Stream'}
            </span>
          </div>
          <svg viewBox="0 0 ${chartWidth} ${chartHeight}" style="width: 100%; height: auto; display: block; overflow: visible;">
            ${barsSvg}
          </svg>
        </div>

        <div class="card">
          <div class="card-head">
            <div>
              <div class="eyebrow">Top App Events (7d)</div>
              <div class="card-title">Action Distribution</div>
            </div>
            <span class="badge ${summary.crashes7d > 0 ? 'badge-red' : 'badge-green'}">
              ${summary.crashes7d} crashes
            </span>
          </div>
          <div>${eventBarsHtml}</div>
        </div>
      </div>
    `;
  }
}
