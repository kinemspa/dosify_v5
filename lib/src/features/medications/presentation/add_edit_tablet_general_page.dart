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
  // Strength fields (current section)
  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;
  // Inventory fields (next section)
  final _stockCtrl = TextEditingController();
  bool _lowStockAlert = false;
  final _lowStockThresholdCtrl = TextEditingController();
  DateTime? _expiryDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockThresholdCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      // No floating label; we render labels in the left column
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintText: hint,
      helperText: helper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minHeight: 40),
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant),
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
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Name *', hint: 'e.g., AcmeTab-500'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _rowLabelField(
                  label: 'Manufacturer',
                  field: TextFormField(
                    controller: _manufacturerCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Manufacturer', hint: 'e.g., Contoso Pharma'),
                  ),
                ),
                _rowLabelField(
                  label: 'Description',
                  field: TextFormField(
                    controller: _descriptionCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Description', hint: 'e.g., Pain relief'),
                  ),
                ),
                _rowLabelField(
                  label: 'Notes',
                  field: TextFormField(
                    controller: _notesCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Notes', hint: 'e.g., Take with food'),
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
                          textAlign: TextAlign.left,
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
                  field: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: SizedBox(
                      height: 40,
                      width: 120,
                      child: DropdownButtonFormField<Unit>(
                        value: _strengthUnit,
                        isExpanded: false,
                        items: const [Unit.mcg, Unit.mg, Unit.g]
                            .map((u) => DropdownMenuItem(value: u, child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))))
                            .toList(),
                        onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
                        decoration: _dec(label: 'Unit *'),
                      ),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 10),
              _section('Inventory', [
                _rowLabelField(
                  label: 'Stock',
                  field: Row(
                    children: [
                      _incBtn('−', () {
                        final d = double.tryParse(_stockCtrl.text.trim());
                        final base = (d ?? 0).toStringAsFixed(2);
                        final current = double.tryParse(base) ?? 0;
                        final nv = (current - 0.25).clamp(0, 1000000000).toStringAsFixed(2);
                        setState(() => _stockCtrl.text = nv);
                      }),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _stockCtrl,
                          textAlign: TextAlign.left,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'))],
                          decoration: _dec(label: 'Stock', hint: '0.00'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final d = double.tryParse(v);
                            if (d == null) return 'Invalid number';
                            final cents = (d * 100).round();
                            if (cents % 25 != 0) return 'Use .00, .25, .50, or .75';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      _incBtn('+', () {
                        final d = double.tryParse(_stockCtrl.text.trim());
                        final base = (d ?? 0).toStringAsFixed(2);
                        final current = double.tryParse(base) ?? 0;
                        final nv = (current + 0.25).clamp(0, 1000000000).toStringAsFixed(2);
                        setState(() => _stockCtrl.text = nv);
                      }),
                    ],
                  ),
                ),
                _rowLabelField(
                  label: 'Unit',
                  field: Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: SizedBox(
                      height: 40,
                      width: 120,
                      child: DropdownButtonFormField<String>(
                        value: 'tablets',
                        isExpanded: false,
                        items: const [DropdownMenuItem(value: 'tablets', child: Text('tablets'))],
                        onChanged: null, // locked
                        decoration: _dec(label: 'Unit'),
                      ),
                    ),
                  ),
                ),
              ]),

              // Expiry picker
              const SizedBox(height: 10),
              _section('Expiry', [
                _rowLabelField(
                  label: 'Expiry date',
                  field: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 10),
                          initialDate: _expiryDate ?? now,
                        );
                        if (picked != null) setState(() => _expiryDate = picked);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_expiryDate == null ? 'Select date' : _fmtDate(_expiryDate!)),
                    ),
                  ),
                ),
                if (_lowStockAlert) _rowLabelField(
                  label: 'Threshold',
                  field: SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _lowStockThresholdCtrl,
                      textAlign: TextAlign.left,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec(label: 'Threshold', hint: '0'),
                    ),
                  ),
                ),
                _rowLabelField(
                  label: 'Low stock alert',
                  field: Row(
                    children: [
                      Checkbox(
                        value: _lowStockAlert,
                        onChanged: (v) => setState(() => _lowStockAlert = v ?? false),
                      ),
                      const Text('Enable'),
                    ],
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: FilledButton(
              onPressed: () async {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                await _showConfirmDialog();
              },
              child: const Text('Save'),
            ),
          ),
        ),
      ),
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
  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _showConfirmDialog() async {
    final summary = _buildSummary();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Save'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('[SAVE] Confirmed: ' + summary.replaceAll('\n', ' | '));
              // TODO: Wire up persistence in a subsequent step
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _buildSummary() {
    return [
      'Name: ' + (_nameCtrl.text.trim().isEmpty ? '(empty)' : _nameCtrl.text.trim()),
      'Manufacturer: ' + (_manufacturerCtrl.text.trim().isEmpty ? '(empty)' : _manufacturerCtrl.text.trim()),
      'Description: ' + (_descriptionCtrl.text.trim().isEmpty ? '(empty)' : _descriptionCtrl.text.trim()),
      'Notes: ' + (_notesCtrl.text.trim().isEmpty ? '(empty)' : _notesCtrl.text.trim()),
      'Strength: ' + (_strengthValueCtrl.text.trim().isEmpty ? '(empty)' : _strengthValueCtrl.text.trim()) + ' ' + (_strengthUnit == Unit.mcg ? 'mcg' : _strengthUnit == Unit.mg ? 'mg' : 'g'),
      'Stock: ' + (_stockCtrl.text.trim().isEmpty ? '(empty)' : _stockCtrl.text.trim()) + ' tablets',
      'Low stock alert: ' + (_lowStockAlert ? 'ON' : 'OFF'),
      if (_lowStockAlert) 'Threshold: ' + (_lowStockThresholdCtrl.text.trim().isEmpty ? '(empty)' : _lowStockThresholdCtrl.text.trim()),
      'Expiry: ' + (_expiryDate == null ? '(none)' : _fmtDate(_expiryDate!)),
    ].join('\n');
  }
}
