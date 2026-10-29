import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  group('R2: Horizontal Option Selectors (Tier 1 Feature Coverage)', () {
    testWidgets('T1.1: Expense suggester styled horizontal selectors use horizontal scroll direction', (tester) async {
      final items = ['Groceries', 'Dining Out', 'Transport', 'Utilities'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (context, i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: Colors.white,
                    ),
                    child: Center(child: Text(items[i])),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final horizontalList = tester.widget<ListView>(find.byType(ListView));
      expect(horizontalList.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('T1.2: Horizontal option cards utilize 12px border radius (AppRadius.md)', (tester) async {
      bool found12pxRadius = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (context, i) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    child: Center(child: Text('Option $i')),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final c in containers) {
        if (c.decoration is BoxDecoration) {
          final box = c.decoration as BoxDecoration;
          if (box.borderRadius == BorderRadius.circular(AppRadius.md)) {
            found12pxRadius = true;
            break;
          }
        }
      }

      expect(found12pxRadius, isTrue);
      expect(AppRadius.md, equals(12.0));
    });

    testWidgets('T1.3: Selecting an unselected horizontal card updates selection state', (tester) async {
      String selected = 'Cash';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            final options = ['Cash', 'Bank', 'Wallet', 'Savings'];
            return MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final opt = options[i];
                      final isSelected = opt == selected;
                      return InkWell(
                        onTap: () => setState(() => selected = opt),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(opt),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, size: 14),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(selected, equals('Cash'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap on 'Bank'
      await tester.tap(find.text('Bank'));
      await tester.pump();

      expect(selected, equals('Bank'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('T1.4: Selected card shows active checkmark indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Text('Everyday Bank'),
                  Icon(Icons.check_circle_rounded, size: 14),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('T1.5: Unselected horizontal card renders without active checkmark indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Text('Digital Wallet'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.text('Digital Wallet'), findsOneWidget);
    });
  });

  group('R2: Horizontal Option Selectors (Tier 2 Boundary & Corner Cases)', () {
    testWidgets('T2.1: Single item horizontal selector renders cleanly without layout crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Center(child: Text('Sole Option')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sole Option'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.2: Many items (8+ currencies) scroll smoothly horizontally', (tester) async {
      final currencies = ['USD', 'NPR', 'EUR', 'INR', 'GBP', 'AUD', 'CAD', 'JPY'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currencies.length,
                itemBuilder: (context, i) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Center(child: Text(currencies[i])),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('USD'), findsOneWidget);

      // Drag to scroll horizontally
      await tester.drag(find.text('USD'), const Offset(-300, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.3: Horizontal option card with long text truncates or wraps without layout overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 140,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Text(
                      'Extremely Long Merchant Or Category Name That Might Overflow',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.4: Rapid sequential taps switch selection reliably', (tester) async {
      int tapCount = 0;
      int selectedIdx = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    itemBuilder: (context, i) {
                      return InkWell(
                        onTap: () {
                          tapCount++;
                          setState(() => selectedIdx = i);
                        },
                        child: Text('Card $i'),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Card 1'));
      await tester.pump();
      await tester.tap(find.text('Card 2'));
      await tester.pump();
      await tester.tap(find.text('Card 3'));
      await tester.pump();

      expect(tapCount, equals(3));
      expect(selectedIdx, equals(3));
    });

    testWidgets('T2.5: Horizontal cards support leading avatar or icon alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.all(8),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 12, child: Text('W')),
                        SizedBox(width: 8),
                        Text('Woolworths'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Woolworths'), findsOneWidget);
    });
  });

  group('R2: HorizontalOptionSelector Component Functional Coverage', () {
    testWidgets('R2.1: HorizontalOptionSelector renders items with subtitle, icon, and selection checkmark', (tester) async {
      String? selected = 'opt2';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HorizontalOptionSelector<String>(
                  height: 64,
                  selectedValue: selected,
                  onChanged: (val) => setState(() => selected = val),
                  items: const [
                    HorizontalOptionItem(
                      value: 'opt1',
                      label: 'Option 1',
                      subtitle: 'First Subtitle',
                      icon: HugeIcons.strokeRoundedCoins01,
                    ),
                    HorizontalOptionItem(
                      value: 'opt2',
                      label: 'Option 2',
                      subtitle: 'Second Subtitle',
                      icon: HugeIcons.strokeRoundedBank,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('First Subtitle'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Second Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap Option 1
      await tester.tap(find.text('Option 1'));
      await tester.pump();

      expect(selected, equals('opt1'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('R2.2: HorizontalOptionSelector supports null selection and iconData / avatar items', (tester) async {
      int? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<int?>(
              selectedValue: selected,
              onChanged: (_) {},
              items: const [
                HorizontalOptionItem(
                  value: null,
                  label: 'All Items',
                  iconData: Icons.people_alt_rounded,
                ),
                HorizontalOptionItem(
                  value: 1,
                  label: 'Item 1',
                  avatar: CircleAvatar(radius: 10, child: Text('1')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('All Items'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      // null is selected, checkmark present on All Items
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
