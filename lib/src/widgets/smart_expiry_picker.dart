import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';

class SmartExpiryPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const SmartExpiryPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final now = DateTime.now();
    return showDialog<DateTime>(
      context: context,
      builder: (context) => SmartExpiryPicker(
        initialDate:
            initialDate ??
            now.add(const Duration(days: kDefaultMedicationExpiryDays)),
        firstDate: firstDate ?? now.subtract(const Duration(days: 365)),
        lastDate: lastDate ?? now.add(const Duration(days: 365 * 10)),
      ),
    );
  }

  @override
  State<SmartExpiryPicker> createState() => _SmartExpiryPickerState();
}

class _SmartExpiryPickerState extends State<SmartExpiryPicker> {
  late DateTime _selectedDate;
  bool _isDaysMode = false;
  final _daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _updateDaysController();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _updateDaysController() {
    final days = _selectedDate.difference(DateTime.now()).inDays;
    _daysController.text = days.toString();
  }

  void _updateDateFromDays(String value) {
    final days = int.tryParse(value);
    if (days != null) {
      setState(() {
        _selectedDate = DateTime.now().add(Duration(days: days));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysUntil = _selectedDate.difference(DateTime.now()).inDays;
    final isExpired = daysUntil < 0;

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(kSpacingL),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kBorderRadiusLarge),
                ),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expiry Date',
                        style: helperTextStyle(
                          context,
                          color: colorScheme.onPrimary.withValues(
                            alpha: kOpacityMediumHigh,
                          ),
                        )?.copyWith(fontWeight: kFontWeightMedium),
                      ),
                      // Toggle Mode Button
                      Material(
                        color: colorScheme.surface.withValues(alpha: 0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDaysMode = !_isDaysMode;
                              if (_isDaysMode) {
                                _updateDaysController();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSpacingS,
                              vertical: kSpacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDaysMode
                                      ? Icons.calendar_today
                                      : Icons.edit_calendar,
                                  size: kIconSizeXXSmall,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: kSpacingXS),
                                Text(
                                  _isDaysMode ? 'Pick Date' : 'Enter Days',
                                  style: microHelperTextStyle(
                                    context,
                                    color: colorScheme.onPrimary,
                                  )?.copyWith(fontWeight: kFontWeightBold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kSpacingS),
                  Text(
                    DateFormat('EEE, MMM d, y').format(_selectedDate),
                    style: detailCollapsedTitleTextStyle(context)?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: kFontWeightBold,
                    ),
                  ),
                  const SizedBox(height: kSpacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpacingS,
                      vertical: kSpacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? colorScheme.errorContainer
                          : colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(kBorderRadiusChipTight),
                    ),
                    child: Text(
                      isExpired
                          ? 'Expired ${daysUntil.abs()} days ago'
                          : '$daysUntil days remaining',
                      style: helperTextStyle(
                        context,
                        color: isExpired
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimary,
                      )?.copyWith(fontWeight: kFontWeightBold),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (_isDaysMode)
              Padding(
                padding: const EdgeInsets.all(kSpacingXXL),
                child: Column(
                  children: [
                    Text(
                      'Enter days until expiry',
                      style: sectionTitleStyle(context),
                    ),
                    const SizedBox(height: kSpacingL),
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: detailHeaderBannerTitleTextStyle(context)?.copyWith(
                        fontWeight: kFontWeightBold,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'days',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: kSpacingL,
                          horizontal: kSpacingL,
                        ),
                      ),
                      onChanged: _updateDateFromDays,
                    ),
                    const SizedBox(height: kSpacingS),
                    Text(
                      'Calculated date will update automatically',
                      style: helperTextStyle(
                        context,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 300,
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedDate),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
