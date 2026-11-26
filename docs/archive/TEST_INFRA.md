# E2E Test Infra: Hyprwise Hero Cards Visualization

## Test Philosophy
- Opaque-box, requirement-driven. No reliance on internal styling hacks.
- Methodology: Category-Partition + Boundary Value Analysis (BVA) + Pairwise Combinatorial + Real-World Workload Testing.

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Usable vs Non-Usable Balance Partition | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 2 | Flat Balance Proportion Bar | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 3 | Dual Spendable & Reserved Metric Pills | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 4 | Homepage Hero Overflow Safety & Design Tokens | ORIGINAL_REQUEST §R1, §R3 | 5 | 5 | ✓ |
| 5 | Three-State Velocity & Rate Metric | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 6 | Horizon Comparison Metric Bridge | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 7 | Zero-Baseline Trajectory Vector Curve | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 8 | Plan Hero Overflow Safety & Flat Styling | ORIGINAL_REQUEST §R2, §R3 | 5 | 5 | ✓ |

## Test Architecture
- Test runner: `flutter test test/features/home_hero_visualization_test.dart test/features/plan_hero_visualization_test.dart`
- Pass/fail semantics: Exit code 0, all tests pass, zero RenderFlex overflow exceptions.
- In-memory SQLite: `AppDatabase.forTesting(NativeDatabase.memory())`.

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Multi-currency everyday earner with savings & lent debt | F1, F2, F3, F4 | Medium |
| 2 | Heavy debt student / overdrawn balance with negative projection | F1, F2, F5, F7, F8 | High |
| 3 | Steady income earner with flat/zero monthly net change | F5, F6, F7, F8 | Medium |
| 4 | Rapid savings accumulator with high growth trajectory | F5, F6, F7 | Medium |
| 5 | Extreme scale values ($1,500,000+) on narrow 320px viewport | F2, F3, F4, F6, F8 | High |

## Coverage Thresholds
- Tier 1: ≥5 per feature
- Tier 2: ≥5 boundary/corner cases per feature
- Tier 3: pairwise coverage of feature interactions
- Tier 4: ≥5 realistic application scenarios
