import 'package:flutter/material.dart';

class SummaryHeaderCard extends StatelessWidget {
  const SummaryHeaderCard({
    super.key,
    required this.title,
    this.manufacturer,
    this.strengthValue,
    this.strengthUnitLabel,
    this.stockCurrent,
    this.stockInitial,
    this.stockUnitLabel,
    this.expiryText,
    this.expiryDate,
    this.showRefrigerate = false,
    this.showFrozen = false,
    this.showDark = false,
    this.lowStockEnabled = false,
    this.lowStockThreshold,
  });

  final String title;
  final String? manufacturer;
  final double? strengthValue;
  final String? strengthUnitLabel;
  final double? stockCurrent;
  final double? stockInitial;
  final String? stockUnitLabel;
  final String? expiryText;
  final DateTime? expiryDate;
  final bool showRefrigerate;
  final bool showFrozen;
  final bool showDark;
  final bool lowStockEnabled;
  final double? lowStockThreshold;

  String _fmt2(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool lowStockActive = lowStockEnabled && stockCurrent != null && lowStockThreshold != null && stockCurrent! <= lowStockThreshold!;

    // Resolve localized expiry text if a DateTime was provided
    String? expDisplay;
    if (expiryDate != null) {
      expDisplay = MaterialLocalizations.of(context).formatCompactDate(expiryDate!);
    } else {
      expDisplay = expiryText;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication, color: cs.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Top-right cluster: Expiry text only
                    if (expDisplay != null && expDisplay.isNotEmpty)
                      Text(
                        'Exp: $expDisplay',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimary),
                      ),
                  ],
                ),
                if ((manufacturer ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    manufacturer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
                // Bottom row: left side (strength + stock + low-stock), right side (storage icons)
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left cluster uses Wrap for responsive flow
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          if (strengthValue != null && strengthValue! > 0 && (strengthUnitLabel ?? '').isNotEmpty)
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimary),
                                children: [
                                  TextSpan(
                                    text: _fmt2(strengthValue),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  TextSpan(text: ' $strengthUnitLabel '),
                                  const TextSpan(text: 'per tablet'),
                                ],
                              ),
                            ),
                          if (stockCurrent != null && (stockUnitLabel ?? '').isNotEmpty)
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimary),
                                children: [
                                  TextSpan(
                                    text: _fmt2(stockCurrent),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  if (stockInitial != null) ...[
                                    const TextSpan(text: '/'),
                                    TextSpan(
                                      text: _fmt2(stockInitial),
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                  TextSpan(text: ' $stockUnitLabel remain'),
                                ],
                              ),
                            ),
                          if (lowStockEnabled && lowStockThreshold != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (lowStockActive)
                                  ...[
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade300),
                                    const SizedBox(width: 2),
                                  ],
                                Text(
                                  lowStockActive
                                      ? 'Low stock (≤ ${_fmt2(lowStockThreshold)})'
                                      : 'Alert at ≤ ${_fmt2(lowStockThreshold)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: lowStockActive
                                        ? Colors.amber.shade200
                                        : cs.onPrimary.withOpacity(0.9),
                                    fontWeight: lowStockActive ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Right cluster: storage icons inline on the same bottom row
                    if (showRefrigerate || showFrozen || showDark) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showRefrigerate)
                            Icon(Icons.kitchen, size: 18, color: cs.onPrimary),
                          if (showFrozen) ...[
                            if (showRefrigerate) const SizedBox(width: 6),
                            Icon(Icons.ac_unit, size: 18, color: cs.onPrimary),
                          ],
                          if (showDark) ...[
                            if (showRefrigerate || showFrozen) const SizedBox(width: 6),
                            Icon(Icons.dark_mode, size: 18, color: cs.onPrimary),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
                // Bottom-right storage icons
                if (showRefrigerate || showFrozen || showDark) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showRefrigerate)
                          Icon(Icons.kitchen, size: 18, color: cs.onPrimary),
                        if (showFrozen) ...[
                          if (showRefrigerate) const SizedBox(width: 6),
                          Icon(Icons.ac_unit, size: 18, color: cs.onPrimary),
                        ],
                        if (showDark) ...[
                          if (showRefrigerate || showFrozen) const SizedBox(width: 6),
                          Icon(Icons.dark_mode, size: 18, color: cs.onPrimary),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}