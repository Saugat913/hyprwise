// Public landing page for Hyprwise Legal & Compliance Portal.
// Strictly contains NO admin links, icons, or buttons (admin is path-only at /admin).

import { getHyprwiseIconSvg } from '../brand_assets';
import { wrapHtml } from '../compliance_and_admin';

export function renderLandingPage(): string {
  const bodyContent = `
    <div style="max-width: 820px; margin: 0 auto;">
      <!-- Obsidian Hero Banner matching Hyprwise Mobile App -->
      <div style="background: var(--hero); color: #FFFFFF; border-radius: var(--radius); padding: 36px 28px; text-align: center; margin-bottom: 24px; border: 1px solid #27272A;">
        <div style="display: inline-block; margin-bottom: 16px;">
          ${getHyprwiseIconSvg(56)}
        </div>
        <h1 style="color: #FFFFFF; font-size: 2.1rem; margin-bottom: 8px; letter-spacing: -0.03em;">hyprwise</h1>
        <p style="color: #9B9BA6; max-width: 560px; margin: 0 auto 18px; font-size: 0.975rem;">
          Local-first personal finance, shift wage management &amp; dual-currency budget intelligence.
        </p>
        <div style="display: inline-flex; align-items: center; gap: 8px; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); padding: 6px 14px; border-radius: 99px; font-size: 0.8rem; color: #E4E4E7;">
          <span class="status-dot" style="margin: 0;"></span>
          <span>Edge Services Operational</span>
          <span style="color: #71717A;">·</span>
          <span style="font-family: var(--font-mono); font-size: 0.78rem;">com.hypr.hyprwise</span>
        </div>
      </div>

      <!-- Compliance & User Rights Cards -->
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 14px; margin-bottom: 24px;">
        <a href="/privacy" class="nav-card">
          <span class="section-eyebrow" style="color: var(--green);">Data Safety</span>
          <h2 style="font-size: 1.1rem; margin: 0 0 6px; color: var(--ink);">Privacy Policy →</h2>
          <p style="font-size: 0.85rem; margin: 0;">
            On-device Drift SQLite vault. Zero data sale, zero ad tracking, and transparent cloud controls.
          </p>
        </a>

        <a href="/terms" class="nav-card">
          <span class="section-eyebrow">Legal</span>
          <h2 style="font-size: 1.1rem; margin: 0 0 6px; color: var(--ink);">Terms of Service →</h2>
          <p style="font-size: 0.85rem; margin: 0;">
            Software license, wage calculation disclaimers, and RevenueCat subscription terms.
          </p>
        </a>

        <a href="/delete-account" class="nav-card">
          <span class="section-eyebrow" style="color: var(--red);">User Rights</span>
          <h2 style="font-size: 1.1rem; margin: 0 0 6px; color: var(--ink);">Delete Account →</h2>
          <p style="font-size: 0.85rem; margin: 0;">
            Google Play &amp; Apple compliant account and cloud backup erasure portal.
          </p>
        </a>
      </div>

      <div class="content-card" style="padding: 24px;">
        <span class="section-eyebrow">Architecture</span>
        <h3 style="margin-top: 0; margin-bottom: 8px;">Local-First Financial Vault</h3>
        <p style="font-size: 0.875rem; margin: 0;">
          All accounts, shift logs, hourly rates, debts, and savings goals stay in your device's encrypted sandbox so Hyprwise works 100% offline. Optional Pro cloud sync uses verified Firebase authentication over TLS 1.3.
        </p>
      </div>
    </div>
  `;
  return wrapHtml({ title: 'Personal Finance & Shift Tracker', bodyContent, activeNav: '' });
}
