import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/horizontal_option_selector.dart';
import 'package:finance_tracker/features/shared/widgets/pro_badge.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  group('HorizontalOptionSelector Empirical Stress Tests', () {
    // ------------------------------------------------------------------------
    // Group 1: List Size Extremes & Boundaries
    // ------------------------------------------------------------------------
    testWidgets('G1.1: Empty items list with null selectedValue renders without crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [],
              selectedValue: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HorizontalOptionSelector<String>), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('G1.2: Empty items list with non-null selectedValue does not throw assertion error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [],
              selectedValue: 'non_existent',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HorizontalOptionSelector<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('G1.3: Single item list renders cleanly with selection and tap interactions', (tester) async {
      String? selected = 'only_one';
      int tapCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: HorizontalOptionSelector<String>(
                  items: const [
                    HorizontalOptionItem<String>(
                      value: 'only_one',
                      label: 'Sole Survivor',
                      iconData: Icons.star,
                    ),
                  ],
                  selectedValue: selected,
                  onChanged: (val) {
                    tapCount++;
                    setState(() => selected = val);
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sole Survivor'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('Sole Survivor'));
      await tester.pumpAndSettle();

      expect(tapCount, equals(1));
      expect(selected, equals('only_one'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('G1.4: Large item list (100 items) virtualizes and scrolls smoothly to tail', (tester) async {
      final items = List.generate(
        100,
        (i) => HorizontalOptionItem<int>(
          value: i,
          label: 'Option Item #$i',
          subtitle: 'Subtitle #$i',
        ),
      );

      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: HorizontalOptionSelector<int>(
                    height: 64,
                    items: items,
                    selectedValue: selected,
                    onChanged: (val) => setState(() => selected = val),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Item 0 is in viewport and selected
      expect(find.text('Option Item #0'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tail item 99 is not yet built (virtualization check)
      expect(find.text('Option Item #99'), findsNothing);

      // Scroll horizontally until item 99 is visible
      await tester.scrollUntilVisible(
        find.text('Option Item #99'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Option Item #99'), findsOneWidget);

      // Tap item 99
      await tester.tap(find.text('Option Item #99'));
      await tester.pumpAndSettle();

      expect(selected, equals(99));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ------------------------------------------------------------------------
    // Group 2: Null Value Support & Selection Semantics
    // ------------------------------------------------------------------------
    testWidgets('G2.1: Null value selection for "All Parties" filter semantics', (tester) async {
      String? selectedParty;
      int callbackCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: HorizontalOptionSelector<String?>(
                  items: const [
                    HorizontalOptionItem<String?>(
                      value: null,
                      label: 'All Parties',
                      iconData: Icons.people_alt_rounded,
                    ),
                    HorizontalOptionItem<String?>(
                      value: 'Alice',
                      label: 'Alice',
                      subtitle: 'Owes: +100',
                    ),
                    HorizontalOptionItem<String?>(
                      value: 'Bob',
                      label: 'Bob',
                      subtitle: 'Owe: -50',
                    ),
                  ],
                  selectedValue: selectedParty,
                  onChanged: (val) {
                    callbackCount++;
                    setState(() => selectedParty = val);
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // When selectedParty is null, 'All Parties' must be selected
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap on 'Alice'
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();

      expect(callbackCount, equals(1));
      expect(selectedParty, equals('Alice'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap back on 'All Parties'
      await tester.tap(find.text('All Parties'));
      await tester.pumpAndSettle();

      expect(callbackCount, equals(2));
      expect(selectedParty, isNull);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('G2.2: Completely unselected state when selectedValue is null and no item has null value', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [
                HorizontalOptionItem(value: 'usd', label: 'USD'),
                HorizontalOptionItem(value: 'npr', label: 'NPR'),
                HorizontalOptionItem(value: 'eur', label: 'EUR'),
              ],
              selectedValue: selected,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No item should have a checkmark
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('G2.3: Assert throws AssertionError when selectedValue is not in non-empty items', (tester) async {
      expect(
        () => HorizontalOptionSelector<String>(
          items: const [
            HorizontalOptionItem(value: 'usd', label: 'USD'),
            HorizontalOptionItem(value: 'npr', label: 'NPR'),
          ],
          selectedValue: 'invalid_currency',
          onChanged: (_) {},
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    // ------------------------------------------------------------------------
    // Group 3: Rapid State Transitions & Asynchronous Interactions
    // ------------------------------------------------------------------------
    testWidgets('G3.1: Rapid successive taps switch selection and execute callbacks sequentially', (tester) async {
      final history = <String>[];
      String current = 'A';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: HorizontalOptionSelector<String>(
                  items: const [
                    HorizontalOptionItem(value: 'A', label: 'Option A'),
                    HorizontalOptionItem(value: 'B', label: 'Option B'),
                    HorizontalOptionItem(value: 'C', label: 'Option C'),
                    HorizontalOptionItem(value: 'D', label: 'Option D'),
                  ],
                  selectedValue: current,
                  onChanged: (val) {
                    history.add(val);
                    setState(() => current = val);
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Rapidly tap B, C, D without waiting for animations to finish
      await tester.tap(find.text('Option B'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Option C'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Option D'));
      await tester.pumpAndSettle();

      expect(history, equals(['B', 'C', 'D']));
      expect(current, equals('D'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('G3.2: Re-tapping already selected item fires callback without visual jitter', (tester) async {
      int count = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [
                HorizontalOptionItem(value: 'fixed', label: 'Fixed Option'),
              ],
              selectedValue: 'fixed',
              onChanged: (_) => count++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fixed Option'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fixed Option'));
      await tester.pumpAndSettle();

      expect(count, equals(2));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('G3.3: Disabled selector (onChanged == null) does not invoke callbacks on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [
                HorizontalOptionItem(value: 'read_only', label: 'Read Only Option'),
              ],
              selectedValue: 'read_only',
              onChanged: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Read Only Option'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ------------------------------------------------------------------------
    // Group 4: Layout Constraints, Text Sizing, and Overflow Boundaries
    // ------------------------------------------------------------------------
    testWidgets('G4.1: Extreme text lengths in label and subtitle truncate without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              height: 64,
              items: const [
                HorizontalOptionItem(
                  value: 'long',
                  label: 'Extremely Long Account Name That Exceeds Normal Viewport Length For Testing Purposes',
                  subtitle: 'Very Extensive Description Detailing The Financial Rules Associated With This Account',
                  icon: HugeIcons.strokeRoundedBank,
                ),
              ],
              selectedValue: 'long',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Extremely Long Account'), findsOneWidget);
    });

    testWidgets('G4.2: Tight height constraint (height: 48) with subtitle does not throw RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              height: 48,
              items: const [
                HorizontalOptionItem(
                  value: 'NPR',
                  label: 'NPR',
                  subtitle: 'Nepalese rupee',
                ),
                HorizontalOptionItem(
                  value: 'USD',
                  label: 'USD',
                  subtitle: 'US dollar',
                ),
              ],
              selectedValue: 'NPR',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Nepalese rupee'), findsOneWidget);
    });

    testWidgets('G4.3: Accessibility large font scale (textScaleFactor: 1.5) renders cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: HorizontalOptionSelector<String>(
                height: 64,
                items: const [
                  HorizontalOptionItem(
                    value: 'scaled',
                    label: 'Scaled Font Label',
                    subtitle: 'Scaled Subtitle',
                    icon: HugeIcons.strokeRoundedCoins01,
                  ),
                ],
                selectedValue: 'scaled',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Scaled Font Label'), findsOneWidget);
    });

    testWidgets('G4.4: Bounded narrow container (width: 150) scrolls without clipping crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: HorizontalOptionSelector<String>(
                items: const [
                  HorizontalOptionItem(value: 'c1', label: 'Card 1 Wide'),
                  HorizontalOptionItem(value: 'c2', label: 'Card 2 Wide'),
                  HorizontalOptionItem(value: 'c3', label: 'Card 3 Wide'),
                ],
                selectedValue: 'c1',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card 1 Wide'), findsOneWidget);
      // Drag left in narrow box
      await tester.drag(find.text('Card 1 Wide'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // ------------------------------------------------------------------------
    // Group 5: Polymorphic Item Contents (Avatars, Icons, Trailing, Badges)
    // ------------------------------------------------------------------------
    testWidgets('G5.1: Mixed visual components (IconGlyph, IconData, Avatar, Trailing Pro Badge)', (tester) async {
      String selected = 'avatar_item';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: HorizontalOptionSelector<String>(
                  height: 64,
                  selectedValue: selected,
                  onChanged: (val) => setState(() => selected = val),
                  items: const [
                    HorizontalOptionItem(
                      value: 'glyph_item',
                      label: 'Glyph Item',
                      icon: HugeIcons.strokeRoundedBriefcase01,
                    ),
                    HorizontalOptionItem(
                      value: 'data_item',
                      label: 'Data Item',
                      iconData: Icons.security,
                    ),
                    HorizontalOptionItem(
                      value: 'avatar_item',
                      label: 'Avatar Item',
                      avatar: CircleAvatar(radius: 12, child: Text('A')),
                    ),
                    HorizontalOptionItem(
                      value: 'pro_item',
                      label: 'Pro Report',
                      trailing: ProCrownBadge(isCompact: true),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Glyph Item'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(ProCrownBadge), findsOneWidget);

      // Avatar item is currently selected
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Switch to Pro Report
      await tester.tap(find.text('Pro Report'));
      await tester.pumpAndSettle();

      expect(selected, equals('pro_item'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('G5.2: Dynamic item list mutation (rebuilding with modified item sets)', (tester) async {
      var currentItems = <HorizontalOptionItem<String>>[
        const HorizontalOptionItem(value: 'a', label: 'Item A'),
        const HorizontalOptionItem(value: 'b', label: 'Item B'),
      ];
      String currentSelected = 'a';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    HorizontalOptionSelector<String>(
                      items: currentItems,
                      selectedValue: currentSelected,
                      onChanged: (val) => setState(() => currentSelected = val),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentItems = [
                            const HorizontalOptionItem(value: 'c', label: 'Item C'),
                            const HorizontalOptionItem(value: 'd', label: 'Item D'),
                            const HorizontalOptionItem(value: 'e', label: 'Item E'),
                          ];
                          currentSelected = 'd';
                        });
                      },
                      child: const Text('Update Items'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);

      // Mutate list
      await tester.tap(find.text('Update Items'));
      await tester.pumpAndSettle();

      expect(find.text('Item A'), findsNothing);
      expect(find.text('Item C'), findsOneWidget);
      expect(find.text('Item D'), findsOneWidget);
      expect(find.text('Item E'), findsOneWidget);
      expect(currentSelected, equals('d'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Group 6: Design System Conformance (Expense Suggester Style)
    // ------------------------------------------------------------------------
    testWidgets('G6.1: Conforms to 12px border radius, 1.5px brand outline and tint when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
          ),
          home: Scaffold(
            body: HorizontalOptionSelector<String>(
              items: const [
                HorizontalOptionItem(value: 'selected', label: 'Selected Card'),
                HorizontalOptionItem(value: 'unselected', label: 'Unselected Card'),
              ],
              selectedValue: 'selected',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the AnimatedContainers
      final animatedContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();
      expect(animatedContainers.length, equals(2));

      final selectedBox = animatedContainers[0].decoration as BoxDecoration;
      final unselectedBox = animatedContainers[1].decoration as BoxDecoration;

      // 12px border radius (AppRadius.md)
      expect(selectedBox.borderRadius, equals(BorderRadius.circular(AppRadius.md)));
      expect(unselectedBox.borderRadius, equals(BorderRadius.circular(AppRadius.md)));

      // Selected has 1.5px border, unselected has 1.0px border
      final selectedBorder = selectedBox.border as Border;
      final unselectedBorder = unselectedBox.border as Border;
      expect(selectedBorder.top.width, equals(1.5));
      expect(unselectedBorder.top.width, equals(1.0));

      // Selected has primary tint background
      expect(selectedBox.color, isNotNull);
    });
  });
}
