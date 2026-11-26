# Hyprwise

**Local-first personal finance, shift wage tracking, dual-currency budgeting & AI financial assistant** (`com.hypr.hyprwise`).

## Key Capabilities
- **Local-First Encrypted SQLite Vault (Drift)**: 100% functional offline across accounts, transactions, transfers, shifts, breaks, overtime rules, goals, debts, exchange rates, and reminder rules.
- **Live Shift & Wage Engine**: Real-time shift tracking, break hydration across restarts, custom hourly overrides, overtime multipliers, and native **Android & iOS Home Screen Widgets**.
- **Dual-Currency & 9 Languages**: Adaptive native symbols (`$`, `A$`, `¥`, `€`, `रु`, `₹`, etc.) across `en`, `ne`, `hi`, `es`, `fr`, `de`, `ja`, `zh`, and `it`.
- **Hyprwise AI Assistant**: Private Gemini 2.5 Flash financial reasoning and receipt OCR scanning with strict anti-hallucination guardrails and confirmed local database actions.
- **Hyprwise Pro**: RevenueCat subscriptions (`pro_access` / `supporter` / `hyprwise_pro`) unlocking unlimited AI queries, executive PDF/summary reports, and automatic Cloudflare D1 cloud backup & sync.

## Architecture & Branching
- `lib/app/` — Dependency injection (`di/injection.dart`), GoRouter (`router/app_router.dart`), routes & app shell.
- `lib/core/` — WCAG AA theme tokens (`theme/`), Drift SQLite database (`database/`), localization (`l10n/`), notifications, exports, telemetry, and native home widget bridge (`widgets/`).
- `lib/features/` — Modular MVVM features (`home`, `analytics`, `money`, `work`, `calendar`, `goals`, `accounts`, `debts`, `transfers`, `alerts`, `assistant`, `auth`, `onboarding`, `categories`, `settings`, `subscription`).
- `server` branch — Standalone Hono + Cloudflare Workers + D1 backend.

## Documentation
- [AGENTS.md](AGENTS.md) — Architectural source of truth, design system rules, and AI guardrails.
- [docs/DEPLOYMENT_REQUIREMENTS.md](docs/DEPLOYMENT_REQUIREMENTS.md) — CI/CD, Codemagic, Cloudflare secrets, RevenueCat, and store release setup.
- [android/GOOGLE_PLAY_SETUP.md](android/GOOGLE_PLAY_SETUP.md) & [android/KEYSTORE_FINGERPRINTS.md](android/KEYSTORE_FINGERPRINTS.md) — Play Console signing and publishing guides.

## Local Verification
```bash
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release
flutter build appbundle --release
```
