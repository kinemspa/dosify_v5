import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

class AddTabletDebugPage extends StatefulWidget {
  AddTabletDebugPage({super.key});

  @override
  State<AddTabletDebugPage> createState() => _AddTabletDebugPageState();
}

class _AddTabletDebugPageState extends State<AddTabletDebugPage> {
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
  String? _stockError;
  DateTime? _expiry;
  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();
  // Storage
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();

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
    _storageNotesCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({String? hint}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      hintText: hint,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      constraints: const BoxConstraints(minHeight: 40),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: cs.onSurfaceVariant,
      ),
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

  Widget _rowLabelField({required String label, required Widget field}) {
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

  Widget _section(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight
          ? theme.colorScheme.primary.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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

  Widget _incBtn(String symbol, VoidCallback onTap) {
    return SizedBox(
      height: 30,
      width: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(30, 30),
        ),
        onPressed: onTap,
        child: Text(symbol),
      ),
    );
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

  bool _isQuarter(double v) {
    final x = (v * 4).roundToDouble() / 4.0;
    return (v - x).abs() < 0.000001;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[DEBUG TABLET] build() called');
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'DEBUG TABLET PAGE – FORM v2',
        forceBackButton: true,
      ),
      body: SingleChildScrollView(
        // Visible banner at very top to confirm new body
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 36,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.green,
                child: const Text(
                  'DEBUG: MINIMAL FORM BODY RENDERED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _section('General', [
                _rowLabelField(
                  label: 'Name *',
                  field: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(hint: 'e.g., Panadol'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                _rowLabelField(
                  label: 'Manufacturer',
                  field: TextFormField(
                    controller: _manufacturerCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(hint: 'e.g., GSK'),
                  ),
                ),
                _rowLabelField(
                  label: 'Description',
                  field: TextFormField(
                    controller: _descriptionCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _dec(hint: 'e.g., Pain relief'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _section('Strength', [
                _rowLabelField(
                  label: 'Amount *',
                  field: Row(
                    children: [
                      _incBtn('−', () {
                        final d = double.tryParse(
                          _strengthValueCtrl.text.trim(),
                        );
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
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                            ),
                          ],
                          decoration: _dec(hint: '0'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _incBtn('+', () {
                        final d = double.tryParse(
                          _strengthValueCtrl.text.trim(),
                        );
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
                    height: 40,
                    child: DropdownButtonFormField<Unit>(
                      value: _strengthUnit,
                      isExpanded: false,
                      alignment: AlignmentDirectional.center,
                      menuMaxHeight: 320,
                      selectedItemBuilder: (ctx) =>
                          const [Unit.mcg, Unit.mg, Unit.g]
                              .map(
                                (u) => Center(
                                  child: Text(
                                    u == Unit.mcg
                                        ? 'mcg'
                                        : (u == Unit.mg ? 'mg' : 'g'),
                                  ),
                                ),
                              )
                              .toList(),
                      items: const [Unit.mcg, Unit.mg, Unit.g]
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              alignment: AlignmentDirectional.center,
                              child: Center(
                                child: Text(
                                  u == Unit.mcg
                                      ? 'mcg'
                                      : (u == Unit.mg ? 'mg' : 'g'),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (u) =>
                          setState(() => _strengthUnit = u ?? _strengthUnit),
                      decoration: _dec(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _section('Inventory', [
                _rowLabelField(
                  label: 'Stock *',
                  field: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _incBtn('−', () {
                            final v =
                                double.tryParse(_stockValueCtrl.text) ?? 0;
                            final nv = (v - 0.25).clamp(0, 1000000);
                            setState(
                              () =>
                                  _stockValueCtrl.text = nv.toStringAsFixed(2),
                            );
                          }),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: _stockValueCtrl,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                                ),
                              ],
                              decoration: _dec(hint: '0.00'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                              onChanged: (v) {
                                final d = double.tryParse(v);
                                setState(
                                  () =>
                                      _stockError = (d == null || _isQuarter(d))
                                      ? null
                                      : 'Stock should be .00, .25, .50 or .75',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          _incBtn('+', () {
                            final v =
                                double.tryParse(_stockValueCtrl.text) ?? 0;
                            final nv = (v + 0.25).clamp(0, 1000000);
                            setState(
                              () =>
                                  _stockValueCtrl.text = nv.toStringAsFixed(2),
                            );
                          }),
                        ],
                      ),
                      if (_stockError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _stockError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _rowLabelField(
                  label: 'Unit *',
                  field: DropdownButtonFormField<StockUnit>(
                    value: StockUnit.tablets,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: StockUnit.tablets,
                        child: Text('tablets'),
                      ),
                    ],
                    onChanged: null,
                    decoration: _dec(),
                  ),
                ),
                _rowLabelField(
                  label: 'Expiry',
                  field: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _pickExpiry,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        _expiry == null
                            ? 'Pick expiry date'
                            : DateFormat.yMd().format(_expiry!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 40),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _section('Storage Information', [
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
                    decoration: _dec(hint: 'Enter storage location'),
                  ),
                ),
                CheckboxListTile(
                  title: const Text('Requires Refrigeration'),
                  subtitle: const Text('Must be stored in refrigerator'),
                  value: _requiresFridge,
                  onChanged: (v) =>
                      setState(() => _requiresFridge = v ?? false),
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
                onPressed: _nameCtrl.text.trim().isNotEmpty
                    ? () async {
                        if (!_formKey.currentState!.validate()) return;
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Debug Save'),
                            content: const Text(
                              'UI renders correctly. We will wire persistence next.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
