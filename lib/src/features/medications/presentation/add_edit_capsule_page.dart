import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';

class AddEditCapsulePage extends ConsumerStatefulWidget {
  const AddEditCapsulePage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddEditCapsulePage> createState() => _AddEditCapsulePageState();
}

class _AddEditCapsulePageState extends ConsumerState<AddEditCapsulePage> {
  // Dynamic floating summary spacer
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 0;
  final ScrollController _scrollCtrl = ScrollController();
  // Gating for helper-row validation (hide red until interaction)
  bool _submitted = false;
  bool _touchedName = false;
  bool _touchedStrengthAmt = false;
  bool _touchedStock = false;
  bool _touchedThreshold = false;
  double _labelWidth() {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 ? 120.0 : 110.0;
  }

  Widget _helperBelowLeft(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: _labelWidth() + 8, top: 4, bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: kHintFontSize,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _helperBelowCenter(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _helperBelowLeftCompact(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: _labelWidth() + 8, top: 2, bottom: 6),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;

  final _stockValueCtrl = TextEditingController();
  StockUnit _stockUnit = StockUnit.capsules;

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  bool _keepFrozen = false;
  bool _lightSensitive = false;
  final _storageNotesCtrl = TextEditingController();

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
      final si = med.storageInstructions ?? '';
      _lightSensitive = si.toLowerCase().contains('light');
      _keepFrozen = si.toLowerCase().contains('frozen');
      _storageNotesCtrl.text = si;
    }
    // Defaults for integer fields when adding new entries
    if (_strengthValueCtrl.text.isEmpty) _strengthValueCtrl.text = '0';
    if (_stockValueCtrl.text.isEmpty) _stockValueCtrl.text = '0';
    if (_lowStockCtrl.text.isEmpty) _lowStockCtrl.text = '0';
  }

  void _updateSummaryHeight() {
    final ctx = _summaryKey.currentContext;
    if (ctx != null) {
      final rb = ctx.findRenderObject();
      if (rb is RenderBox) {
        final h = rb.size.height;
        if (h != _summaryHeight && h > 0) setState(() => _summaryHeight = h);
      }
    }
  }

  SummaryHeaderCard _floatingSummaryCard() {
    final name = _nameCtrl.text.trim();
    final manufacturer = _manufacturerCtrl.text.trim();
    final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
    final stockVal = double.tryParse(_stockValueCtrl.text.trim());
    final initialStock = widget.initial?.initialStockValue ?? stockVal ?? 0;
    String unitLabel = _unitLabel(_strengthUnit);
    final threshold = double.tryParse(_lowStockCtrl.text.trim());
    final headerTitle = name.isEmpty ? 'Capsules' : name;

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: unitLabel,
      stockCurrent: stockVal ?? 0,
      stockInitial: initialStock,
      stockUnitLabel: 'capsules',
      expiryDate: _expiry,
      showRefrigerate: _requiresFridge,
      showFrozen: _keepFrozen,
      showDark: _lightSensitive,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: threshold,
      includeNameInStrengthLine: false,
      perTabletLabel: name.isNotEmpty,
      formLabelPlural: 'capsules',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummaryHeight());
    return card;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
    final parts = <String>['Capsules'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      parts.add(
        '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unitLabel per capsule',
      );
    }
    if (_stockValueCtrl.text.isNotEmpty) {
      parts.add(
        '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} $stockLabel in stock',
      );
    }
    if (_manufacturerCtrl.text.isNotEmpty) parts.add(_manufacturerCtrl.text);
    if (_requiresFridge) parts.add('Keep refrigerated');
    if (_expiry != null) {
      parts.add('Expires - ${DateFormat.yMd().format(_expiry!)}');
    }
    if (_notesCtrl.text.isNotEmpty) parts.add(_notesCtrl.text);
    return parts.join('. ');
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

  String _unitLabel(Unit u) {
    switch (u) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      default:
        return u.name; // not expected for capsules
    }
  }

  String _stockUnitLabel(StockUnit s) {
    switch (s) {
      case StockUnit.capsules:
        return 'capsules';
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

  InputDecoration _dec({required String label, String? hint, String? helper}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      // Restore hint; labels are rendered in the left column
      hintText: hint,
      helperText: helper,
      // Render errors in helper area; suppress default error line to avoid squashing Field36
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      // hintStyle and helperStyle come from ThemeData.inputDecorationTheme
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
          width: kOutlineWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: kFocusedOutlineWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
      ),
      // No in-field label text
      labelText: null,
    );
  }

  InputDecoration _decDrop({
    required String label,
    String? hint,
    String? helper,
  }) {
    return _dec(label: label, hint: hint, helper: helper);
  }

  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    return SectionFormCard(
      title: title,
      neutral: true,
      trailing: trailing,
      children: children,
    );
  }

  Widget _rowLabelField({required String label, required Widget field}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth(),
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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

  Widget _intStepper({
    required TextEditingController controller,
    int step = 1,
    int min = 0,
    int max = 1000000,
    int width = 80,
    String? label,
    String? hint,
    String? helper,
    bool error = false,
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
                  style: Theme.of(context).textTheme.bodyMedium,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: false,
                    decimal: false,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: (() {
                    final base = _dec(
                      label: label ?? '',
                      hint: hint,
                      helper: helper,
                    );
                    if (!error) return base;
                    final cs = Theme.of(context).colorScheme;
                    return base.copyWith(
                      errorText: null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.error, width: kOutlineWidth),
                      ),
                    );
                  })(),
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

  Widget _buildEnhancedSummary() {
    if (_nameCtrl.text.isEmpty) {
      return Text(
        'Fill in medication details to see summary',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  children: [
                    TextSpan(
                      text: _nameCtrl.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_manufacturerCtrl.text.isNotEmpty)
                      TextSpan(
                        text: ' from ${_manufacturerCtrl.text}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (_strengthValueCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)} capsules.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_stockValueCtrl.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} left',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        if (_requiresFridge)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.ac_unit, size: 20, color: Colors.blue.shade700),
          ),
      ],
    );
  }

  bool _isWhole(num v) => v == v.roundToDouble();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(medicationRepositoryProvider);
    final id =
        widget.initial?.id ??
        (DateTime.now().microsecondsSinceEpoch.toString() +
            Random().nextInt(9999).toString().padLeft(4, '0'));

    final previous = widget.initial;
    final stock = double.parse(_stockValueCtrl.text);
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue
              ? stock
              : (previous.initialStockValue ?? previous.stockValue));
    final med = Medication(
      id: id,
      form: MedicationForm.capsule,
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
      stockValue: stock,
      stockUnit: _stockUnit,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty
          ? double.parse(_lowStockCtrl.text)
          : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty
          ? null
          : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty
          ? null
          : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: (() {
        final parts = <String>[];
        final s = _storageNotesCtrl.text.trim();
        if (s.isNotEmpty) parts.add(s);
        if (_keepFrozen &&
            !parts.any((p) => p.toLowerCase().contains('frozen')))
          parts.add('Keep frozen');
        if (_lightSensitive &&
            !parts.any((p) => p.toLowerCase().contains('light')))
          parts.add('Protect from light');
        return parts.isEmpty ? null : parts.join('. ');
      })(),
      initialStockValue: initialStock,
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(
          child: Text('Confirm Medication', textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Simple summary (no gradient card)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _buildSummary(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Full details
            _detailRow(context, 'Form', 'Capsule'),
            _detailRow(context, 'Name', _nameCtrl.text.trim()),
            if (_manufacturerCtrl.text.trim().isNotEmpty)
              _detailRow(
                context,
                'Manufacturer',
                _manufacturerCtrl.text.trim(),
              ),
            if (_descriptionCtrl.text.trim().isNotEmpty)
              _detailRow(context, 'Description', _descriptionCtrl.text.trim()),
            if (_notesCtrl.text.trim().isNotEmpty)
              _detailRow(context, 'Notes', _notesCtrl.text.trim()),
            if (_strengthValueCtrl.text.trim().isNotEmpty)
              _detailRow(
                context,
                'Strength',
                '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)}',
              ),
            if (_stockValueCtrl.text.trim().isNotEmpty)
              _detailRow(
                context,
                'Stock',
                '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
              ),
            if (_lowStockEnabled && _lowStockCtrl.text.trim().isNotEmpty)
              _detailRow(
                context,
                'Low stock at',
                '${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
              ),
            _detailRow(
              context,
              'Expiry',
              _expiry != null
                  ? DateFormat('dd/MM/yy').format(_expiry!)
                  : 'No expiry',
            ),
            if (_batchCtrl.text.trim().isNotEmpty)
              _detailRow(context, 'Batch #', _batchCtrl.text.trim()),
            if (_storageCtrl.text.trim().isNotEmpty)
              _detailRow(context, 'Storage', _storageCtrl.text.trim()),
            _detailRow(
              context,
              'Requires refrigeration',
              _requiresFridge ? 'Yes' : 'No',
            ),
            if (_keepFrozen) _detailRow(context, 'Keep frozen', 'Yes'),
            if (_lightSensitive)
              _detailRow(context, 'Protect from light', 'Yes'),
            if (_storageNotesCtrl.text.trim().isNotEmpty)
              _detailRow(
                context,
                'Storage notes',
                _storageNotesCtrl.text.trim(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
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
          overlayColor: WidgetStatePropertyAll(
            theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }

  Widget _generalOnlySummary() {
    final name = _nameCtrl.text.trim();
    final mfr = _manufacturerCtrl.text.trim();
    if (name.isEmpty && mfr.isEmpty) return const SizedBox.shrink();
    final s = name.isEmpty ? mfr : (mfr.isEmpty ? name : '$name – $mfr');
    return Text(s, overflow: TextOverflow.ellipsis);
  }

  String _strengthSummary() {
    // Hide until user changes the default (0) value
    if (!_touchedStrengthAmt) return '';
    final v = _strengthValueCtrl.text.trim();
    final d = double.tryParse(v) ?? 0;
    if (d <= 0) return '';
    final unit = _unitLabel(_strengthUnit);
    final name = _nameCtrl.text.trim();
    final med = name.isEmpty ? '' : ' per $name capsule';
    return '${d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toString()}$unit$med';
  }

  Widget _errorUnderLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 2, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildSummarySheet(BuildContext context) {
    // reuse the confirm dialog content in a sheet-like layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Summary',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _detailRow(context, 'Form', 'Capsule'),
        _detailRow(context, 'Name', _nameCtrl.text.trim()),
        if (_manufacturerCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Manufacturer', _manufacturerCtrl.text.trim()),
        if (_descriptionCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Description', _descriptionCtrl.text.trim()),
        if (_notesCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Notes', _notesCtrl.text.trim()),
        if (_strengthValueCtrl.text.trim().isNotEmpty)
          _detailRow(
            context,
            'Strength',
            '${(_strengthValueCtrl.text.trim())} ${_unitLabel(_strengthUnit)}',
          ),
        if (_stockValueCtrl.text.trim().isNotEmpty)
          _detailRow(
            context,
            'Stock',
            '${_stockValueCtrl.text.trim()} ${_stockUnitLabel(_stockUnit)}',
          ),
        if (_lowStockEnabled && _lowStockCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Low stock at', _lowStockCtrl.text.trim()),
        _detailRow(
          context,
          'Expiry',
          _expiry != null
              ? DateFormat('dd/MM/yy').format(_expiry!)
              : 'No expiry',
        ),
        if (_batchCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Batch #', _batchCtrl.text.trim()),
        if (_storageCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Storage', _storageCtrl.text.trim()),
        _detailRow(
          context,
          'Requires refrigeration',
          _requiresFridge ? 'Yes' : 'No',
        ),
        if (_keepFrozen) _detailRow(context, 'Keep frozen', 'Yes'),
        if (_lightSensitive) _detailRow(context, 'Protect from light', 'Yes'),
        if (_storageNotesCtrl.text.trim().isNotEmpty)
          _detailRow(context, 'Storage notes', _storageNotesCtrl.text.trim()),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derive validation messages to surface in helper rows
    String? nameError = _nameCtrl.text.trim().isEmpty ? 'Required' : null;
    String? strengthAmtError;
    final strengthTxt = _strengthValueCtrl.text.trim();
    if (strengthTxt.isEmpty) {
      strengthAmtError = 'Required';
    } else {
      final d = double.tryParse(strengthTxt);
      if (d == null)
        strengthAmtError = 'Invalid number';
      else if (d <= 0)
        strengthAmtError = 'Must be > 0';
    }
    String? stockError;
    final stockTxt = _stockValueCtrl.text.trim();
    if (stockTxt.isEmpty) {
      stockError = 'Required';
    } else {
      final d = double.tryParse(stockTxt);
      if (d == null)
        stockError = 'Invalid number';
      else if (d < 0)
        stockError = 'Must be ≥ 0';
    }
    String? thresholdError;
    if (_lowStockEnabled && _lowStockCtrl.text.trim().isNotEmpty) {
      final d = double.tryParse(_lowStockCtrl.text.trim());
      if (d == null)
        thresholdError = 'Invalid number';
      else if (d < 0)
        thresholdError = 'Must be ≥ 0';
      else {
        final stock = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
        if (d > stock) thresholdError = 'Threshold cannot exceed stock';
      }
    }

    // Gate errors until touched or submitted
    final String? gNameError = (_submitted || _touchedName) ? nameError : null;
    final String? gStrengthAmtError = (_submitted || _touchedStrengthAmt)
        ? strengthAmtError
        : null;
    final String? gStockError = (_submitted || _touchedStock)
        ? stockError
        : null;
    final String? gThresholdError = (_submitted || _touchedThreshold)
        ? thresholdError
        : null;

    final theme = Theme.of(context);

    // Determine if required fields are valid (for Save state)
    final bool requiredOk = (() {
      final nameOk = _nameCtrl.text.trim().isNotEmpty;
      final aTxt = _strengthValueCtrl.text.trim();
      final a = double.tryParse(aTxt);
      final amtOk = a != null && a > 0;
      final sTxt = _stockValueCtrl.text.trim();
      final s = double.tryParse(sTxt);
      final stockOk = s != null && s >= 0;
      return nameOk && amtOk && stockOk;
    })();

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Capsule' : 'Edit Capsule',
        forceBackButton: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 96),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
children: [
                  SizedBox(height: _summaryHeight + 10),
                  _section('General', [
                    _rowLabelField(
                      label: 'Name *',
                      field: Field36(
                        child: TextFormField(
                          controller: _nameCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration:
                              _dec(
                                label: 'Name *',
hint: 'eg. DosifiCaps-500'
                              ).copyWith(
                                // keep decorator out of error mode; we color border ourselves
                                errorText: null,
                                enabledBorder: gNameError == null
                                    ? null
                                    : OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                      ),
                                focusedBorder: gNameError == null
                                    ? null
                                    : OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                      ),
                              ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                          onChanged: (_) => setState(() {
                            _touchedName = true;
                          }),
                        ),
                      ),
                    ),
                    if (gNameError != null)
                      _errorUnderLabel(context, gNameError)
                    else
                      _helperBelowLeft(context, 'Enter the medication name'),
                    _rowLabelField(
                      label: 'Manufacturer',
                      field: Field36(
                        child: TextFormField(
                          controller: _manufacturerCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: _dec(
                            label: 'Manufacturer',
hint: 'eg. Dosifi Labs'
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft(
                      context,
                      'Enter the brand or company name',
                    ),
                    _rowLabelField(
                      label: 'Description',
                      field: Field36(
                        child: TextFormField(
                          controller: _descriptionCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: _dec(
                            label: 'Description',
hint: 'eg. Pain relief'
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    _helperBelowLeft(context, 'Optional short description'),
                    _rowLabelField(
                      label: 'Notes',
                      field: TextFormField(
                        controller: _notesCtrl,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: _dec(
                          label: 'Notes',
hint: 'eg. Take with water'
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    _helperBelowLeft(context, 'Optional notes'),
                  ]),
                  const SizedBox(height: 10),
                  _section(
                    'Strength',
                    [
                      _rowLabelField(
                        label: 'Strength *',
                        field: SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _incBtn('−', () {
                                final d = double.tryParse(
                                  _strengthValueCtrl.text.trim(),
                                );
                                final base = d?.floor() ?? 0;
                                final nv = (base - 1).clamp(0, 1000000000);
                                setState(() {
                                  _strengthValueCtrl.text = nv.toString();
                                  _touchedStrengthAmt = true;
                                });
                              }),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 120,
                                child: Field36(
                                  child: TextFormField(
                                    controller: _strengthValueCtrl,
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration:
                                        _dec(
                                          label: 'Amount *',
                                          hint: '0',
                                        ).copyWith(
                                          errorText: null,
                                          enabledBorder: gStrengthAmtError == null
                                              ? null
                                              : OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                                ),
                                          focusedBorder: gStrengthAmtError == null
                                              ? null
                                              : OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: kOutlineWidth),
                                                ),
                                        ),
                                    onChanged: (_) => setState(() {
                                      _touchedStrengthAmt = true;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _incBtn('+', () {
                                final d = double.tryParse(
                                  _strengthValueCtrl.text.trim(),
                                );
                                final base = d?.floor() ?? 0;
                                final nv = (base + 1).clamp(0, 1000000000);
                                setState(() {
                                  _strengthValueCtrl.text = nv.toString();
                                  _touchedStrengthAmt = true;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                      _rowLabelField(
                        label: 'Unit *',
                        field: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: kFieldHeight,
                            width: 120,
                            child: DropdownButtonFormField<Unit>(
                              value: _strengthUnit,
                              isExpanded: false,
                              alignment: AlignmentDirectional.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                              dropdownColor: Theme.of(
                                context,
                              ).colorScheme.surface,
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
                              onChanged: (u) => setState(
                                () => _strengthUnit = u ?? _strengthUnit,
                              ),
                              decoration: _decDrop(
                                label: '',
                                hint: null,
                                helper: null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (gStrengthAmtError != null)
                        _errorUnderLabel(context, gStrengthAmtError)
                      else
                        _helperBelowCenter(
                          context,
                          'Specify the amount per capsule and its unit of measurement.',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _section('Inventory', [
                    _rowLabelField(
                      label: 'Stock quantity *',
                      field: StepperRow36(
                        controller: _stockValueCtrl,
                        onDec: () {
                          final d = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                          final nv = (d - 1).clamp(0, 1000000000).toStringAsFixed(0);
                          setState(() {
                            _stockValueCtrl.text = nv;
                            _touchedStock = true;
                          });
                        },
                        onInc: () {
                          final d = double.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                          final nv = (d + 1).clamp(0, 1000000000).toStringAsFixed(0);
                          setState(() {
                            _stockValueCtrl.text = nv;
                            _touchedStock = true;
                          });
                        },
                        decoration: _dec(
                          label: 'Stock quantity *',
                          hint: '0',
                        ),
                      ),
                    ),
                    if (gStockError != null)
                      _errorUnderLabel(context, gStockError)
                    else
                      _helperBelowLeft(
                        context,
                        'Enter the number of capsules currently in stock',
                      ),
                    _rowLabelField(
                      label: 'Low stock alert',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _lowStockEnabled,
                            onChanged: (v) =>
                                setState(() => _lowStockEnabled = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'Enable alert when stock is low',
                              style: kCheckboxLabelStyle(context),
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_lowStockEnabled) ...[
                      _rowLabelField(
                        label: 'Threshold',
                        field: _intStepper(
                          controller: _lowStockCtrl,
                          step: 1,
                          min: 0,
                          max: 100000,
                          width: 120,
                          label: 'Threshold',
                          hint: '0',
                          error: gThresholdError != null,
                        ),
                      ),
                      if (gThresholdError != null)
                        _errorUnderLabel(context, gThresholdError)
                      else
                        _helperBelowLeftCompact(
                          context,
                          'Set the stock level that triggers a low stock alert',
                        ),
                    ],
                    _rowLabelField(
                      label: 'Expiry date',
                      field: SizedBox(
                        width: 120,
child: DateButton36(
                          label: _expiry == null
                              ? 'Select date'
                              : MaterialLocalizations.of(context).formatCompactDate(_expiry!),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 10),
                              initialDate: _expiry ?? now,
                            );
                            if (picked != null) setState(() => _expiry = picked);
                          },
                          width: 120,
                          selected: _expiry != null,
                        ),
                      ),
                    ),
                  _helperBelowLeft(context, 'Enter the expiry date'),
                  ]),
                  const SizedBox(height: 10),
                  _section('Storage', [
                    _rowLabelField(
                      label: 'Batch No.',
                      field: Field36(
                        child: TextFormField(
                          controller: _batchCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: _dec(
                            label: 'Batch No.',
                            hint: 'Enter batch number',
                          ),
                        ),
                      ),
                    ),
                    _helperBelowLeft(
                      context,
                      'Enter the printed batch or lot number',
                    ),
                    _rowLabelField(
                      label: 'Location',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: _dec(
                            label: 'Location',
                            hint: 'eg. Bathroom cabinet',
                          ),
                        ),
                      ),
                    ),
                    _helperBelowLeft(
                      context,
                      'Where it’s stored (e.g., Bathroom cabinet)',
                    ),
_rowLabelField(
                      label: 'Keep refrigerated',
                      field: Opacity(
                        opacity: _keepFrozen ? 0.5 : 1.0,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _requiresFridge,
                            onChanged: _keepFrozen
                                ? null
                                : (v) => setState(
                                    () => _requiresFridge = v ?? false,
                                  ),
                          ),
                          Text(
                            'Refrigerate',
                            style: _keepFrozen
                                ? kMutedLabelStyle(context)
                                : kCheckboxLabelStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                    _helperBelowLeftCompact(
                      context,
                      'Enable if this medication must be kept refrigerated',
                    ),
                    _rowLabelField(
                      label: 'Keep frozen',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _keepFrozen,
                            onChanged: (v) => setState(() {
                              _keepFrozen = v ?? false;
                              if (_keepFrozen) _requiresFridge = false;
                            }),
                          ),
                          Text('Freeze', style: kCheckboxLabelStyle(context)),
                        ],
                      ),
                    ),
                    _helperBelowLeftCompact(
                      context,
                      'Enable if this medication must be kept frozen',
                    ),
                    _rowLabelField(
                      label: 'Keep in dark',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _lightSensitive,
                            onChanged: (v) =>
                                setState(() => _lightSensitive = v ?? false),
                          ),
                          Text(
                            'Dark storage',
                            style: kCheckboxLabelStyle(context),
                          ),
                        ],
                      ),
                    ),
                    _helperBelowLeftCompact(
                      context,
                      'Enable if this medication must be protected from light',
                    ),
                    _rowLabelField(
                      label: 'Storage instructions',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageNotesCtrl,
                          textAlign: TextAlign.left,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: _dec(
                            label: 'Storage instructions',
                            hint: 'Enter storage instructions',
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // Floating summary pinned beneath app bar
          Positioned(
            left: 10,
            right: 10,
            top: 8,
            child: IgnorePointer(child: _floatingSummaryCard()),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 120,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: requiredOk
                ? null
                : Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: requiredOk
                ? null
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onPressed: () {
            setState(() => _submitted = true);
            if (!requiredOk) return;
            _submit();
          },
          child: Text(widget.initial == null ? 'Save' : 'Update'),
        ),
      ),
    );
  }
}
