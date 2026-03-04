import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skedux/src/core/design_system.dart';
import 'package:skedux/src/features/schedules/domain/entry_log.dart';
import 'package:skedux/src/widgets/entry_action_legend_row.dart';
import 'package:skedux/src/widgets/unified_status_badge.dart';

void main() {
  testWidgets('EntryActionLegendRow renders Taken/Skipped/Snoozed with DS colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        ),
        home: const Scaffold(body: EntryActionLegendRow()),
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
    final expected = entryActionVisualSpec(context, EntryAction.skipped);

    expect(skippedBadge.color, expected.color);
    expect(skippedBadge.icon, expected.icon);
  });

  testWidgets('EntryActionLegendRow can include Inventory badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        ),
        home: const Scaffold(
          body: EntryActionLegendRow(includeInventory: true),
        ),
      ),
    );

    expect(find.widgetWithText(UnifiedStatusBadge, 'Inventory'), findsOneWidget);
  });
}
