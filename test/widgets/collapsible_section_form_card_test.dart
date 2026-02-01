import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
                    onExpandedChanged: (next) => setState(() => expanded = next),
                    trailing: IconButton(
                      tooltip: 'Action',
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                    ),
                    children: const [
                      Text('Child content'),
                    ],
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
}
