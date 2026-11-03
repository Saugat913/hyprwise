# AGENTS.md — Hyprwise Architectural Context & Decision Matrix

This document is the **single source of truth** for all autonomous agents, human engineers, and subagents working on **Hyprwise**. Any modification to the codebase must adhere to the decisions, guidelines, and constraints defined below.

---

## 1. Product Identity & Philosophy

- **Product Name**: **Hyprwise** (formerly Tilvane).
- **Application ID / Package**: `com.hypr.hyprwise` (Android & iOS).
- **Domain**: Personal Finance, Shift Wage Management, Dual-Currency Tracking & AI Budget Intelligence.
- **Philosophy**:
  1. **Local-First**: All accounts, shifts, debts, goals, and transactions live in an encrypted on-device SQLite database via Drift. The app is 100% functional offline.
  2. **Zero Data Monetization**: We never sell or lease user transactions, hourly earnings, or logs to advertisers.
  3. **Multi-Currency & Multilingual**: Built for dual-currency earners and migrant workers. Currencies adaptively format with native symbols (e.g. `$`, `A$`, `¥`, `€`, Nepali `रु`, Hindi `₹`).
  4. **Dynamic Shift Rate Slider Protocol**: Supports base hourly rates, custom hourly pricing overrides, overtime multipliers, and overtime fixed rates.

---

## 2. System Architecture

```
                  ┌──────────────────────────────────────────┐
                  │          Hyprwise Flutter App            │
                  │        (com.hypr.hyprwise)               │
                  └─────────────┬───────────────────┬────────┘
                                │                   │
       ┌────────────────────────▼────────┐   ┌──────▼─────────────────────┐
       │     Local Drift / SQLite DB     │   │      Telemetry Service     │
       │   (Accounts, Shifts, Tx, Goals) │   │  (Firebase & Crash Center) │
       └─────────────────────────────────┘   └─────────────┬──────────────┘
                                                           │
                                             ┌─────────────▼──────────────┐
                                             │  Hono Server (Cloudflare)  │
                                             │  - Admin Dashboard (/admin)│
                                             │  - Legal (/privacy, /terms)│
                                             │  - Delete Account Portal   │
                                             │  - Gemini 2.5 Flash Proxy  │
                                             └────────────────────────────┘
```

### Key Technologies
- **Client**: Flutter (Dart 3.7+), Drift ORM, GetIt, GoRouter, HugeIcons, Purchases Flutter (RevenueCat).
- **Backend**: Hono TypeScript running on Cloudflare Workers with D1 Database.
- **AI Gateway**: Google Gemini 2.5 Flash for chat reasoning and OCR receipt scanning.
- **Subscriptions**: RevenueCat SDK (`hyprwise_pro` entitlement).

---

## 3. Git Branching Strategy & CI/CD

### Branch Topology
- **`main`**: Production-ready code. Every commit on `main` is production quality.
  - Triggers: **Codemagic Production Workflow** & Google Play Production deployment.
- **`dev`**: Active integration branch. All features merge here first.
  - Triggers: **Codemagic Internal Testing Workflow** & Google Play Internal Testing track.
- **`patch`**: Single dedicated standing branch for emergency production hotfixes/patches.
  - Always kept in sync with `main`.
  - Triggers: **Codemagic Production Workflow** (Play Store patch release).
  - After a patch release, changes merge into `main` and propagate to `dev` on the next release cycle.
- **`feature/<name>`**: Feature development branched off `dev`.
  - Merged into `dev` via Pull Request after passing `flutter analyze` and `flutter test`.

### Versioning Rules (SemVer + Monotonic Build Codes)
- **Internal Testing Baseline**: `0.1.0+X` (Git tag `v0.1.0`).
- **Production Baseline**: `1.0.0+100` (Git tag `v1.0.0`).
- **Production Hotfixes**: `1.0.1+101` (Git tag `v1.0.1`).
- **Monotonicity**: Production build codes reserve `100+`, ensuring they are strictly greater than internal testing build codes.

### Release Automation
Run the automated release script:
```bash
# Interactive mode
./scripts/release.sh

# Non-interactive CLI
./scripts/release.sh --type=internal --push
./scripts/release.sh --type=production --push
./scripts/release.sh --type=patch --push
```

---

## 4. Server Compliance & Admin Credentials

- **Admin Dashboard**: `https://<backend-domain>/admin`
  - **Password**: `P@ssword123`
  - Monitors: Real-time exceptions, crash reports, customer interaction patterns, active cloud backups, registered users.
- **Compliance URLs (Google Play Mandate)**:
  - Privacy Policy: `/privacy` (alias `/privacy-policy`)
  - Terms of Service: `/terms` (alias `/terms-of-service`)
  - Account Deletion Portal: `/delete-account` (alias `/account-deletion`)
  - Account Deletion API: `POST /api/account/delete`
- **Telemetry Ingestion**: `POST /api/telemetry/event`

---

## 5. Architectural DO's and DONT's

### UI & Design System
- **DO** use consistent `12px` border radius (`AppRadius.md` / `12.0`) across cards, sheets, and dialogs.
- **DO** ensure all modal bottom sheets set `isScrollControlled: true` and wrap their content in a `SingleChildScrollView` with keyboard-aware padding (`MediaQuery.of(context).viewInsets.bottom`) to prevent pixel buffer overflows.
- **DO** place all section headers (`SectionHeader`) outside white container cards (`AppCard`), keeping section titles clean and free of logos or icon prefixes.
- **DO** stack modal bottom sheet action buttons (e.g. Edit, View, Close) vertically in a full-width `Column` (`minimumSize: Size(double.infinity, ...)`) rather than cramming them into a horizontal `Row` with `Expanded`, preventing localized string clipping and multiline overflows on compact viewports.
- **DO** present bottom sheet choice selectors (e.g. photo source, filter options) as vertical `OptionTile` lists or responsive 3-column `GridView`s rather than horizontal strips.
- **DO** wrap `ListTile` or `InkWell` in its own `Material` widget (`Material(shape: ..., color: ...)`) instead of an intermediate colored `Container(decoration: BoxDecoration(...))` to ensure ink splashes and touch feedback remain visible and avoid Flutter framework runtime warnings.
- **DO** keep Hero cards (`HomeHeroCard`, `GoalScreen` outlook hero) spacious, calm, and visually unified with ambient brand geometry, rather than congested with heavy nested double borders.
- **DO** display receipt image thumbnails inside the chat bubble when the user uploads or snaps a bill photo.
- **DO** show actionable pills and confirmation dialogues when the AI assistant executes database actions.
- **DONT** hardcode currency symbols or currency codes (`AUD`, `USD`). Always query the active user's base currency via `context.strings` / `CurrencyService`.
- **DONT** allow text truncation or awkward overflows in currency selectors or language pickers.

### Architecture & Data Layer
- **DO** keep the Drift SQLite database as the single source of truth for all business operations.
- **DO** execute actual database insertions (e.g. adding 1,500 to Groceries) when the AI assistant confirms an expense command, rather than merely replying with simulated text.
- **DO** mark `completeOnboarding()` immediately upon successful Google or Apple sign-in so returning users and cross-device sign-ins are never forced through first-run currency and language selection.
- **DO** automatically pull the latest cloud backup (`pullCloudDataToLocal()`) on user sign-in and trigger background auto-sync (`triggerProAutoSync()`) whenever Pro users modify settings or financial data.
- **DO** provide a master ON/OFF switch in Settings (`setAllAlerts`) to toggle all reminders and notifications globally.
- **DO** wrap Android exact alarm scheduling with runtime permission checks (`canScheduleExactAlarms`) and fall back to `AndroidScheduleMode.inexactAllowWhileIdle` when exact alarm scheduling is disallowed by the operating system.
- **DO** wrap background telemetry logging in `unawaited(...)` so network lag never stalls the UI thread.
- **DONT** call asynchronous database or network operations inside Flutter `build()` methods.
- **DONT** maintain two separate paywall implementations. RevenueCat SDK (`PurchasesUI.presentPaywall()`) is the exclusive upgrade paywall.

### AI Assistant & MCP Protocol Guardrails
- **DO** enforce strict anti-hallucination boundaries. The AI assistant is exclusively **Hyprwise**, a personal finance, wage tracking, and shift management assistant.
- **DO** answer with honest ignorance when asked about unknown facts, non-financial trivia, or unrecorded expenses: *"I don't know that. I am Hyprwise, your personal finance and shift management assistant. I only have access to your personal financial records, accounts, and shift planner."*
- **DO** inject live on-device financial snapshots (balances, shifts, transactions, debts, goals) into context, but **only reveal specific numbers when directly asked** by the user. Do NOT dump entire financial overviews unprompted.
- **DO** clearly differentiate schedule queries (e.g., *"when is my next shift"*) from creation actions (e.g., *"schedule a shift tomorrow 9am"*).
- **DO** execute real Drift DB transactions immediately for parsed financial commands and display actionable confirmation cards (`AssistantActionConfirmation`).
- **DONT** hallucinate or invent receipt OCR values when scanning bills. If the amount cannot be read with confidence (amount $\le 0$ or merchant empty), return an honest *"Could Not Read Bill"* prompt rather than fake default transactions.
- **DONT** allow the AI to answer general world knowledge (e.g., geography, sports, celebrity trivia, coding advice) that falls outside personal finance and shift scheduling.

### Security & Compliance
- **DO** provide both in-app account deletion (*Settings $\rightarrow$ Danger Zone $\rightarrow$ Delete Account*) and web-based account deletion (`/delete-account`) as required by Google Play Data Safety policies.
- **DO** handle unhandled errors globally in `main.dart` through `FlutterError.onError` and `PlatformDispatcher.instance.onError` to route crash reports to the admin console.
- **DONT** log plaintext credentials, tokens, or unredacted personal account numbers into telemetry.

---

## 6. Key Project Map

| Directory / File | Description |
|---|---|
| `lib/app/` | Dependency injection (`injection.dart`), routing (`routes.dart`), app configuration (`app.dart`). |
| `lib/core/telemetry/` | Crash capture, Firebase Analytics & backend telemetry forwarding (`telemetry_service.dart`). |
| `lib/core/network/` | Hono backend client (`api_client.dart`). |
| `lib/features/assistant/` | Gemini AI chat, OCR receipt scanner, and automated action execution. |
| `lib/features/goals/` | Goal tracking, 3-month balance forecast engine, savings progress. |
| `lib/features/work/` | Shift tracking, rate slider protocol, overtime calculation. |
| `lib/features/subscription/`| RevenueCat paywall integration (`subscription_service.dart`). |
| `server/` (branch `server`) | Dedicated standalone Cloudflare Workers backend (`src/index.ts`, `src/routes/`, `src/middleware/`, `src/services/`). |
| `codemagic.yaml` | Codemagic CI/CD pipeline for Play Store release. |
| `scripts/release.sh` | Interactive version bump, test runner, git tagger, and push automation. |
