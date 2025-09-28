import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

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
    this.neutral = false,
    this.outlined = false,
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
  // When true, renders with soft surface background and onSurface text colors (for medication list cards).
  final bool neutral;
  final bool outlined;

  String _fmt2(double? v) {
    if (v == null) return '-';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  // Convenience: build a header card directly from a Medication model
  factory SummaryHeaderCard.fromMedication(Medication m, {bool neutral = false, bool outlined = false}) {
    String unitLabel;
    switch (m.strengthUnit) {
      case Unit.mcg:
        unitLabel = 'mcg';
        break;
      case Unit.mg:
        unitLabel = 'mg';
        break;
      case Unit.g:
        unitLabel = 'g';
        break;
      default:
        unitLabel = m.strengthUnit.name;
    }
    String stockUnitLabel;
    switch (m.stockUnit) {
      case StockUnit.tablets:
        stockUnitLabel = 'tablets';
        break;
      default:
        stockUnitLabel = m.stockUnit.name;
    }
    final showDark = (m.storageInstructions?.toLowerCase().contains('light') ?? false);
    return SummaryHeaderCard(
      title: m.name,
      manufacturer: m.manufacturer,
      strengthValue: m.strengthValue,
      strengthUnitLabel: unitLabel,
      stockCurrent: m.stockValue,
      stockInitial: m.initialStockValue ?? m.stockValue,
      stockUnitLabel: stockUnitLabel,
      expiryDate: m.expiry,
      showRefrigerate: m.requiresRefrigeration,
      showFrozen: false, // not persisted in model currently
      showDark: showDark,
      lowStockEnabled: m.lowStockEnabled,
      lowStockThreshold: m.lowStockThreshold,
      neutral: neutral,
      outlined: outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool lowStockActive = lowStockEnabled && stockCurrent != null && lowStockThreshold != null && stockCurrent! <= lowStockThreshold!;

    final Color bg = neutral ? cs.surfaceContainerLowest : cs.primary;
    final Color fg = neutral ? cs.onSurface : cs.onPrimary;

    // Resolve localized expiry text if a DateTime was provided
    String? expDisplay;
    if (expiryDate != null) {
      expDisplay = MaterialLocalizations.of(context).formatCompactDate(expiryDate!);
    } else {
      expDisplay = expiryText;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: (neutral && outlined)
            ? Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 0.75)
            : null,
        boxShadow: neutral
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (neutral ? cs.primary : cs.onPrimary).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication, color: neutral ? cs.primary : fg),
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
                          color: neutral ? cs.primary : fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Top-right cluster: Expiry text only
                    if (expDisplay != null && expDisplay.isNotEmpty)
                      Text(
                        'Exp: $expDisplay',
                        style: theme.textTheme.bodySmall?.copyWith(color: fg),
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
                      color: fg.withOpacity(0.9),
                    ),
                  ),
                ],
                // Bottom area: left side (multi-line details), right side (storage icons)
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left cluster: each item on its own line for clarity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (strengthValue != null && strengthValue! > 0 && (strengthUnitLabel ?? '').isNotEmpty)
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(color: neutral ? cs.primary : fg),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: RichText(
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
                            ),
                          if (lowStockEnabled && lowStockThreshold != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (lowStockActive) ...[
                                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade300),
                                    const SizedBox(width: 4),
                                  ],
                                  RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall?.copyWith(
                                    color: lowStockActive
                                            ? Colors.amber.shade200
                                            : fg.withOpacity(0.9),
                                      ),
                                      children: [
                                        TextSpan(text: lowStockActive ? 'Low stock: ' : 'Alert at '),
                                        TextSpan(
                                          text: _fmt2(lowStockThreshold),
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        const TextSpan(text: ' left'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Right cluster: storage icons inline on the same bottom row, aligned bottom-right
                    if (showRefrigerate || showFrozen || showDark) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showRefrigerate)
                            Icon(Icons.kitchen, size: 18, color: fg),
                          if (showFrozen) ...[
                            if (showRefrigerate) const SizedBox(width: 6),
                            Icon(Icons.ac_unit, size: 18, color: fg),
                          ],
                          if (showDark) ...[
                            if (showRefrigerate || showFrozen) const SizedBox(width: 6),
                            Icon(Icons.dark_mode, size: 18, color: fg),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}