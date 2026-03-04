// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/schedules/domain/calculated_entry.dart';
import 'package:dosifi_v5/src/features/schedules/domain/entry_calculator.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/widgets/entry_status_ui.dart';
import 'package:dosifi_v5/src/widgets/white_syringe_gauge.dart';

class EntryDialogEntryPreview extends StatelessWidget {
  const EntryDialogEntryPreview({
    required this.med,
    required this.schedule,
    required this.status,
    super.key,
  });

  final Medication med;
  final Schedule schedule;
  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final visual = entryStatusVisual(context, status, disabled: false);
    final statusColor = visual.color;
    final statusIcon = visual.icon;

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

    final units = schedule.entryIU?.toDouble();
    final volumeMicroliter = schedule.entryVolumeMicroliter?.toDouble();
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

  List<_EntryValueRow> _buildValueRows() {
    final entryMass = schedule.entryMassMcg?.toDouble();
    final entryVolume = schedule.entryVolumeMicroliter?.toDouble();
    final entryUnits = schedule.entryIU?.toDouble();

    final countRow = _countRow();

    final massRow = entryMass != null
        ? _EntryValueRow(
            label: 'Entry',
            value: MedicationDisplayHelpers.formatEntryMassFromMcg(
              med,
              entryMass,
            ),
          )
        : null;

    final volumeRow = entryVolume != null
        ? _EntryValueRow(
            label: 'Volume',
            value: MedicationDisplayHelpers.formatEntryVolumeFromMicroliter(
              entryVolume,
            ),
          )
        : null;

    final unitsRow = entryUnits != null
        ? _EntryValueRow(
            label: 'Units',
            value: MedicationDisplayHelpers.formatSyringeUnits(entryUnits),
          )
        : null;

    final preferred = <_EntryValueRow>[
      if (massRow != null) massRow,
      if (volumeRow != null) volumeRow,
      if (unitsRow != null) unitsRow,
    ];

    if (preferred.length >= 2) {
      return preferred.take(3).toList();
    }

    final fallback = <_EntryValueRow>[
      if (countRow != null) countRow,
      ...preferred,
    ];

    if (fallback.isNotEmpty) return fallback.take(3).toList();

    final metrics = schedule.displayMetrics(med);

    return [
      if (metrics.trim().isNotEmpty)
        _EntryValueRow(label: 'Entry', value: metrics),
    ];
  }

  _EntryValueRow? _countRow() {
    switch (med.form) {
      case MedicationForm.prefilledSyringe:
        final n = schedule.entrySyringes;
        if (n == null) return null;
        return _EntryValueRow(
          label: 'Count',
          value: '$n ${n == 1 ? 'syringe' : 'syringes'}',
        );
      case MedicationForm.singleDoseVial:
        final n = schedule.entryVials;
        if (n == null) return null;
        return _EntryValueRow(
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

  
}

class _EntryValueRow {
  const _EntryValueRow({required this.label, required this.value});

  final String label;
  final String value;
}

class EntryDialogEntryFallbackSummary extends StatelessWidget {
  const EntryDialogEntryFallbackSummary({required this.entry, super.key});

  final CalculatedEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(entry.scheduledTime);
    final time = DateTimeFormatter.formatTime(context, entry.scheduledTime);

    final entryText = '${_formatEntryValue(entry.entryValue)} ${entry.entryUnit}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.scheduleName,
          style: bodyTextStyle(
            context,
          )?.copyWith(fontWeight: kFontWeightSemiBold, color: cs.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingXXS),
        Text(
          entry.medicationName,
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
              child: Text('Entry', style: fieldLabelStyle(context)),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: Text(
                entryText,
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
                '$date | $time',
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

  String _formatEntryValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    var str = value.toStringAsFixed(3);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
