import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

class AddEditTabletHybridPage extends StatefulWidget {
  const AddEditTabletHybridPage({super.key, this.initial});
  final Medication? initial;

  @override
  State<AddEditTabletHybridPage> createState() => _AddEditTabletHybridPageState();
}

class _AddEditTabletHybridPageState extends State<AddEditTabletHybridPage> {
  final _formKey = GlobalKey<FormState>();

  // Identity
  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Strength
  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;

  // Inventory
  final _stockValueCtrl = TextEditingController();
  StockUnit _stockUnit = StockUnit.tablets;
  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();

  // Storage
  DateTime? _expiry;
  final _expiryNotifyCtrl = TextEditingController(text: '14');
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();

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
      _stockValueCtrl.text = (m.stockValue == m.stockValue.roundToDouble())
          ? m.stockValue.toStringAsFixed(0)
          : m.stockValue.toString();
      _stockUnit = m.stockUnit;
      _lowStockEnabled = m.lowStockEnabled;
      _lowStockCtrl.text = m.lowStockThreshold?.toString() ?? '';
      _expiry = m.expiry;
      _batchCtrl.text = m.batchNumber ?? '';
      _storageCtrl.text = m.storageLocation ?? '';
      _requiresFridge = m.requiresRefrigeration;
      _storageNotesCtrl.text = m.storageInstructions ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _stockValueCtrl.dispose();
    _lowStockCtrl.dispose();
      _batchCtrl.dispose();
      _storageCtrl.dispose();
      _expiryNotifyCtrl.dispose();
      _storageNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: _expiry ?? now,
      helpText: 'Expiry',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  String _unitLabel(Unit u) => switch (u) {
        Unit.mcg => 'mcg',
        Unit.mg => 'mg',
        Unit.g => 'g',
        _ => u.name,
      };

  String _unitFull(Unit u) => switch (u) {
        Unit.mcg => 'micrograms',
        Unit.mg => 'milligrams',
        Unit.g => 'grams',
        _ => u.name,
      };

  String _stockUnitLabel(StockUnit s) => switch (s) {
        StockUnit.tablets => 'tablets',
        StockUnit.capsules => 'capsules',
        StockUnit.preFilledSyringes => 'pre filled syringes',
        StockUnit.singleDoseVials => 'single dose vials',
        StockUnit.multiDoseVials => 'multi dose vials',
        StockUnit.mcg => 'mcg',
        StockUnit.mg => 'mg',
        StockUnit.g => 'g',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sv = double.tryParse(_strengthValueCtrl.text.trim());
    final stockVal = double.tryParse(_stockValueCtrl.text.trim());
    final roundedStock = stockVal == null ? null : (stockVal * 4).round() / 4.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Confirm medication', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow(ctx, 'Name', _nameCtrl.text.trim()),
              _confirmRow(ctx, 'Manufacturer', _manufacturerCtrl.text.trim()),
              _confirmRow(ctx, 'Strength', sv == null ? '-' : '${sv.toStringAsFixed(2)} ${_unitLabel(_strengthUnit)} per tablet'),
              _confirmRow(ctx, 'Stock', roundedStock == null ? '-' : _formatQuarter(roundedStock) + ' tablets'),
              _confirmRow(ctx, 'Low stock alerts', _lowStockEnabled ? 'On at ${_lowStockCtrl.text.trim()}' : 'Off'),
              _confirmRow(ctx, 'Expiry', _expiry != null ? DateFormat('dd/MM/yy').format(_expiry!) : '-'),
              _confirmRow(ctx, 'Batch', _batchCtrl.text.trim()),
              _confirmRow(ctx, 'Storage location', _storageCtrl.text.trim()),
              _confirmRow(ctx, 'Requires refrigeration', _requiresFridge ? 'Yes' : 'No'),
              _confirmRow(ctx, 'Storage instructions', _storageNotesCtrl.text.trim()),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final med = Medication(
      id: widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      form: MedicationForm.tablet,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      strengthValue: double.parse(_strengthValueCtrl.text.trim()),
      strengthUnit: _strengthUnit,
      stockValue: (roundedStock ?? 0).toDouble(),
      stockUnit: StockUnit.tablets,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.trim().isNotEmpty
          ? double.tryParse(_lowStockCtrl.text.trim())
          : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageNotesCtrl.text.trim().isEmpty ? null : _storageNotesCtrl.text.trim(),
    );
    final box = Hive.box<Medication>('medications');
    await box.put(med.id, med);
    if (!mounted) return;
    context.go('/medications');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.initial == null ? 'Added "${med.name}"' : 'Updated "${med.name}"')),
    );
  }

  Widget _rowLabelField({
    required String label,
    required Widget field,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
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

InputDecoration _dec({String? hint}) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        // Enforce a full 36 px input decorator height using kFieldHeight
        return InputDecoration(
          hintText: hint,
          isDense: true,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          constraints: const BoxConstraints(minHeight: kFieldHeight),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: kHintFontSize, color: cs.onSurfaceVariant),
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

  Widget _incBtn(String symbol, VoidCallback onTap) {
    final theme = Theme.of(context);
return SizedBox(
      height: kBtnSize,
      width: kBtnSize,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact, minimumSize: const Size(kBtnSize, kBtnSize)),
        onPressed: onTap,
        child: Text(symbol, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HYBRID] build() called, initial=${widget.initial != null}');
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        appBar: GradientAppBar(
          title: widget.initial == null ? 'Add Medication' : 'Edit Medication',
          actions: const [],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DEBUG banner to confirm body is rendering
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                  child: const Text('DEBUG: HYBRID FORM BODY RENDERED', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                // General
                _section(context, 'General', [
                  _rowLabelField(
                    label: 'Name *',
                    field: TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'eg. Panadol'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  _rowLabelField(
                    label: 'Manufacturer',
                    field: TextFormField(
                      controller: _manufacturerCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'eg. GSK'),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Description',
                    field: TextFormField(
                      controller: _descriptionCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'eg. Pain relief'),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Notes',
                    field: TextFormField(
                      controller: _notesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'eg. Take with food'),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // Strength
                _section(context, 'Strength', [
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
                            inputFormatters: const [_TwoDecimalTextInputFormatter()],
                            decoration: _dec(hint: '0'),
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
                    field: SizedBox(
                      width: 120,
                      height: kFieldHeight,
                      child: DropdownButtonFormField<Unit>(
                        value: _strengthUnit,
                        isExpanded: false,
                        alignment: AlignmentDirectional.center,
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
                        decoration: _dec(),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // Inventory
                _section(context, 'Inventory', [
                  _rowLabelField(
                    label: 'Stock *',
                    field: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _incBtn('−', () {
                              final v = double.tryParse(_stockValueCtrl.text) ?? 0;
                              final nv = (v - 0.25).clamp(0, 1000000);
                              setState(() => _stockValueCtrl.text = nv.toStringAsFixed(2));
                            }),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _stockValueCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: const [_TwoDecimalTextInputFormatter()],
                                decoration: _dec(hint: '0.00'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                onChanged: (v) {
                                  final d = double.tryParse(v);
                                  setState(() {
                                    if (d == null || _isQuarter(d)) {
                                      _stockError = null;
                                    } else {
                                      _stockError = 'Stock should be .00, .25, .50 or .75';
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            _incBtn('+', () {
                              final v = double.tryParse(_stockValueCtrl.text) ?? 0;
                              final nv = (v + 0.25).clamp(0, 1000000);
                              setState(() => _stockValueCtrl.text = nv.toStringAsFixed(2));
                            }),
                          ],
                        ),
                        if (_stockError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_stockError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  _rowLabelField(
                    label: 'Unit *',
                    field: SizedBox(
                      height: kFieldHeight,
                      child: DropdownButtonFormField<StockUnit>(
                        value: StockUnit.tablets,
                        isExpanded: true,
                        items: const [DropdownMenuItem(value: StockUnit.tablets, child: Text('tablets'))],
                        onChanged: null,
                        decoration: _dec(),
                      ),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Expiry',
                    field: SizedBox(
                      height: kFieldHeight,
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiry,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(_expiry == null ? 'Pick expiry date' : DateFormat.yMd().format(_expiry!)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, kFieldHeight)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: _lowStockEnabled,
                          onChanged: (v) => setState(() => _lowStockEnabled = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Low stock alerts'),
                          subtitle: const Text('Notify when reaching threshold'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: _lowStockEnabled
                            ? SizedBox(
                                key: const ValueKey('lowStock'),
                                width: 120,
                                child: TextFormField(
                                  controller: _lowStockCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: const [_TwoDecimalTextInputFormatter()],
                                  decoration: _dec(hint: '0'),
                                ),
                              )
                            : const SizedBox(key: ValueKey('lowStockOff'), width: 120),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 12),

                // Storage
                _section(context, 'Storage Information', [
                  _rowLabelField(
                    label: 'Batch No.',
                    field: TextFormField(
                      controller: _batchCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'Enter batch number'),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Lot / Storage Location',
                    field: TextFormField(
                      controller: _storageCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'eg. Bathroom cabinet'),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Requires Refrigeration'),
                    subtitle: const Text('Must be stored in refrigerator'),
                    value: _requiresFridge,
                    onChanged: (v) => setState(() => _requiresFridge = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  _rowLabelField(
                    label: 'Storage Instructions',
                    field: TextFormField(
                      controller: _storageNotesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'Enter storage instructions'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Center(
              child: SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _confirmRow(BuildContext context, String label, String value) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        const SizedBox(width: 8),
        Expanded(child: Text(value.isEmpty ? '-' : value, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}

String _formatQuarter(double v) {
  final rounded = (v * 4).round() / 4.0;
  if ((rounded % 1) == 0) return rounded.toStringAsFixed(0);
  return rounded.toStringAsFixed(2);
}

bool _isQuarter(double v) {
  final x = (v * 4).roundToDouble() / 4.0;
  return (v - x).abs() < 0.000001;
}

class _TwoDecimalTextInputFormatter extends TextInputFormatter {
  const _TwoDecimalTextInputFormatter();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue; // allow deletion to empty
    final reg = RegExp(r'^\d{0,7}(?:\.\d{0,2})?$');
    if (reg.hasMatch(text)) return newValue;
    return oldValue;
  }
}

Widget _section(BuildContext context, String title, List<Widget> children, {Widget? trailing}) {
  final theme = Theme.of(context);
  final isLight = Theme.of(context).brightness == Brightness.light;
  return Card(
    elevation: 0,
    color: isLight ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );
}

class SizeReporter extends StatefulWidget {
  const SizeReporter({super.key, required this.tag, required this.child});
  final String tag;
  final Widget child;
  @override
  State<SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<SizeReporter> {
  final _key = GlobalKey();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rb = _key.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null) {
        debugPrint('[SizeReporter] ${widget.tag}: \\${rb.size.width} x \\${rb.size.height}');
      }
    });
  }
  @override
  Widget build(BuildContext context) => Container(key: _key, child: widget.child);
}
