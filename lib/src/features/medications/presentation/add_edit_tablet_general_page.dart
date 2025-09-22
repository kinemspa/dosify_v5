import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/data/medication_repository.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

/// Minimal Tablet editor that renders ONLY the General section.
/// This is used to isolate rendering issues step-by-step.
class AddEditTabletGeneralPage extends StatefulWidget {
  const AddEditTabletGeneralPage({super.key, this.initial});

  final Medication? initial;

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
  // Storage fields
  final _storageLocationCtrl = TextEditingController();
  final _storeBelowCtrl = TextEditingController();
  final _batchNumberCtrl = TextEditingController();
  final _storageInstructionsCtrl = TextEditingController();
  bool _keepRefrigerated = false;
  bool _lightSensitive = false;

  // Live validation state
  String? _stockError;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _nameCtrl.text = m.name;
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _descriptionCtrl.text = m.description ?? '';
      _notesCtrl.text = m.notes ?? '';
      _strengthValueCtrl.text = (m.strengthValue == m.strengthValue.roundToDouble())
          ? m.strengthValue.toStringAsFixed(0)
          : m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _stockCtrl.text = (m.stockValue == m.stockValue.roundToDouble())
          ? m.stockValue.toStringAsFixed(0)
          : m.stockValue.toStringAsFixed(2);
      _lowStockAlert = m.lowStockEnabled;
      _lowStockThresholdCtrl.text = m.lowStockThreshold?.toString() ?? '';
      _expiryDate = m.expiry;
      _batchNumberCtrl.text = m.batchNumber ?? '';
      _storageLocationCtrl.text = m.storageLocation ?? '';
      _keepRefrigerated = m.requiresRefrigeration;
      _lightSensitive = (m.storageInstructions?.toLowerCase().contains('light') ?? false);
      _storageInstructionsCtrl.text = m.storageInstructions ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockThresholdCtrl.dispose();
    _storageLocationCtrl.dispose();
    _storeBelowCtrl.dispose();
    _batchNumberCtrl.dispose();
    _storageInstructionsCtrl.dispose();
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
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant),
      helperStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.60)),
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

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Card(
      elevation: 0,
color: isLight ? theme.colorScheme.primary.withOpacity(0.04) : theme.colorScheme.surfaceContainerHigh,
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
              padding: const EdgeInsets.only(left: 2, bottom: 4, right: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (trailing != null) DefaultTextStyle(
                    style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.primary.withOpacity(0.50), fontWeight: FontWeight.w600),
                    child: trailing,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _decDrop({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintText: hint,
      helperText: helper,
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant),
      helperStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.60)),
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
      labelText: label,
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
height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
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

  Widget _intStepper({
    required TextEditingController controller,
    int step = 1,
    int min = 0,
    int max = 1000000,
    int width = 80,
    String? label,
    String? hint,
    String? helper,
  }) {
return SizedBox(
      height: 36,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          _incBtn('−', () {
            final v = int.tryParse(controller.text.trim()) ?? 0;
            final nv = (v - step).clamp(min, max);
            setState(() => controller.text = nv.toString());
          }),
          const SizedBox(width: 6),
          SizedBox(
            width: width.toDouble(),
            child: SizedBox(
              height: kFieldHeight,
              child: TextFormField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec(label: label ?? '', hint: hint, helper: helper),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _incBtn('+', () {
            final v = int.tryParse(controller.text.trim()) ?? 0;
            final nv = (v + step).clamp(min, max);
            setState(() => controller.text = nv.toString());
          }),
        ],
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[GENERAL] build() called');
    debugPrint('[GENERAL] step=hybrid-dec-no-bottom');
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: GradientAppBar(title: widget.initial == null ? 'Add Tablet' : 'Edit Tablet'),
        body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('General', [
                _rowLabelField(
                  label: 'Name *',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                    controller: _nameCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Name *', hint: 'eg. AcmeTab-500', helper: 'Enter the medication name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  )),
                ),
                _rowLabelField(
                  label: 'Manufacturer',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                    controller: _manufacturerCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Manufacturer', hint: 'eg. Contoso Pharma', helper: 'Enter the brand or company name'),
                    onChanged: (_) => setState(() {}),
                  )),
                ),
                _rowLabelField(
                  label: 'Description',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                    controller: _descriptionCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(label: 'Description', hint: 'eg. Pain relief', helper: 'Optional short description'),
                    onChanged: (_) => setState(() {}),
                  )),
                ),
                _rowLabelField(
                  label: 'Notes',
                  field: TextFormField(
                    controller: _notesCtrl,
                    textAlign: TextAlign.left,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    minLines: 2,
                    maxLines: null,
                    decoration: _dec(label: 'Notes', hint: 'eg. Take with food', helper: 'Optional notes'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ], trailing: _generalSummary()),
              const SizedBox(height: 10),
              _section('Strength', [
                _rowLabelField(
                  label: 'Strength amount (per tablet) *',
                  field: SizedBox(
height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Required';
                            final d = double.tryParse(t);
                            if (d == null) return 'Invalid number';
                            if (d <= 0) return 'Must be > 0';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
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
                ),
                _rowLabelField(
                  label: 'Strength unit *',
                  field: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: kFieldHeight,
                        width: 120,
                        child: DropdownButtonFormField<Unit>(
                          value: _strengthUnit,
                          isExpanded: false,
                          alignment: AlignmentDirectional.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          menuMaxHeight: 320,
                          selectedItemBuilder: (ctx) => const [Unit.mcg, Unit.mg, Unit.g]
                              .map((u) => Center(child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))))
                              .toList(),
                          items: const [Unit.mcg, Unit.mg, Unit.g]
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    alignment: AlignmentDirectional.center,
                                    child: Center(child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))),
                                  ))
                              .toList(),
                          onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
                          decoration: _decDrop(label: '', hint: null, helper: 'mcg / mg / g'),
                        ),
                      ),
                    ],
                  ),
                ),
              ], trailing: _strengthSummary()),

              const SizedBox(height: 10),
              _section('Inventory', [
                _rowLabelField(
                  label: 'Stock amount *',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^$|^\\d{0,7}(?:\\.\\d{0,2})?$'))],
                          decoration: _dec(label: 'Stock amount *', hint: '0.00', helper: 'Quarter steps: .00 / .25 / .50 / .75'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final d = double.tryParse(v);
                            if (d == null) return 'Invalid number';
                            if (d < 0) return 'Must be ≥ 0';
                            final cents = (d * 100).round();
                            if (cents % 25 != 0) return 'Use .00, .25, .50, or .75';
                            return null;
                          },
                          onChanged: (v) {
                            final d = double.tryParse(v);
                            setState(() {
                              if (d == null || ((d * 100).round() % 25 == 0)) {
                                _stockError = null;
                              } else {
                                _stockError = 'Use .00, .25, .50, or .75';
                              }
                            });
                          },
                        ),
                      ),
                      if (_stockError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 36 + 120 + 6 + 30 + 6, top: 4),
                          child: Text(_stockError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
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
                ),
                _rowLabelField(
                  label: 'Stock unit',
                  field: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: kFieldHeight,
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          value: 'tablets',
                          isExpanded: false,
                          alignment: AlignmentDirectional.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          menuMaxHeight: 320,
                          selectedItemBuilder: (ctx) => const ['tablets']
                              .map((t) => Center(child: Text(t)))
                              .toList(),
                          items: const [DropdownMenuItem(value: 'tablets', child: Center(child: Text('tablets')))],
                          onChanged: null, // locked
                          decoration: _decDrop(label: '', hint: null, helper: 'Locked to tablets'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Low stock alert toggle + threshold
                _rowLabelField(
                  label: 'Low stock alert',
field: Row(
                    children: [
                      Checkbox(
                        value: _lowStockAlert,
                        onChanged: (v) => setState(() => _lowStockAlert = v ?? false),
                      ),
                      Text('Enable alert when stock is low', style: kMutedLabelStyle(context)),
                    ],
                  ),
                ),
                if (_lowStockAlert)
                  _rowLabelField(
                    label: 'Threshold',
                    field: _intStepper(
                      controller: _lowStockThresholdCtrl,
                      step: 1,
                      min: 0,
                      max: 100000,
                      width: 80,
                      label: 'Threshold',
                      hint: '0',
                      helper: 'Required when enabled',
                    ),
                  ),
                _rowLabelField(
                  label: 'Expiry date',
                  field: SizedBox(
                    height: kFieldHeight,
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
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, kFieldHeight)),
                    ),
                  ),
                ),
              ], trailing: _inventorySummary()),

              // Storage
              const SizedBox(height: 10),
              _section('Storage', [
                _rowLabelField(
                  label: 'Batch No.',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                      controller: _batchNumberCtrl,
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(label: 'Batch No.', hint: 'Enter batch number', helper: 'Optional'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                _rowLabelField(
                  label: 'Location',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                      controller: _storageLocationCtrl,
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(label: 'Location', hint: 'eg. Bathroom cabinet', helper: 'Optional'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                _rowLabelField(
                  label: 'Store below (°C)',
                  field: _intStepper(
                    controller: _storeBelowCtrl,
                    step: 1,
                    min: 0,
                    max: 1000,
                    width: 80,
                    label: 'Store below (°C)',
                    hint: '25',
                    helper: 'Optional',
                  ),
                ),
                _rowLabelField(
                  label: 'Cold storage',
                  field: Row(
                    children: [
                      Checkbox(
                        value: _keepRefrigerated,
                        onChanged: (v) => setState(() => _keepRefrigerated = v ?? false),
                      ),
                      Text('Keep refrigerated', style: kMutedLabelStyle(context)),
                    ],
                  ),
                ),
                _rowLabelField(
                  label: 'Light sensitive',
                  field: Row(
                    children: [
                      Checkbox(
                        value: _lightSensitive,
                        onChanged: (v) => setState(() => _lightSensitive = v ?? false),
                      ),
                      Text('Protect from light', style: kMutedLabelStyle(context)),
                    ],
                  ),
                ),
                _rowLabelField(
                  label: 'Storage instructions',
                  field: SizedBox(
                    height: kFieldHeight,
                    child: TextFormField(
                      controller: _storageInstructionsCtrl,
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(label: 'Storage instructions', hint: 'Enter storage instructions', helper: 'Optional'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ], trailing: _storageSummary()),

            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Center(
              child: SizedBox(
                width: 220,
child: FilledButton(
style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                  onPressed: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    await _showConfirmDialog();
                  },
                  child: const Text('Save'),
                ),
              ),
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
  Widget _generalSummary() {
    final name = _nameCtrl.text.trim();
    final mfr = _manufacturerCtrl.text.trim();
    if (name.isEmpty && mfr.isEmpty) return const SizedBox.shrink();
    final s = name.isEmpty ? mfr : (mfr.isEmpty ? name : '$name – $mfr');
    return Text(s, overflow: TextOverflow.ellipsis);
  }

  Widget _strengthSummary() {
    final v = _strengthValueCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (v.isEmpty) return const SizedBox.shrink();
    final unit = _strengthUnit == Unit.mcg ? 'mcg' : _strengthUnit == Unit.mg ? 'mg' : 'g';
    final med = name.isEmpty ? '' : ' per $name tablet';
    return Text('$v$unit$med');
  }

  Widget _inventorySummary() {
    final v = _stockCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (v.isEmpty) return const SizedBox.shrink();
    final med = name.isEmpty ? '' : ' $name Tablets';
    return Text('$v$med');
  }

  Widget _storageSummary() {
    final parts = <String>[];
    if (_keepRefrigerated) parts.add('Fridge');
    if (_storageLocationCtrl.text.trim().isNotEmpty) parts.add(_storageLocationCtrl.text.trim());
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join(' · '));
  }

  Widget _expirySummary() {
    if (_expiryDate == null) return const SizedBox.shrink();
    return Text(_fmtDate(_expiryDate!));
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _showConfirmDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirm medication', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(child: _buildConfirmContent(ctx)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _persistMedication();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistMedication() async {
    try {
      final box = Hive.box<Medication>('medications');
      final repo = MedicationRepository(box);
      final id = widget.initial?.id ?? _newId();
      final strength = double.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
      final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0;
      final lowThresh = double.tryParse(_lowStockThresholdCtrl.text.trim());
      final med = Medication(
        id: id,
        form: MedicationForm.tablet,
        name: _nameCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        strengthValue: strength,
        strengthUnit: _strengthUnit,
        stockValue: stock,
        stockUnit: StockUnit.tablets,
        lowStockEnabled: _lowStockAlert,
        lowStockThreshold: _lowStockAlert ? lowThresh : null,
        expiry: _expiryDate,
        batchNumber: _batchNumberCtrl.text.trim().isEmpty ? null : _batchNumberCtrl.text.trim(),
        storageLocation: _storageLocationCtrl.text.trim().isEmpty ? null : _storageLocationCtrl.text.trim(),
        requiresRefrigeration: _keepRefrigerated,
        storageInstructions: _storageInstructionsCtrl.text.trim().isNotEmpty
            ? _storageInstructionsCtrl.text.trim()
            : (_lightSensitive ? 'Protect from light' : null),
      );
      await repo.upsert(med);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medication saved')));
        Navigator.of(context).maybePop();
      }
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  String _newId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'med_$ms';
  }

  Widget _buildConfirmContent(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    Widget row(String l, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(l, style: labelStyle)),
          const SizedBox(width: 8),
          Expanded(child: Text(v.isEmpty ? '-' : v, style: valueStyle)),
        ],
      ),
    );
    final strengthText = _strengthSummary() is SizedBox ? '' : (_strengthValueCtrl.text.trim().isEmpty ? '' : '${_strengthValueCtrl.text.trim()} ${_strengthUnit == Unit.mcg ? 'mcg' : _strengthUnit == Unit.mg ? 'mg' : 'g'} ${_nameCtrl.text.trim().isEmpty ? '' : _nameCtrl.text.trim() + ' Tablets'}');
    final inventoryText = _inventorySummary() is SizedBox ? '' : (_stockCtrl.text.trim().isEmpty ? '' : '${_stockCtrl.text.trim()} ${_nameCtrl.text.trim().isEmpty ? '' : _nameCtrl.text.trim() + ' Tablets'}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Name', _nameCtrl.text.trim()),
        row('Manufacturer', _manufacturerCtrl.text.trim()),
        row('Strength', strengthText),
        row('Stock', inventoryText.isEmpty ? (_stockCtrl.text.trim().isEmpty ? '' : _stockCtrl.text.trim() + ' tablets') : inventoryText),
        row('Low stock alerts', _lowStockAlert ? 'On at ${_lowStockThresholdCtrl.text.trim()}' : 'Off'),
        row('Expiry', _expiryDate == null ? '' : _fmtDate(_expiryDate!)),
        row('Batch', _batchNumberCtrl.text.trim()),
        row('Storage location', _storageLocationCtrl.text.trim()),
        row('Requires refrigeration', _keepRefrigerated ? 'Yes' : 'No'),
        row('Storage instructions', _storageInstructionsCtrl.text.trim()),
      ],
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
'Batch: ' + (_batchNumberCtrl.text.trim().isEmpty ? '(empty)' : _batchNumberCtrl.text.trim()),
      'Storage location: ' + (_storageLocationCtrl.text.trim().isEmpty ? '(empty)' : _storageLocationCtrl.text.trim()),
      'Store below: ' + (_storeBelowCtrl.text.trim().isEmpty ? '(empty)' : (_storeBelowCtrl.text.trim() + ' °C')),
      'Cold storage: ' + (_keepRefrigerated ? 'Yes' : 'No'),
      'Light sensitive: ' + (_lightSensitive ? 'Yes' : 'No'),
      'Storage instructions: ' + (_storageInstructionsCtrl.text.trim().isEmpty ? '(empty)' : _storageInstructionsCtrl.text.trim()),
      'Expiry: ' + (_expiryDate == null ? '(none)' : _fmtDate(_expiryDate!)),
    ].join('\n');
  }
}
