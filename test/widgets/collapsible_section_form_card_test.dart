import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

void main() {
  testWidgets('CollapsibleSectionFormCard expands and collapses', (
    WidgetTester tester,
  ) async {
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: CollapsibleSectionFormCard(
                    title: 'Section',
                    isExpanded: expanded,
                    onExpandedChanged: (next) =>
                        setState(() => expanded = next),
                    trailing: IconButton(
                      tooltip: 'Action',
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                    ),
                    children: const [Text('Child content')],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    final crossFade0 = tester.widget<AnimatedCrossFade>(
      find.byType(AnimatedCrossFade),
    );
    expect(crossFade0.crossFadeState, CrossFadeState.showFirst);

    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(48),
    );

    final constrainedBoxFinder = find.ancestor(
      of: find.byTooltip('Action'),
      matching: find.byType(ConstrainedBox),
    );

    final constrainedBoxes = tester
        .widgetList<ConstrainedBox>(constrainedBoxFinder)
        .toList();
    expect(
      constrainedBoxes.any((b) => b.constraints == kTightIconButtonConstraints),
      isTrue,
    );

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();
    final crossFade1 = tester.widget<AnimatedCrossFade>(
      find.byType(AnimatedCrossFade),
    );
    expect(crossFade1.crossFadeState, CrossFadeState.showSecond);

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();
    final crossFade2 = tester.widget<AnimatedCrossFade>(
      find.byType(AnimatedCrossFade),
    );
    expect(crossFade2.crossFadeState, CrossFadeState.showFirst);

    expect(find.byTooltip('Action'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leadingCollapsedOnly hides leading when expanded', (
    WidgetTester tester,
  ) async {
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: CollapsibleSectionFormCard(
                    title: 'Section',
                    isExpanded: expanded,
                    onExpandedChanged: (next) =>
                        setState(() => expanded = next),
                    leading: const Icon(Icons.drag_indicator, key: Key('lead')),
                    leadingCollapsedOnly: true,
                    children: const [Text('Child content')],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('lead')), findsOneWidget);

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lead')), findsNothing);
  });
}
