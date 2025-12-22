import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
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
                        style: TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Toggle Mode Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDaysMode = !_isDaysMode;
                              if (_isDaysMode) {
                                _updateDaysController();
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDaysMode
                                      ? Icons.calendar_today
                                      : Icons.edit_calendar,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isDaysMode ? 'Pick Date' : 'Enter Days',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEE, MMM d, y').format(_selectedDate),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? colorScheme.errorContainer
                          : colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isExpired
                          ? 'Expired ${daysUntil.abs()} days ago'
                          : '$daysUntil days remaining',
                      style: TextStyle(
                        color: isExpired
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (_isDaysMode)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Enter days until expiry',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'days',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      onChanged: _updateDateFromDays,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculated date will update automatically',
                      style: theme.textTheme.bodySmall?.copyWith(
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
