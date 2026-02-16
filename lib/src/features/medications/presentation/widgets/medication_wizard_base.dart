// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/widgets/wizard_navigation_bar.dart';

/// Base class for medication wizard pages.
/// Provides common wizard functionality: step indicator, navigation, validation.
abstract class MedicationWizardBase extends ConsumerStatefulWidget {
  const MedicationWizardBase({
    super.key,
    this.initial,
    this.initialMedicationId,
  });

  final Medication? initial;
  final String? initialMedicationId;

  bool get isEditing => initial != null || initialMedicationId != null;

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
  final _stepFocusScope = FocusScopeNode();
  bool _showDownScrollHint = false;

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
    _stepFocusScope.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _updateDownScrollHint(_scrollController.position);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildUnifiedHeader(),
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      _updateDownScrollHint(notification.metrics);
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: FocusScope(
                      node: _stepFocusScope,
                      child: buildStepContent(_currentStep),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedOpacity(
                      opacity: _showDownScrollHint ? 1 : 0,
                      duration: kAnimationFast,
                      curve: kCurveSnappy,
                      child: Padding(
                        padding: kWizardScrollHintPadding,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: kWizardScrollHintIconSize,
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: kOpacityMediumHigh),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  void _updateDownScrollHint(ScrollMetrics metrics) {
    final shouldShow = metrics.maxScrollExtent > (metrics.pixels + 0.5);
    if (_showDownScrollHint == shouldShow) return;
    if (!mounted) return;
    setState(() => _showDownScrollHint = shouldShow);
  }

  Widget _buildUnifiedHeader() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final headerFg = medicationDetailHeaderForegroundColor(context);

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
                    icon: Icon(Icons.arrow_back, color: headerFg),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Edit Medication' : 'Add Medication',
                      style: wizardHeaderTitleTextStyle(
                        context,
                        color: headerFg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: keyboardOpen
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                children: [
                  // Step indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        for (int i = 0; i < widget.stepCount; i++) ...[
                          _StepCircle(
                            number: i + 1,
                            isActive: i == _currentStep,
                            isCompleted: i < _currentStep,
                          ),
                          if (i < widget.stepCount - 1)
                            Expanded(
                              child: Container(
                                height: 1.5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: i < _currentStep
                                      ? headerFg
                                      : headerFg.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Current step label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      getStepLabel(_currentStep),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: headerFg.withValues(alpha: 0.85),
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
                    color: headerFg.withValues(alpha: 0.15),
                  ),
                  // Summary content
                  Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    padding: const EdgeInsets.all(12),
                    child: buildSummaryContent(),
                  ),
                ],
              ),
              secondChild: Divider(
                height: 1,
                thickness: 1,
                color: headerFg.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary card content - to be implemented by subclasses
  Widget buildSummaryContent();

  Widget _buildNavigationBar() {
    return WizardNavigationBar(
      currentStep: _currentStep,
      stepCount: widget.stepCount,
      canProceed: canProceed,
      onBack: _currentStep > 0 ? previousStep : null,
      onContinue: nextStep,
      onSave: saveMedication,
      saveLabel: 'Save Medication',
      fieldFocusScope: _stepFocusScope,
      continueLabel: 'Continue',
      nextLabel: 'Next',
      nextPageLabel: 'Continue',
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
    final headerFg = medicationDetailHeaderForegroundColor(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? headerFg
            : headerFg.withValues(alpha: 0.2),
        border: Border.all(
          color: isCompleted || isActive
              ? headerFg
              : headerFg.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check, size: 12, color: cs.primary)
            : Text(
                number.toString(),
                style: wizardStepNumberTextStyle(
                  context,
                  color: isActive
                      ? cs.primary
                      : headerFg.withValues(alpha: 0.6),
                )?.copyWith(fontWeight: kFontWeightExtraBold),
              ),
      ),
    );
  }
}
