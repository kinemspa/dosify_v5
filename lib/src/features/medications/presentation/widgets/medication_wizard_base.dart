// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';

/// Base class for medication wizard pages.
/// Provides common wizard functionality: step indicator, navigation, validation.
abstract class MedicationWizardBase extends ConsumerStatefulWidget {
  const MedicationWizardBase({super.key, this.initial});

  final Medication? initial;

  /// Number of steps in this wizard
  int get stepCount;

  /// Labels for each step
  List<String> get stepLabels;
}

/// Base state for medication wizard pages
abstract class MedicationWizardState<T extends MedicationWizardBase>
    extends ConsumerState<T> {
  int _currentStep = 0;
  final _scrollController = ScrollController();

  int get currentStep => _currentStep;
  ScrollController get scrollController => _scrollController;

  /// Check if current step can proceed
  bool get canProceed;

  /// Build content for specific step
  Widget buildStepContent(int step);

  /// Get label for specific step
  String getStepLabel(int step);

  /// Save medication
  Future<void> saveMedication();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (canProceed && _currentStep < widget.stepCount - 1) {
      setState(() => _currentStep++);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildUnifiedHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: buildStepContent(_currentStep),
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMedicationDetailGradientStart,
            kMedicationDetailGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.initial == null
                          ? 'Add Medication'
                          : 'Edit Medication',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (int i = 0; i < widget.stepCount; i++) ...{
                    _StepCircle(
                      number: i + 1,
                      isActive: i == _currentStep,
                      isCompleted: i < _currentStep,
                    ),
                    if (i < widget.stepCount - 1)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i < _currentStep
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  },
                ],
              ),
            ),
            // Current step label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                getStepLabel(_currentStep),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.15),
            ),
            // Summary content with fixed min height
            Container(
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.all(12),
              child: buildSummaryContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary card content - to be implemented by subclasses
  Widget buildSummaryContent();

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canProceed
                  ? (_currentStep < widget.stepCount - 1
                        ? nextStep
                        : saveMedication)
                  : null,
              child: Text(
                _currentStep < widget.stepCount - 1
                    ? 'Continue'
                    : 'Save Medication',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.isActive,
    required this.isCompleted,
  });

  final int number;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? cs.onPrimary
            : cs.onPrimary.withValues(alpha: 0.2),
        border: Border.all(
          color: isCompleted || isActive
              ? cs.onPrimary
              : cs.onPrimary.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 12, color: cs.primary)
            : Text(
                number.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isActive
                      ? cs.primary
                      : cs.onPrimary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
      ),
    );
  }
}
