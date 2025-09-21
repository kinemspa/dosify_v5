import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

/// Minimal Tablet editor that renders ONLY the General section.
/// This is used to isolate rendering issues step-by-step.
class AddEditTabletGeneralPage extends StatefulWidget {
  const AddEditTabletGeneralPage({super.key});

  @override
  State<AddEditTabletGeneralPage> createState() => _AddEditTabletGeneralPageState();
}

class _AddEditTabletGeneralPageState extends State<AddEditTabletGeneralPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // Strength fields (next section)
  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minHeight: 40),
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant),
      helperStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.60)),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight ? theme.colorScheme.primary.withValues(alpha: 0.04) : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _rowLabelField({required String label, required Widget field}) {
    final width = MediaQuery.of(context).size.width;
    final labelWidth = width >= 400 ? 120.0 : 110.0;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: field),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GENERAL] build() called');
    debugPrint('[GENERAL] step=hybrid-dec-no-bottom');
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tablet – General (plain app bar)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-contrast debug banner to confirm body renders
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                height: 36,
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.teal,
                child: const Text(
                  'DEBUG: GENERAL CARD ONLY (hybrid) – step A',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              _section('General', [
                _rowLabelField(
                  label: 'Name *',
                  field: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Name *', hint: 'e.g., Panadol', helper: 'Enter the medication name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _rowLabelField(
                  label: 'Manufacturer',
                  field: TextFormField(
                    controller: _manufacturerCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Manufacturer', hint: 'e.g., GlaxoSmithKline', helper: 'Enter the brand or company name'),
                  ),
                ),
                _rowLabelField(
                  label: 'Description',
                  field: TextFormField(
                    controller: _descriptionCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Description', hint: 'e.g., Pain relief', helper: 'What is this medication used for?'),
                  ),
                ),
                _rowLabelField(
                  label: 'Notes',
                  field: TextFormField(
                    controller: _notesCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Notes', hint: 'e.g., Take with food', helper: 'Additional notes or instructions'),
                  ),
                ),
              ]),

              const SizedBox(height: 10),
              _section('Strength', [
                _rowLabelField(
                  label: 'Amount *',
                  field: Row(
                    children: [
                      _incBtn('−', () {
                        final d = double.tryParse(_strengthValueCtrl.text.trim());
                        final base = d?.floor() ?? 0;
                        final nv = (base - 1).clamp(0, 1000000000);
                        setState(() => _strengthValueCtrl.text = nv.toString());
                      }),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _strengthValueCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'))],
                          decoration: _dec(label: 'Amount *', hint: '0'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _incBtn('+', () {
                        final d = double.tryParse(_strengthValueCtrl.text.trim());
                        final base = d?.floor() ?? 0;
                        final nv = (base + 1).clamp(0, 1000000000);
                        setState(() => _strengthValueCtrl.text = nv.toString());
                      }),
                    ],
                  ),
                ),
                _rowLabelField(
                  label: 'Unit *',
                  field: DropdownButtonFormField<Unit>(
                    value: _strengthUnit,
                    isExpanded: true,
                    items: const [Unit.mcg, Unit.mg, Unit.g]
                        .map((u) => DropdownMenuItem(value: u, child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))))
                        .toList(),
                    onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
                    decoration: _dec(label: 'Unit *'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      // No bottom nav here for this step
    );
  }

  Widget _incBtn(String symbol, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      width: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, minimumSize: const Size(30, 30)),
        onPressed: onTap,
        child: Text(symbol),
      ),
    );
  }
}
