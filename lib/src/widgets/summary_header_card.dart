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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (expiryText != null && expiryText!.isNotEmpty)
                          Text(
                            'Exp: $expiryText',
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimary),
                          ),
                        if (showRefrigerate)
                          Icon(Icons.kitchen, size: 18, color: cs.onPrimary),
                        if (showFrozen)
                          Icon(Icons.ac_unit, size: 18, color: cs.onPrimary),
                        if (showDark)
                          Icon(Icons.dark_mode, size: 18, color: cs.onPrimary),
                      ],
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
                if (strengthValue != null && strengthValue! > 0 && (strengthUnitLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
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
                ],
                if (stockCurrent != null && stockInitial != null && (stockUnitLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onPrimary),
                          children: [
                            TextSpan(
                              text: _fmt2(stockCurrent),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: '/'),
                            TextSpan(
                              text: _fmt2(stockInitial),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: ' $stockUnitLabel remain'),
                          ],
                        ),
                      ),
                      if (lowStockActive) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber.shade300),
                        const SizedBox(width: 2),
                        Text(
                          lowStockThreshold != null
                              ? 'Low stock (≤ ${_fmt2(lowStockThreshold)})'
                              : 'Low stock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade200,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
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