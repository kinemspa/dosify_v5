import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dosifi_v5/src/app/app.dart';

void main() {
  testWidgets('App builds without throwing and renders MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DosifiApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
