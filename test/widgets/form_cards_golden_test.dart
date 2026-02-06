@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

ThemeData _goldenTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  const secondarySeed = kDoseStatusSnoozedOrange;

  final scheme = ColorScheme.fromSeed(seedColor: primarySeed).copyWith(
    primary: primarySeed,
    secondary: secondarySeed,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Widget _wrapForGolden(
  Widget child, {
  double width = 380,
  double? textScaleFactor,
}) {
  return MaterialApp(
    theme: _goldenTheme(),
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
      ),
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('golden'),
            child: ConstrainedBox(
              constraints: BoxConstraints.tightFor(width: width),
              child: Padding(
                padding: const EdgeInsets.all(kSpacingM),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionFormCard goldens', () {
    testWidgets('standard width with normal text scale', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          SectionFormCard(
            title: 'Test Section',
            children: [
              const Text('Field 1: Value'),
              const SizedBox(height: kSpacingS),
              const Text('Field 2: Another Value'),
              const SizedBox(height: kSpacingS),
              const Text('Field 3: Yet Another Value'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/section_form_card_standard.png'),
      );
    });

    testWidgets('compact width with large text scale', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          SectionFormCard(
            title: 'Test Section',
            children: [
              const Text('Field 1: Value'),
              const SizedBox(height: kSpacingS),
              const Text('Field 2: Another Value'),
            ],
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/section_form_card_compact_large_text.png'),
      );
    });

    testWidgets('neutral variant', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          SectionFormCard(
            title: 'Neutral Section',
            neutral: true,
            children: [
              const Text('Content in neutral card'),
              const SizedBox(height: kSpacingS),
              const Text('More content'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/section_form_card_neutral.png'),
      );
    });
  });

  group('CollapsibleSectionFormCard goldens', () {
    testWidgets('expanded state - standard width', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          CollapsibleSectionFormCard(
            title: 'Collapsible Section',
            isExpanded: true,
            onExpandedChanged: (_) {},
            children: const [
              Text('Field 1: Value'),
              SizedBox(height: kSpacingS),
              Text('Field 2: Another Value'),
              SizedBox(height: kSpacingS),
              Text('Field 3: Yet Another Value'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile('goldens/collapsible_section_form_card_expanded.png'),
      );
    });

    testWidgets('collapsed state - compact width with large text',
        (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          CollapsibleSectionFormCard(
            title: 'Collapsible Section',
            isExpanded: false,
            onExpandedChanged: (_) {},
            children: const [
              Text('This content should be hidden'),
            ],
          ),
          width: 320,
          textScaleFactor: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/collapsible_section_form_card_collapsed_compact_large_text.png',
        ),
      );
    });

    testWidgets('expanded neutral variant with long title', (tester) async {
      await tester.pumpWidget(
        _wrapForGolden(
          CollapsibleSectionFormCard(
            title: 'Very Long Section Title That Might Wrap or Ellipsize',
            isExpanded: true,
            neutral: true,
            onExpandedChanged: (_) {},
            children: const [
              Text('Content 1'),
              SizedBox(height: kSpacingS),
              Text('Content 2'),
            ],
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey<String>('golden')),
        matchesGoldenFile(
          'goldens/collapsible_section_form_card_long_title.png',
        ),
      );
    });
  });
}
