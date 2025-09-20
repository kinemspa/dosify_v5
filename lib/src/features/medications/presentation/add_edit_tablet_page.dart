import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/strength_input.dart';
import '../../../core/prefs/user_prefs.dart';
import '../../../widgets/form_field_styler.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditTabletPage extends ConsumerStatefulWidget {
  const AddEditTabletPage({super.key, this.initial});
  
  final Medication? initial;

  @override
  ConsumerState<AddEditTabletPage> createState() => _AddEditTabletPageState();
}

class _AddEditTabletPageState extends ConsumerState<AddEditTabletPage> with TickerProviderStateMixin {
  // Dynamically size the gradient header to match summary content
  final GlobalKey _summaryAreaKey = GlobalKey();
  double _headerHeight = kToolbarHeight + 84;

  void _recalcHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _summaryAreaKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final desired = kToolbarHeight + box.size.height;
      if ((_headerHeight - desired).abs() > 1) {
        setState(() => _headerHeight = desired);
      }
    });
  }
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;

  final _stockValueCtrl = TextEditingController();
  StockUnit _stockUnit = StockUnit.tablets;

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();
  String? _stockError;

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();


  int _strengthStyleIndex = 0;
  int _formStyleIndex = 0;

  Future<void> _loadStylePrefs() async {
    final s = await UserPrefs.getStrengthInputStyle();
    final f = await UserPrefs.getFormFieldStyle();
    if (mounted) setState(() { _strengthStyleIndex = s; _formStyleIndex = f; });
  }

  @override
  void initState() {
    super.initState();
    final med = widget.initial;
    if (med != null) {
      _nameCtrl.text = med.name;
      _manufacturerCtrl.text = med.manufacturer ?? '';
      _descriptionCtrl.text = med.description ?? '';
      _notesCtrl.text = med.notes ?? '';
      _strengthValueCtrl.text = med.strengthValue.toString();
      _strengthUnit = med.strengthUnit;
      _stockValueCtrl.text = med.stockValue.toString();
      _stockUnit = med.stockUnit;
      _lowStockEnabled = med.lowStockEnabled;
      _lowStockCtrl.text = med.lowStockThreshold?.toString() ?? '';
      _expiry = med.expiry;
      _batchCtrl.text = med.batchNumber ?? '';
      _storageCtrl.text = med.storageLocation ?? '';
      _requiresFridge = med.requiresRefrigeration;
      _storageNotesCtrl.text = med.storageInstructions ?? '';
    }
    // Load style prefs
    _loadStylePrefs();
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
    _storageNotesCtrl.dispose();
    super.dispose();
  }

  String _buildSummary() {
    final unitLabel = _unitLabel(_strengthUnit);
    final stockLabel = _stockUnitLabel(_stockUnit);
    final parts = <String>['Tablets'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      parts.add('${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unitLabel per tablet');
    }
    if (_stockValueCtrl.text.isNotEmpty) {
      parts.add('${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} $stockLabel in stock');
    }
    if (_manufacturerCtrl.text.isNotEmpty) parts.add(_manufacturerCtrl.text);
    if (_requiresFridge) parts.add('Keep refrigerated');
    if (_expiry != null) {
      parts.add('Expires - ${DateFormat.yMd().format(_expiry!)}');
    }
    if (_notesCtrl.text.isNotEmpty) parts.add(_notesCtrl.text);
    return parts.join('. ');
  }

  Widget _buildStyledSummary() {
    if (_nameCtrl.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Fill in medication details to see summary',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main info row with stock on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and manufacturer
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: _nameCtrl.text,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_manufacturerCtrl.text.isNotEmpty)
                          TextSpan(text: ' from ${_manufacturerCtrl.text}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  // Strength info
                  if (_strengthValueCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)} per tablet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Description
                  if (_descriptionCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'For ${_descriptionCtrl.text.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
            // Right side with stock info and indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_stockValueCtrl.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                // Refrigeration and expiry indicators
                if (_requiresFridge || _expiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_requiresFridge)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.ac_unit,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        if (_expiry != null && _requiresFridge)
                          const SizedBox(height: 2),
                        if (_expiry != null)
                          Text(
                            DateFormat('MMM yy').format(_expiry!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Additional info if present
        if (_notesCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _notesCtrl.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.white60,
              ),
            ),
          ),
        if (_lowStockEnabled && _lowStockCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  'Low stock alert at ${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: _expiry ?? now,
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _unitLabel(Unit u) {
    switch (u) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      default:
        return u.name; // not expected for tablets
    }
  }

  String _stockUnitLabel(StockUnit s) {
    switch (s) {
      case StockUnit.tablets:
        return 'tablets';
      case StockUnit.mcg:
        return 'mcg';
      case StockUnit.mg:
        return 'mg';
      case StockUnit.g:
        return 'g';
      default:
        return s.name;
    }
  }

  bool _isQuarter(double v) {
    final frac = (v * 4).round() / 4.0;
    return (v - frac).abs() < 1e-8;
  }

  bool _isExpiringSoon() {
    if (_expiry == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = _expiry!.difference(now).inDays;
    return daysUntilExpiry <= 30;
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(medicationRepositoryProvider);

    final id = widget.initial?.id ?? (DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0'));

    final med = Medication(
      id: id,
      form: MedicationForm.tablet,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty
          ? null
          : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      strengthValue: double.parse(_strengthValueCtrl.text),
      strengthUnit: _strengthUnit,
      stockValue: double.parse(_stockValueCtrl.text),
      stockUnit: _stockUnit,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty
          ? double.parse(_lowStockCtrl.text)
          : null,
      expiry: _expiry,
      batchNumber:
          _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation:
          _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageNotesCtrl.text.trim().isEmpty
          ? null
          : _storageNotesCtrl.text.trim(),
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Confirm Medication',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled summary preview block
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                _buildSummary(),
                style: const TextStyle(color: Colors.white, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            // Full details list
            _detailRow('Form', 'Tablet'),
            _detailRow('Name', _nameCtrl.text.trim()),
            if (_manufacturerCtrl.text.trim().isNotEmpty) _detailRow('Manufacturer', _manufacturerCtrl.text.trim()),
            _detailRow('Strength', '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)}'),
            _detailRow('Stock', '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}'),
            if (_lowStockEnabled && _lowStockCtrl.text.isNotEmpty) _detailRow('Low stock at', '${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}'),
            _detailRow('Expiry', _expiry != null ? DateTime.now().isAfter(_expiry!) ? 'Expired' : '${_expiry!.day}/${_expiry!.month}/${_expiry!.year}' : 'No expiry'),
            if (_batchCtrl.text.trim().isNotEmpty) _detailRow('Batch #', _batchCtrl.text.trim()),
            if (_storageCtrl.text.trim().isNotEmpty) _detailRow('Storage', _storageCtrl.text.trim()),
            _detailRow('Requires refrigeration', _requiresFridge ? 'Yes' : 'No'),
            if (_storageNotesCtrl.text.trim().isNotEmpty) _detailRow('Storage notes', _storageNotesCtrl.text.trim()),
            if (_descriptionCtrl.text.trim().isNotEmpty) _detailRow('Description', _descriptionCtrl.text.trim()),
            if (_notesCtrl.text.trim().isNotEmpty) _detailRow('Notes', _notesCtrl.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.upsert(med);
      if (!mounted) return;
      context.go('/medications');
    }
  }

  Widget _pillBtn(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          overlayColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.12)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }

  // Hybrid styling helpers (from hybrid page)
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
      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: cs.onSurfaceVariant),
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

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    final theme = Theme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Card(
      elevation: 0,
      color: isLight ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: theme.colorScheme.primary,
                      ),
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

  Widget _incBtn(String symbol, VoidCallback onTap) {
    final theme = Theme.of(context);
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
        child: Text(symbol, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        appBar: GradientAppBar(
          title: widget.initial == null ? 'Add Medication - Tablet' : 'Edit Medication - Tablet',
          forceBackButton: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('General', [
                  _rowLabelField(
                    label: 'Name *',
                    field: TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'e.g., Panadol'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Manufacturer',
                    field: TextFormField(
                      controller: _manufacturerCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'e.g., GSK'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Description',
                    field: TextFormField(
                      controller: _descriptionCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'e.g., Pain relief'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Notes',
                    field: TextFormField(
                      controller: _notesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'e.g., Take with food'),
                      onChanged: (_) => setState(() {}),
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
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$')),
                            ],
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
                    field: DropdownButtonFormField<Unit>(
                      value: _strengthUnit,
                      isExpanded: true,
                      items: const [Unit.mcg, Unit.mg, Unit.g]
                          .map((u) => DropdownMenuItem(value: u, child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))))
                          .toList(),
                      onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
                      decoration: _dec(),
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$')),
                                ],
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
                    field: DropdownButtonFormField<StockUnit>(
                      value: StockUnit.tablets,
                      isExpanded: true,
                      items: const [DropdownMenuItem(value: StockUnit.tablets, child: Text('tablets'))],
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
                        label: Text(_expiry == null ? 'Pick expiry date' : DateFormat.yMd().format(_expiry!)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 40), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
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
                                  decoration: _dec(hint: '0'),
                                ),
                              )
                            : const SizedBox(key: ValueKey('lowStockOff'), width: 120),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 12),

                _section('Storage Information', [
                  _rowLabelField(
                    label: 'Batch No.',
                    field: TextFormField(
                      controller: _batchCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'Enter the Medication Batch Number'),
                    ),
                  ),
                  _rowLabelField(
                    label: 'Lot / Storage Location',
                    field: TextFormField(
                      controller: _storageCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(hint: 'Enter the Storage Location'),
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
                  onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
                  icon: const Icon(Icons.save),
                  label: Text(widget.initial == null ? 'Save' : 'Update'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 24)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

