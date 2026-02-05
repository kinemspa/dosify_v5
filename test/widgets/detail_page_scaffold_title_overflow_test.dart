import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/detail_page_scaffold.dart';

ThemeData _testTheme() {
  const primarySeed = kDetailHeaderGradientStart;
  final scheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
  ).copyWith(primary: primarySeed);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

Future<List<FlutterErrorDetails>> _captureFlutterErrors(
  Future<void> Function() action,
) async {
  final errors = <FlutterErrorDetails>[];
  final oldHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };

  try {
    await action();
  } finally {
    FlutterError.onError = oldHandler;
  }
  return errors;
}

bool _isOverflowError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  return message.contains('A RenderFlex overflowed') ||
      message.contains('overflowed by');
}

void main() {
  testWidgets('DetailPageScaffold title does not overflow with long text', (
    WidgetTester tester,
  ) async {
    final longTitle =
        'Extremely Long Schedule Title That Should Never Overflow The App Header Even On Narrow Screens';

    final errors = await _captureFlutterErrors(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _testTheme(),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(width: 320),
                child: DetailPageScaffold(
                  title: longTitle,
                  expandedTitle: longTitle,
                  statsBannerContent: const SizedBox.shrink(),
                  sections: const [SizedBox(height: 600)],
                  onEdit: () {},
                  onDelete: () async {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    final overflowErrors = errors.where(_isOverflowError);
    expect(overflowErrors, isEmpty);
  });
}
