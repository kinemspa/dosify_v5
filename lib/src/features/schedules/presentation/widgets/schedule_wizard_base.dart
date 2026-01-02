// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/wizard_navigation_bar.dart';

/// Base class for schedule wizard pages.
/// Provides common wizard functionality: step indicator, navigation, validation.
/// Pattern matches MedicationWizardBase exactly.
abstract class ScheduleWizardBase extends StatefulWidget {
  const ScheduleWizardBase({super.key});

  /// Number of steps in this wizard
  int get stepCount;

  /// Labels for each step
  List<String> get stepLabels;
}

/// Base state for schedule wizard pages
abstract class ScheduleWizardState<T extends ScheduleWizardBase>
    extends State<T> {
  int _currentStep = 0;
  final _scrollController = ScrollController();

  int get currentStep => _currentStep;
  ScrollController get scrollController => _scrollController;

  /// Check if current step can proceed
  bool get canProceed;

  /// Build content for specific step
  Widget buildStepContent(int step);

  /// Build summary content displayed in gradient header
  Widget buildSummaryContent();

  /// Get label for specific step
  String getStepLabel(int step);

  /// Save schedule
  Future<void> saveSchedule();

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
                  const Expanded(
                    child: Text(
                      'Add Schedule',
                      style: TextStyle(
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

  Widget _buildNavigationBar() {
    return WizardNavigationBar(
      currentStep: _currentStep,
      stepCount: widget.stepCount,
      canProceed: canProceed,
      onBack: _currentStep > 0 ? previousStep : null,
      onContinue: nextStep,
      onSave: saveSchedule,
      saveLabel: 'Save Schedule',
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
