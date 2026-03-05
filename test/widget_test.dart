// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:skedux/src/app/app.dart';

void main() {
  testWidgets('App builds without throwing and renders MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SkeduxApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
