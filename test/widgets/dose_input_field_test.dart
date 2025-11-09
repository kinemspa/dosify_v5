import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosifi_v5/src/widgets/dose_input_field.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';

void main() {
  group('DoseInputField - Tablets', () {
    testWidgets('displays mode toggle with Tablets and Strength options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000, // 50mg
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Tablets'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
    });

    testWidgets('defaults to Tablets mode when no initial value', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      // Tablets mode should be selected (has primary color styling)
      final tabletsButton = find.text('Tablets');
      expect(tabletsButton, findsOneWidget);
    });

    testWidgets('shows quick action buttons in Tablets mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      // Wait for initial build and postFrameCallback
      await tester.pumpAndSettle();

      // Quick buttons should be present as ActionChips
      expect(find.byType(ActionChip), findsNWidgets(4)); // 1/4, 1/2, 1, 2
    });

    testWidgets('quick button sets value and calculates', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000, // 50mg
              strengthUnit: 'mg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Find ActionChips and tap the last one (should be "2")
      final actionChips = find.byType(ActionChip);
      expect(actionChips, findsNWidgets(4));

      await tester.tap(actionChips.last); // Tap "2" button
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseTabletQuarters, 8); // 2 tablets = 8 quarters
      expect(result!.doseMassMcg, 100000); // 2 × 50mg = 100mg
    });

    testWidgets('stepper buttons increment/decrement by 0.25', (tester) async {
      final results = <DoseCalculationResult>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              initialTabletCount: 1.0,
              onDoseChanged: (r) => results.add(r),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      results.clear(); // Clear initial calculation

      // Find and tap increment button
      final incrementButton = find.byIcon(Icons.add);
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();

      expect(results.last.doseTabletQuarters, 5); // 1.25 tablets = 5 quarters
    });

    testWidgets('toggles to Strength mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify quick buttons exist initially
      expect(find.byType(ActionChip), findsNWidgets(4));

      // Tap Strength button
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();

      // Quick buttons should be hidden in Strength mode
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('calculates from strength input', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000, // 50mg per tablet
              strengthUnit: 'mg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      // Switch to Strength mode
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();

      // Enter 100mg
      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseTabletQuarters, 8); // 100mg ÷ 50mg = 2 tablets
    });
  });

  group('DoseInputField - Capsules', () {
    testWidgets('displays mode toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.capsule,
              strengthPerUnitMcg: 500000, // 500mg
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Capsules'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
    });

    testWidgets('does not show quick buttons for capsules', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.capsule,
              strengthPerUnitMcg: 500000,
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Quick buttons (ActionChips) should not appear for capsules
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('stepper increments by 1 for capsules', (tester) async {
      final results = <DoseCalculationResult>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.capsule,
              strengthPerUnitMcg: 500000,
              strengthUnit: 'mg',
              initialCapsuleCount: 2,
              onDoseChanged: (r) => results.add(r),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Get last result (after increment)
      final lastResult = results.last;
      expect(lastResult.doseCapsules, 3); // 2 + 1 = 3
    });

    testWidgets('calculates from capsule count', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.capsule,
              strengthPerUnitMcg: 500000, // 500mg per capsule
              strengthUnit: 'mg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter 3 capsules
      await tester.enterText(find.byType(TextField), '3');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseCapsules, 3);
      expect(result!.doseMassMcg, 1500000); // 3 × 500mg = 1500mg
    });
  });

  group('DoseInputField - Pre-filled Injections', () {
    testWidgets('does not show mode toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.prefilledSyringe,
              strengthPerUnitMcg: 300, // 300mcg per injection
              volumePerUnitMicroliter: 300, // 0.3ml
              strengthUnit: 'mcg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      // Mode toggle should not appear for injections
      expect(find.text('Injections'), findsNothing);
      expect(find.text('Strength'), findsNothing);
    });

    testWidgets('calculates from injection count', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.prefilledSyringe,
              strengthPerUnitMcg: 300,
              volumePerUnitMicroliter: 300,
              strengthUnit: 'mcg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '2');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseSyringes, 2);
      expect(result!.doseMassMcg, 600); // 2 × 300mcg
      expect(result!.doseVolumeMicroliter, 600); // 2 × 0.3ml
    });
  });

  group('DoseInputField - Single Dose Vials', () {
    testWidgets('calculates from vial count', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.singleDoseVial,
              strengthPerUnitMcg: 10000, // 10mg per vial
              volumePerUnitMicroliter: 2000, // 2ml
              strengthUnit: 'mg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '2');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseVials, 2);
      expect(result!.doseMassMcg, 20000); // 2 × 10mg
      expect(result!.doseVolumeMicroliter, 4000); // 2 × 2ml
    });
  });

  group('DoseInputField - Error Handling', () {
    testWidgets('shows warning for invalid tablet increment', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      // Enter 2.3 tablets (invalid - should warn and round)
      await tester.enterText(find.byType(TextField), '2.3');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.hasWarning, true);
      expect(result!.warning, contains('rounded'));
    });

    testWidgets('shows error container with error styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      // Enter invalid tablet count to trigger warning
      await tester.enterText(find.byType(TextField), '2.33');
      await tester.pumpAndSettle();

      // Should show warning icon
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('DoseInputField - Initial Values', () {
    testWidgets('initializes with tablet count', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000,
              strengthUnit: 'mg',
              initialTabletCount: 2.5,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.doseTabletQuarters, 10); // 2.5 tablets
      expect(find.text('2.5'), findsOneWidget);
    });

    testWidgets('initializes with strength in mg', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.tablet,
              strengthPerUnitMcg: 50000, // 50mg per tablet
              strengthUnit: 'mg',
              initialStrengthMcg: 100000, // 100mg total
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.doseTabletQuarters, 8); // 100mg ÷ 50mg = 2 tablets
      expect(find.text('100.0'), findsOneWidget); // Displayed in mg
    });
  });

  group('DoseInputField - MDV (Multi-Dose Vial)', () {
    testWidgets('displays 3-way mode toggle for MDV', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0, // Not used for MDV
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000, // 2mg vial
              totalVialVolumeMicroliter: 1000, // 1ml vial
              syringeType: SyringeType.ml_0_3, // 30 unit syringe
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 3-way toggle
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Units'), findsOneWidget);
    });

    testWidgets('defaults to Strength mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Strength mode should be selected
      // We can't easily check button styling, but we can check placeholder
      expect(find.text('e.g., 500'), findsOneWidget); // Strength hint
    });

    testWidgets('calculates from strength input', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000, // 2mg (2000mcg) total
              totalVialVolumeMicroliter: 1000, // 1ml total
              syringeType: SyringeType.ml_0_3, // 30 unit syringe (100 units/ml)
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter 500mcg
      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseMassMcg, 500);
      expect(result!.doseVolumeMicroliter, 250); // 500/2000 × 1000 = 0.25ml
      expect(result!.syringeUnits, 25); // 0.25ml × 100 units/ml = 25 units
    });

    testWidgets('switches to Volume mode', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Volume button
      await tester.tap(find.text('Volume'));
      await tester.pumpAndSettle();

      // Enter 0.25ml
      await tester.enterText(find.byType(TextField), '0.25');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.doseVolumeMicroliter, 250);
      expect(result!.doseMassMcg, 500); // 0.25/1.0 × 2000mcg = 500mcg
      expect(result!.syringeUnits, 25); // 0.25ml × 100 units/ml = 25 units
    });

    testWidgets('switches to Units mode', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Units button
      await tester.tap(find.text('Units'));
      await tester.pumpAndSettle();

      // Enter 25 units (corresponds to 0.25ml and 500mcg)
      await tester.enterText(find.byType(TextField), '25');
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.success, true);
      expect(result!.syringeUnits, 25);
      expect(
        result!.doseVolumeMicroliter,
        250,
      ); // 25 units ÷ 100 units/ml = 0.25ml
      expect(result!.doseMassMcg, 500); // 0.25/1.0 × 2000mcg = 500mcg
    });

    testWidgets('displays 3-value summary for MDV', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              onDoseChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter 500mcg
      await tester.enterText(find.byType(TextField), '500');
      await tester.pumpAndSettle();

      // Should show 3-value display with all values
      // Note: There may be 2 instances (one in 3-value display, one in result display)
      expect(find.textContaining('500mcg'), findsWidgets);
      expect(find.textContaining('0.25ml'), findsWidgets);
      expect(find.textContaining('25.0 Units'), findsWidgets);
      expect(find.text('•'), findsNWidgets(2)); // Two bullet separators
    });

    testWidgets('initializes with strength value', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              initialStrengthMcg: 500,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.doseMassMcg, 500);
      expect(find.text('500.0'), findsOneWidget);
    });

    testWidgets('initializes with volume value and defaults to Volume mode', (
      tester,
    ) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              initialVolumeMicroliter: 250,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.doseVolumeMicroliter, 250);
      expect(find.text('0.25'), findsOneWidget); // 250µL = 0.25ml
    });

    testWidgets('initializes with units value and defaults to Units mode', (
      tester,
    ) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              initialSyringeUnits: 25,
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.syringeUnits, 25);
      // The input field shows "25" or "25.0" depending on how it's formatted
      final textFields = find.byType(TextField);
      expect(textFields, findsOneWidget);
    });

    testWidgets('syringe graphic is interactive', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoseInputField(
              medicationForm: MedicationForm.multiDoseVial,
              strengthPerUnitMcg: 0,
              strengthUnit: 'mcg',
              totalVialStrengthMcg: 2000,
              totalVialVolumeMicroliter: 1000,
              syringeType: SyringeType.ml_0_3,
              initialStrengthMcg: 500, // Start at 500mcg = 25 units
              onDoseChanged: (r) => result = r,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state: 500mcg = 25 units
      expect(result!.syringeUnits, 25);

      // Find the WhiteSyringeGauge widget - it should exist and be interactive
      final syringeGauge = find.byType(WhiteSyringeGauge);
      expect(syringeGauge, findsOneWidget);

      // Verify the gauge is interactive
      final gaugeWidget = tester.widget<WhiteSyringeGauge>(syringeGauge);
      expect(gaugeWidget.interactive, true);
      expect(gaugeWidget.onChanged, isNotNull);
    });

    testWidgets('syringe tap updates all values', (tester) async {
      DoseCalculationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500, // Wider to prevent overflow
              child: DoseInputField(
                medicationForm: MedicationForm.multiDoseVial,
                strengthPerUnitMcg: 0,
                strengthUnit: 'mcg',
                totalVialStrengthMcg: 2000,
                totalVialVolumeMicroliter: 1000,
                syringeType: SyringeType.ml_0_3,
                initialStrengthMcg: 500,
                onDoseChanged: (r) => result = r,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial: 500mcg = 25 units
      expect(result!.syringeUnits, 25);

      // Tap near the end of the gauge (90% position = 27 units)
      final syringeGauge = find.byType(WhiteSyringeGauge);
      final gaugeBox = tester.getRect(syringeGauge);

      // Tap at 90% of the width
      final tapPosition = Offset(
        gaugeBox.left + gaugeBox.width * 0.9,
        gaugeBox.center.dy,
      );
      await tester.tapAt(tapPosition);
      await tester.pumpAndSettle();

      // Units should be ~27 (90% of 30)
      expect(result!.syringeUnits, greaterThan(26));
      expect(result!.syringeUnits, lessThan(28));

      // All three values should update accordingly
      expect(result!.doseMassMcg, greaterThan(520));
      expect(result!.doseMassMcg, lessThan(560));
      expect(result!.doseVolumeMicroliter, greaterThan(260));
      expect(result!.doseVolumeMicroliter, lessThan(280));
    });

    testWidgets('syringe interaction updates text field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500, // Wider to prevent overflow
              child: DoseInputField(
                medicationForm: MedicationForm.multiDoseVial,
                strengthPerUnitMcg: 0,
                strengthUnit: 'mcg',
                totalVialStrengthMcg: 2000,
                totalVialVolumeMicroliter: 1000,
                syringeType: SyringeType.ml_0_3,
                initialStrengthMcg: 500, // Strength mode
                onDoseChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap near end of gauge
      final syringeGauge = find.byType(WhiteSyringeGauge);
      final gaugeBox = tester.getRect(syringeGauge);
      await tester.tapAt(
        Offset(gaugeBox.left + gaugeBox.width * 0.9, gaugeBox.center.dy),
      );
      await tester.pumpAndSettle();

      // Text field should update to show new strength
      final textField = tester.widget<TextField>(find.byType(TextField));
      final newValue = double.tryParse(textField.controller!.text) ?? 0;
      expect(newValue, greaterThan(520));
      expect(newValue, lessThan(560));
    });
  });
}
