import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/medication.dart';
import '../../../widgets/unified_form.dart';

/// Card showing status of currently active reconstituted vial
class ActiveVialStatusCard extends StatelessWidget {
  const ActiveVialStatusCard({
    super.key,
    required this.activeVial,
    required this.medicationName,
    required this.strengthValue,
    required this.strengthUnit,
    required this.onDiscard,
  });

  final ActiveVial activeVial;
  final String medicationName;
  final double strengthValue;
  final String strengthUnit;
  final VoidCallback onDiscard;

  Color _getStatusColor(BuildContext context) {
    if (activeVial.isExpired) {
      return Theme.of(context).colorScheme.error;
    } else if (activeVial.isApproachingExpiry) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (activeVial.isExpired) {
      return 'EXPIRED - Discard immediately';
    } else if (activeVial.isApproachingExpiry) {
      return 'Expiring soon';
    } else {
      return 'Active';
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) {
      return 'Expired';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 24) {
      final days = hours ~/ 24;
      return '$days day${days == 1 ? '' : 's'} remaining';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);

    return SectionFormCard(
      title: 'Active Reconstituted Vial',
      neutral: false,
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                activeVial.isExpired
                    ? Icons.dangerous
                    : activeVial.isApproachingExpiry
                        ? Icons.warning_amber
                        : Icons.check_circle,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeRemaining(activeVial.timeUntilExpiry),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reconstitution details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                context,
                Icons.science,
                'Reconstituted',
                DateFormat('MMM d, y h:mm a').format(activeVial.reconstitutionDate),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.schedule,
                'Expires',
                DateFormat('MMM d, y h:mm a').format(activeVial.expiryDate),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.water_drop,
                'Volume',
                '${activeVial.volumeMl.toStringAsFixed(activeVial.volumeMl == activeVial.volumeMl.roundToDouble() ? 0 : 1)} mL',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.straighten,
                'Concentration',
                '${activeVial.concentrationPerMl.toStringAsFixed(activeVial.concentrationPerMl == activeVial.concentrationPerMl.roundToDouble() ? 0 : 1)} $strengthUnit/mL',
              ),
              if (activeVial.diluentName != null) ...{
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.local_drink,
                  'Diluent',
                  activeVial.diluentName!,
                ),
              },
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                Icons.ac_unit,
                'Storage',
                'Refrigerator (2-8°C)',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action button
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onDiscard,
            icon: const Icon(Icons.delete_outline),
            label: Text(activeVial.isExpired ? 'Discard Expired Vial' : 'Discard Vial'),
            style: FilledButton.styleFrom(
              backgroundColor: activeVial.isExpired
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: activeVial.isExpired
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
