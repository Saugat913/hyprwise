# Project: Hyprwise Hero Cards Data Visualization Refinements

## Architecture
- **Home Balance Architecture (`lib/features/home/`)**:
  - `HomeViewModel`: Extends `FinanceSnapshot` calculations with deterministic partition:
    $$\text{usableBalanceMinor} + \text{nonUsableBalanceMinor} = \text{netPositionMinor}$$
    - `usableBalanceMinor`: Sum of liquid accounts (`type == 'bank'`, `'cash'`, `'wallet'`, or `name.toLowerCase() == 'everyday'`) converted to base currency.
    - `nonUsableBalanceMinor`: Exact difference `netPositionMinor - usableBalanceMinor` (representing savings, locked funds, goal allocations, and net debts).
    - `usableRatio` & `nonUsableRatio`: Normalized clamped ratios for proportion rendering.
  - `HomeScreen` (`HeroCard`): Two-tier data visualization:
    - Tier A: Flat 6px dual-segment proportion bar (`AppRadius.pill`, track `colors.onHero.withValues(alpha: 0.12)`, spendable vibrant accent, reserved muted tone, zero/negative safe fallback).
    - Tier B: Sleek metric breakdown pills (`Spendable Cash` vs `Reserved & Savings`) displaying formatted amounts (`MoneyFormatter`), percentage shares, dot indicators, and tap routes.
- **Plan Forecast Architecture (`lib/features/plan/`)**:
  - `PlanViewModel`: Drives 3-month forecast from `ForecastEngine` and `FinanceStore`:
    - Three polarity states: Positive (Growth), Negative (Decline), Neutral (Steady zero-delta).
    - Relative growth rate percentage: `growthRatePercent`.
  - `PlanScreen` (`HeroCard`): Flat three-tier outlook visualizer:
    - Tier 1: Outlook Headline & Dynamic Velocity Badge (`+`, `−`, `flat` with monthly net pace and relative growth rate, fixing zero-delta false positive).
    - Tier 2: Horizon Comparison Metric Bridge (`Current Balance` -> `90-Day Net Delta Capsule` -> `Projected Balance`).
    - Tier 3: Zero-baseline aware flat trajectory vector curve (`_PlanTrajectoryVector`), handling positive and negative projections with zero bar clipping.
- **Shared Design Tokens & Responsiveness (`lib/core/theme/`, `lib/core/utils/`)**:
  - `AppRadius.md` (12px), `elevation: 0`, hairline borders, `colors.hero` deep slate container.
  - Responsive overflow resistance via `FittedBox(fit: BoxFit.scaleDown)` and `MoneyFormatter`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Usable vs Non-Usable Balance Partition | Add computed getters `usableBalanceMinor`, `nonUsableBalanceMinor`, and ratios in `HomeViewModel` | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Flat Balance Proportion Bar | Render 6px dual-segment proportion bar inside Homepage HeroCard with zero/negative protection | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Dual Spendable & Reserved Metric Pills | Render side-by-side metric breakdown pills with amounts, percentages, and tap actions | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Homepage Hero Overflow Safety & Design Tokens | Ensure `FittedBox` scaling, 12px radii, and flat styling without layout regressions | M1 | ORIGINAL_REQUEST §R1, §R3 |
| 5 | Three-State Velocity & Rate Metric | Add growth/decline rate percentage and fix zero-delta false positive in `PlanViewModel` & HeroCard | M2 | ORIGINAL_REQUEST §R2 |
| 6 | Horizon Comparison Metric Bridge | Render Current Balance -> 90-Day Net Delta -> Projected Balance row inside Plan HeroCard | M2 | ORIGINAL_REQUEST §R2 |
| 7 | Zero-Baseline Trajectory Vector Curve | Replace 6-bar clamped histogram with continuous zero-baseline aware trajectory vector | M2 | ORIGINAL_REQUEST §R2 |
| 8 | Plan Hero Overflow Safety & Flat Styling | Ensure responsive scaling, negative value support, and strict design token preservation | M2 | ORIGINAL_REQUEST §R2, §R3 |
| 9 | Opaque-Box E2E & Hero Card Test Suite | Comprehensive tests covering homepage & plan hero cards, edge cases, and all 4 test tiers | M3 | ORIGINAL_REQUEST Acceptance Criteria |
| 10 | Final Verification & Hardening | 100% pass on test suite, flutter analyze with 0 errors, and forensic audit clean verdict | M3 | ORIGINAL_REQUEST Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Homepage Hero Card Data Visualization | Usable vs non-usable balance partition, 6px proportion bar, dual metric pills, overflow safety | None | DONE |
| 2 | Plan Page Hero Card Data Visualization | 3-state velocity badge, metric comparison bridge, zero-baseline trajectory curve, negative value support | None | DONE |
| 3 | Final Milestone: Test Suite & Hardening | Opaque-box E2E & hero widget tests (Tiers 1-4), adversarial hardening, full verification | M1, M2 | DONE |

## Interface Contracts
### `HomeViewModel` ↔ `HomeScreen`
```dart
int get usableBalanceMinor;
int get nonUsableBalanceMinor;
double get usableRatio; // 0.0 .. 1.0
double get nonUsableRatio; // 0.0 .. 1.0
```

### `PlanViewModel` ↔ `PlanScreen`
```dart
int get currentTotalBalanceMinor;
int get projectedBalanceIn3Months;
int get monthlyNetDeltaMinor;
int get threeMonthNetChangeMinor;
double? get threeMonthGrowthRatePercent;
List<PlanForecastPoint> get trajectoryPoints;
```

## Code Layout
- `lib/features/home/viewmodels/home_view_model.dart`: Usable and non-usable balance partition calculations.
- `lib/features/home/view/home_screen.dart`: Homepage HeroCard visualization (proportion bar, metric breakdown pills).
- `lib/features/plan/viewmodels/plan_view_model.dart`: Trajectory points, growth rate percentage, net delta calculations.
- `lib/features/plan/view/plan_screen.dart`: Plan HeroCard visualization (velocity badge, metric bridge, trajectory vector curve).
- `test/features/home_hero_visualization_test.dart`: Unit and widget tests for Homepage hero card.
- `test/features/plan_hero_visualization_test.dart`: Unit and widget tests for Plan hero card.
