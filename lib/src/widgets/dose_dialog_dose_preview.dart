// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_dose.dart';
import 'package:dosifi_v5/src/features/schedules/domain/dose_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

class DoseDialogDosePreview extends StatelessWidget {
  const DoseDialogDosePreview({
    required this.med,
    required this.schedule,
    required this.status,
    super.key,
  });

  final Medication med;
  final Schedule schedule;
  final DoseStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusColor, statusIcon) = _statusPresentation(context, status);

    final strengthLabel = MedicationDisplayHelpers.strengthOrConcentrationLabel(
      med,
    );

    final values = _buildValueRows();

    final gauge = _buildGaugeIfNeeded();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                med.name,
                style: bodyTextStyle(
                  context,
                )?.copyWith(fontWeight: kFontWeightSemiBold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: kSpacingXXS),
              if (strengthLabel.trim().isNotEmpty) ...[
                Text(
                  strengthLabel,
                  style: helperTextStyle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingS),
              ],
              if (gauge != null) ...[gauge, const SizedBox(height: kSpacingS)],
              ...values.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: kSpacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(v.label, style: fieldLabelStyle(context)),
                      ),
                      const SizedBox(width: kSpacingM),
                      Expanded(
                        child: Text(
                          v.value,
                          style: bodyTextStyle(context)?.copyWith(
                            color: cs.onSurface.withValues(
                              alpha: kOpacityMediumHigh,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: kSpacingM),
        Container(
          width: kLargeButtonHeight,
          height: kLargeButtonHeight,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: kOpacityMinimal),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, size: kIconSizeMedium, color: statusColor),
        ),
      ],
    );
  }

  Widget? _buildGaugeIfNeeded() {
    if (!_isInjection(med.form)) return null;

    final units = schedule.doseIU?.toDouble();
    final volumeMicroliter = schedule.doseVolumeMicroliter?.toDouble();
    final volumeMl = volumeMicroliter != null
        ? (volumeMicroliter / 1000)
        : null;

    if (units == null && volumeMl == null) return null;

    final syringeType = units != null
        ? SyringeTypeLookup.forUnits(units)
        : SyringeTypeLookup.forVolumeMl(volumeMl!);
    final totalUnits = syringeType.maxUnits;

    final fillUnits = units ?? (volumeMl! * syringeType.unitsPerMl);

    return WhiteSyringeGauge(
      totalUnits: totalUnits,
      fillUnits: fillUnits.clamp(0.0, totalUnits),
      showValueLabel: false,
    );
  }

  List<_DoseValueRow> _buildValueRows() {
    final doseMass = schedule.doseMassMcg?.toDouble();
    final doseVolume = schedule.doseVolumeMicroliter?.toDouble();
    final doseUnits = schedule.doseIU?.toDouble();

    final countRow = _countRow();

    final massRow = doseMass != null
        ? _DoseValueRow(
            label: 'Dose',
            value: MedicationDisplayHelpers.formatDoseMassFromMcg(
              med,
              doseMass,
            ),
          )
        : null;

    final volumeRow = doseVolume != null
        ? _DoseValueRow(
            label: 'Volume',
            value: MedicationDisplayHelpers.formatDoseVolumeFromMicroliter(
              doseVolume,
            ),
          )
        : null;

    final unitsRow = doseUnits != null
        ? _DoseValueRow(
            label: 'Units',
            value: MedicationDisplayHelpers.formatSyringeUnits(doseUnits),
          )
        : null;

    final preferred = <_DoseValueRow>[
      if (massRow != null) massRow,
      if (volumeRow != null) volumeRow,
      if (unitsRow != null) unitsRow,
    ];

    if (preferred.length >= 2) {
      return preferred.take(3).toList();
    }

    final fallback = <_DoseValueRow>[
      if (countRow != null) countRow,
      ...preferred,
    ];

    if (fallback.isNotEmpty) return fallback.take(3).toList();

    final metrics = MedicationDisplayHelpers.doseMetricsSummary(
      med,
      doseTabletQuarters: schedule.doseTabletQuarters,
      doseCapsules: schedule.doseCapsules,
      doseSyringes: schedule.doseSyringes,
      doseVials: schedule.doseVials,
      doseMassMcg: schedule.doseMassMcg?.toDouble(),
      doseVolumeMicroliter: schedule.doseVolumeMicroliter?.toDouble(),
      syringeUnits: schedule.doseIU?.toDouble(),
    );

    return [
      if (metrics.trim().isNotEmpty)
        _DoseValueRow(label: 'Dose', value: metrics),
    ];
  }

  _DoseValueRow? _countRow() {
    switch (med.form) {
      case MedicationForm.prefilledSyringe:
        final n = schedule.doseSyringes;
        if (n == null) return null;
        return _DoseValueRow(
          label: 'Count',
          value: '$n ${n == 1 ? 'syringe' : 'syringes'}',
        );
      case MedicationForm.singleDoseVial:
        final n = schedule.doseVials;
        if (n == null) return null;
        return _DoseValueRow(
          label: 'Count',
          value: '$n ${n == 1 ? 'vial' : 'vials'}',
        );
      case MedicationForm.multiDoseVial:
      case MedicationForm.tablet:
      case MedicationForm.capsule:
        return null;
    }
  }

  bool _isInjection(MedicationForm form) {
    return form == MedicationForm.prefilledSyringe ||
        form == MedicationForm.singleDoseVial ||
        form == MedicationForm.multiDoseVial;
  }

  (Color, IconData) _statusPresentation(
    BuildContext context,
    DoseStatus status,
  ) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case DoseStatus.taken:
        return (kDoseStatusTakenGreen, Icons.check_rounded);
      case DoseStatus.skipped:
        return (cs.error, Icons.block_rounded);
      case DoseStatus.snoozed:
        return (kDoseStatusSnoozedOrange, Icons.snooze_rounded);
      case DoseStatus.overdue:
        return (cs.error, Icons.warning_rounded);
      case DoseStatus.pending:
        return (cs.primary, Icons.notifications_rounded);
    }
  }
}

class _DoseValueRow {
  const _DoseValueRow({required this.label, required this.value});

  final String label;
  final String value;
}

class DoseDialogDoseFallbackSummary extends StatelessWidget {
  const DoseDialogDoseFallbackSummary({required this.dose, super.key});

  final CalculatedDose dose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(dose.scheduledTime);
    final time = TimeOfDay.fromDateTime(dose.scheduledTime).format(context);

    final doseText = '${_formatDoseValue(dose.doseValue)} ${dose.doseUnit}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dose.scheduleName,
          style: bodyTextStyle(
            context,
          )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXXS),
        Text(
          dose.medicationName,
          style: bodyTextStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('Dose', style: fieldLabelStyle(context)),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: Text(
                doseText,
                style: bodyTextStyle(context)?.copyWith(
                  color: cs.onSurface.withValues(alpha: kOpacityMediumHigh),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('Scheduled', style: fieldLabelStyle(context)),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: Text(
                '$date • $time',
                style: bodyTextStyle(context)?.copyWith(
                  color: cs.onSurface.withValues(alpha: kOpacityMediumHigh),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDoseValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    var str = value.toStringAsFixed(3);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
