// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/widgets/unified_form.dart';

/// A reusable editor template that mirrors the Add Tablet screen layout exactly.
///
/// - Pinned floating summary card overlay (caller provides the summary widget)
/// - Four standard sections (General, Strength, Inventory, Storage)
/// - Left-label / right-field rows using LabelFieldRow
/// - Fixed-width compact controls (SmallDropdown36/DateButton36) inside the sections
/// - Support/helper rows under fields with consistent spacing
///
/// Usage: provide the exact field widgets used in Add Tablet for perfect visual parity.
class MedEditorTemplate extends StatefulWidget {
  const MedEditorTemplate({
    required this.appBarTitle,
    required this.summaryBuilder, // General
    required this.nameField,
    required this.manufacturerField,
    required this.descriptionField,
    required this.notesField, // Strength
    required this.strengthStepper,
    required this.unitDropdown, // Inventory
    required this.stockStepper,
    required this.expiryDateButton, // Storage
    required this.batchField,
    required this.locationField,
    required this.refrigerateRow,
    required this.freezeRow,
    required this.darkRow,
    required this.storageInstructionsField,
    super.key,
    this.nameHelp,
    this.manufacturerHelp,
    this.descriptionHelp,
    this.notesHelp,
    this.perMlStepper,
    this.strengthHelp,
    this.perMlHelp,
    this.quantityDropdown,
    this.stockHelp,
    this.expiryHelp,
    this.lowStockRow,
    this.lowStockThresholdField,
    this.lowStockHelp,
    this.lowStockHelpColor,
    this.batchHelp,
    this.locationHelp,
    this.refrigerateHelp,
    this.freezeHelp,
    this.darkHelp,
    this.storageInstructionsHelp,

    // Optional top intro under General title
    this.generalIntro,

    // Optional MDV section (rendered between Strength and Inventory)
    this.mdvSection,
  });

  final String appBarTitle;
  final Widget Function(GlobalKey key) summaryBuilder;

  // General
  final Widget nameField;
  final Widget manufacturerField;
  final Widget descriptionField;
  final Widget notesField;
  final String? nameHelp;
  final String? manufacturerHelp;
  final String? descriptionHelp;
  final String? notesHelp;

  // Strength
  final Widget strengthStepper;
  final Widget unitDropdown;
  final Widget? perMlStepper;
  final String? strengthHelp;
  final String? perMlHelp;

  // Inventory
  final Widget stockStepper;
  final Widget? quantityDropdown;
  final Widget expiryDateButton;
  final String? stockHelp;
  final String? expiryHelp;
  // Optional low stock controls
  final Widget? lowStockRow;
  final Widget? lowStockThresholdField;
  final String? lowStockHelp;
  final Color? lowStockHelpColor;

  // Storage
  final Widget batchField;
  final Widget locationField;
  final Widget refrigerateRow;
  final Widget freezeRow;
  final Widget darkRow;
  final Widget storageInstructionsField;
  final String? batchHelp;
  final String? locationHelp;
  final String? refrigerateHelp;
  final String? freezeHelp;
  final String? darkHelp;
  final String? storageInstructionsHelp;

  // Optional intro under General title
  final String? generalIntro;

  // Optional MDV Volume & Reconstitution section (rendered between Strength and Inventory)
  final Widget? mdvSection;

  @override
  State<MedEditorTemplate> createState() => _MedEditorTemplateState();
}

class _MedEditorTemplateState extends State<MedEditorTemplate> {
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 0;

  void _measureSummary() {
    final ctx = _summaryKey.currentContext;
    if (ctx == null) return;
    final rb = ctx.findRenderObject();
    if (rb is RenderBox) {
      final h = rb.size.height;
      if (h > 0 && h != _summaryHeight) setState(() => _summaryHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSummary());
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: _summaryHeight + 10),

              // General
              SectionFormCard(
                title: 'General',
                neutral: true,
                children: [
                  if (widget.generalIntro != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 6,
                      ),
                      child: Text(
                        widget.generalIntro!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  LabelFieldRow(label: 'Name *', field: widget.nameField),
                  _support(widget.nameHelp),
                  LabelFieldRow(
                    label: 'Manufacturer',
                    field: widget.manufacturerField,
                  ),
                  _support(widget.manufacturerHelp),
                  LabelFieldRow(
                    label: 'Description',
                    field: widget.descriptionField,
                  ),
                  _support(widget.descriptionHelp),
                  LabelFieldRow(label: 'Notes', field: widget.notesField),
                  _support(widget.notesHelp),
                ],
              ),
              const SizedBox(height: 12),

              // Strength
              SectionFormCard(
                title: 'Strength',
                neutral: true,
                children: [
                  LabelFieldRow(
                    label: 'Strength *',
                    field: widget.strengthStepper,
                  ),
                  LabelFieldRow(label: 'Unit *', field: widget.unitDropdown),
                  // Show strength help first, then perMl section when applicable
                  _support(widget.strengthHelp),
                  if (widget.perMlStepper != null)
                    LabelFieldRow(label: 'Per mL', field: widget.perMlStepper!),
                  if (widget.perMlStepper != null) _support(widget.perMlHelp),
                ],
              ),
              const SizedBox(height: 12),

              // MDV Volume & Reconstitution section (optional, only for multi-dose vials)
              if (widget.mdvSection != null) ...[
                widget.mdvSection!,
                const SizedBox(height: 12),
              ],

              // Inventory
              SectionFormCard(
                title: 'Inventory',
                neutral: true,
                children: [
                  LabelFieldRow(
                    label: 'Stock quantity *',
                    field: widget.stockStepper,
                  ),
                  _support(widget.stockHelp),
                  // Show Quantity unit only if provided (optional for auto-determined stock units)
                  if (widget.quantityDropdown != null)
                    LabelFieldRow(
                      label: 'Quantity unit',
                      field: widget.quantityDropdown!,
                    ),
                  if (widget.lowStockRow != null)
                    LabelFieldRow(
                      label: 'Low stock alert',
                      field: widget.lowStockRow!,
                    ),
                  if (widget.lowStockThresholdField != null)
                    LabelFieldRow(
                      label: 'Threshold',
                      field: widget.lowStockThresholdField!,
                    ),
                  if (widget.lowStockHelp != null)
                    _supportColored(
                      widget.lowStockHelp,
                      widget.lowStockHelpColor,
                    ),
                  LabelFieldRow(
                    label: 'Expiry date',
                    field: widget.expiryDateButton,
                  ),
                  _support(widget.expiryHelp),
                ],
              ),
              const SizedBox(height: 12),

              // Storage
              SectionFormCard(
                title: 'Storage',
                neutral: true,
                children: [
                  LabelFieldRow(label: 'Batch No.', field: widget.batchField),
                  _support(widget.batchHelp),
                  LabelFieldRow(label: 'Location', field: widget.locationField),
                  _support(widget.locationHelp),
                  LabelFieldRow(
                    label: 'Keep refrigerated',
                    field: widget.refrigerateRow,
                  ),
                  _support(widget.refrigerateHelp),
                  LabelFieldRow(label: 'Keep frozen', field: widget.freezeRow),
                  _support(widget.freezeHelp),
                  LabelFieldRow(label: 'Keep in dark', field: widget.darkRow),
                  _support(widget.darkHelp),
                  LabelFieldRow(
                    label: 'Storage instructions',
                    field: widget.storageInstructionsField,
                  ),
                  _support(widget.storageInstructionsHelp),
                ],
              ),
            ],
          ),
        ),
        // Floating summary overlay
        Positioned(
          left: 16,
          right: 16,
          top: 8,
          child: IgnorePointer(child: widget.summaryBuilder(_summaryKey)),
        ),
      ],
    );
  }

  Widget _support(String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        left: kLabelColWidth + 8,
        top: 2,
        bottom: 6,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _supportColored(String? text, Color? color) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(
        left: kLabelColWidth + 8,
        top: 2,
        bottom: 6,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color:
              color ??
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
        ),
      ),
    );
  }
}
