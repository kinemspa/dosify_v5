import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_log.dart';
import 'package:dosifi_v5/src/widgets/dose_action_legend_row.dart';
import 'package:dosifi_v5/src/widgets/unified_status_badge.dart';

void main() {
  testWidgets('DoseActionLegendRow renders Taken/Skipped/Snoozed with DS colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        ),
        home: const Scaffold(body: DoseActionLegendRow()),
      ),
    );

    expect(find.widgetWithText(UnifiedStatusBadge, 'Taken'), findsOneWidget);
    expect(find.widgetWithText(UnifiedStatusBadge, 'Skipped'), findsOneWidget);
    expect(find.widgetWithText(UnifiedStatusBadge, 'Snoozed'), findsOneWidget);

    final skippedBadge = tester.widget<UnifiedStatusBadge>(
      find.widgetWithText(UnifiedStatusBadge, 'Skipped'),
    );

    final context = tester.element(
      find.widgetWithText(UnifiedStatusBadge, 'Skipped'),
    );
    final expected = doseActionVisualSpec(context, DoseAction.skipped);

    expect(skippedBadge.color, expected.color);
    expect(skippedBadge.icon, expected.icon);
  });

  testWidgets('DoseActionLegendRow can include Inventory badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        ),
        home: const Scaffold(
          body: DoseActionLegendRow(includeInventory: true),
        ),
      ),
    );

    expect(find.widgetWithText(UnifiedStatusBadge, 'Inventory'), findsOneWidget);
  });
}
