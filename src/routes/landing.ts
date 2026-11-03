// Root landing page for Hyprwise Compliance & Legal Portal
// Note: Admin portal link is intentionally hidden from this public page as requested.

import { getHyprwiseIconSvg } from '../brand_assets';

export function renderLandingPage(): string {
  return `
    <div style="max-width: 780px; margin: 0 auto; text-align: center; padding: 40px 16px 20px;">
      <div style="margin-bottom: 22px; display: inline-block;">
        ${getHyprwiseIconSvg(58)}
      </div>
      <h1 style="font-size: 2.2rem; margin-bottom: 8px; letter-spacing: -0.03em;">hyprwise</h1>
      <p class="subtitle" style="justify-content: center; font-size: 1.05rem; margin-bottom: 28px;">
        Local-first personal finance, shift wage tracker & dual-currency intelligence
      </p>

      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; text-align: left; margin-bottom: 32px;">
        <a href="/privacy" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;">
          <span class="section-eyebrow" style="color: var(--primary);">Data Safety</span>
          <h2 style="font-size: 1.15rem; margin: 0 0 6px; color: var(--text);">Privacy Policy &rarr;</h2>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0;">
            100% on-device SQLite database via Drift. Zero data sale, zero third-party monetization.
          </p>
        </a>

        <a href="/terms" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;">
          <span class="section-eyebrow" style="color: var(--primary);">Legal</span>
          <h2 style="font-size: 1.15rem; margin: 0 0 6px; color: var(--text);">Terms of Service &rarr;</h2>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0;">
            Acceptable use, subscription rules via RevenueCat, and shift rate slider agreement.
          </p>
        </a>

        <a href="/delete-account" class="content-card" style="text-decoration: none; display: block; transition: border-color 0.15s ease;">
          <span class="section-eyebrow" style="color: var(--accent-red);">User Rights</span>
          <h2 style="font-size: 1.15rem; margin: 0 0 6px; color: var(--text);">Delete Account &rarr;</h2>
          <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0;">
            Google Play Data Safety compliant account and cloud backup deletion portal.
          </p>
        </a>
      </div>

      <div class="content-card" style="text-align: left;">
        <h3 style="font-size: 1.05rem; margin-top: 0; margin-bottom: 12px;">Core Product Architecture</h3>
        <p style="font-size: 0.875rem; color: var(--text-muted); line-height: 1.6; margin: 0;">
          Hyprwise is engineered as an encrypted offline-first system. Financial accounts, hourly rates,
          shift schedules, goals, and transactions are stored locally on your device. Cloud sync is
          optional and end-to-end user authenticated.
        </p>
      </div>
    </div>
  `;
}
