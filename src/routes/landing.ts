// Public landing page for Hyprwise.
// Clean editorial product & trust portal — zero decorative pills, strictly NO /admin links.

import { getHyprwiseIconSvg } from '../brand_assets';
import { wrapHtml } from '../compliance_and_admin';

export function renderLandingPage(): string {
  const bodyContent = `
    <!-- Editorial Hero -->
    <section class="hero-block">
      <div class="hero-inner">
        <div class="hero-copy">
          <div class="hero-brand-mark">${getHyprwiseIconSvg(40)}</div>
          <h1 class="hero-title">Personal finance and shift tracking, built local-first.</h1>
          <p class="hero-lead">
            Track accounts, dual-currency expenses, work shifts, hourly wages, and savings goals in one calm workspace. Your data stays on your device by default — with optional encrypted cloud backup when you want it.
          </p>
          <div class="hero-actions">
            <a href="/privacy" class="btn btn-light">Privacy &amp; Data Safety</a>
            <a href="/terms" class="btn btn-ghost-dark">Terms of Service</a>
          </div>
        </div>
      </div>
    </section>

    <!-- Core Pillars -->
    <section class="section-block">
      <div class="section-header">
        <h2>Built for everyday clarity</h2>
        <p>Focused financial and work tracking without clutter, ads, or third-party data brokering.</p>
      </div>
      <div class="feature-grid">
        <div class="feature-card">
          <h3>Multi-Account Ledger</h3>
          <p>
            Manage bank accounts, wallets, budgets, debts, and recurring transactions with multi-currency conversion and instant balance totals.
          </p>
        </div>
        <div class="feature-card">
          <h3>Shift &amp; Wage Intelligence</h3>
          <p>
            Schedule shifts across multiple jobs, calculate regular and overtime pay automatically, and forecast upcoming paychecks directly alongside your cash flow.
          </p>
        </div>
        <div class="feature-card">
          <h3>On-Device SQLite Vault</h3>
          <p>
            Every record is stored locally in your device's encrypted sandbox for 100% offline speed. Optional Hyprwise Pro sync uses verified Firebase authentication over TLS 1.3.
          </p>
        </div>
      </div>
    </section>

    <!-- Trust, Compliance & User Rights -->
    <section class="section-block">
      <div class="section-header">
        <h2>Trust &amp; Legal Center</h2>
        <p>Transparent policies and self-service data controls for Android and iOS users.</p>
      </div>
      <div class="trust-list">
        <a href="/privacy" class="trust-row">
          <div>
            <h3>Privacy Policy</h3>
            <p>How local storage, optional Pro cloud sync, receipt OCR, and crash diagnostics are handled.</p>
          </div>
          <span class="trust-arrow">Read policy →</span>
        </a>
        <a href="/terms" class="trust-row">
          <div>
            <h3>Terms of Service</h3>
            <p>Software license, informational disclaimers, and Google Play / Apple subscription terms.</p>
          </div>
          <span class="trust-arrow">Read terms →</span>
        </a>
        <a href="/delete-account" class="trust-row">
          <div>
            <h3>Account &amp; Data Deletion</h3>
            <p>Request permanent erasure of your Hyprwise server account and cloud backups with a 30-day grace period.</p>
          </div>
          <span class="trust-arrow trust-arrow-danger">Manage deletion →</span>
        </a>
      </div>
    </section>
  `;

  return wrapHtml({
    title: 'Personal Finance & Shift Tracker',
    bodyContent,
    activeNav: '',
    wide: true,
  });
}
