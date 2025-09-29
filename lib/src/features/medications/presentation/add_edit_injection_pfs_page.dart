import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/form_field_styler.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import '../../../core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditInjectionPfsPage extends ConsumerStatefulWidget {
  const AddEditInjectionPfsPage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddEditInjectionPfsPage> createState() =>
      _AddEditInjectionPfsPageState();
}

class _AddEditInjectionPfsPageState
    extends ConsumerState<AddEditInjectionPfsPage> {
  // Floating summary like Tablet/Capsule
  final GlobalKey _summaryKey = GlobalKey();
  double _summaryHeight = 0;
  final ScrollController _scrollCtrl = ScrollController();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;
  final _perMlCtrl = TextEditingController();

  final _stockValueCtrl = TextEditingController();
  StockUnit _stockUnit = StockUnit.preFilledSyringes;

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  bool _summaryExpanded = true;

  int _formStyleIndex = 0;

  Future<void> _loadStylePrefs() async {
    final f = await UserPrefs.getFormFieldStyle();
    if (mounted) setState(() => _formStyleIndex = f);
  }

  bool get _isPerMl => {
    Unit.mcgPerMl,
    Unit.mgPerMl,
    Unit.gPerMl,
    Unit.unitsPerMl,
  }.contains(_strengthUnit);

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
      _perMlCtrl.text = med.perMlValue?.toString() ?? '';
      _stockValueCtrl.text = med.stockValue.toString();
      _lowStockEnabled = med.lowStockEnabled;
      _lowStockCtrl.text = med.lowStockThreshold?.toString() ?? '';
      _expiry = med.expiry;
      _batchCtrl.text = med.batchNumber ?? '';
      _storageCtrl.text = med.storageLocation ?? '';
      _requiresFridge = med.requiresRefrigeration;
      _storageNotesCtrl.text = med.storageInstructions ?? '';
      final si = med.storageInstructions ?? '';
      _lightSensitive = si.toLowerCase().contains('light');
      _keepFrozen = si.toLowerCase().contains('frozen');
    }
    _loadStylePrefs();
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
    final unitLabel = _unitLabel(_strengthUnit);
    final threshold = double.tryParse(_lowStockCtrl.text.trim());
    final headerTitle = name.isEmpty ? 'Add Pre-Filled Syringe' : name;

    final card = SummaryHeaderCard(
      key: _summaryKey,
      title: headerTitle,
      manufacturer: manufacturer.isEmpty ? null : manufacturer,
      strengthValue: strengthVal,
      strengthUnitLabel: unitLabel,
      stockCurrent: stockVal,
      stockInitial: initialStock,
      stockUnitLabel: 'syringes',
      expiryDate: _expiry,
      showRefrigerate: _requiresFridge,
      showDark: (_storageNotesCtrl.text.toLowerCase().contains('light')),
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: threshold,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSummaryHeight());
    return card;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _descriptionCtrl.dispose();
    _notesCtrl.dispose();
    _strengthValueCtrl.dispose();
    _perMlCtrl.dispose();
    _stockValueCtrl.dispose();
    _lowStockCtrl.dispose();
    _batchCtrl.dispose();
    _storageCtrl.dispose();
    _storageNotesCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _unitLabel(Unit u) => {
    Unit.mcg: 'mcg',
    Unit.mg: 'mg',
    Unit.g: 'g',
    Unit.units: 'units',
    Unit.mcgPerMl: 'mcg/mL',
    Unit.mgPerMl: 'mg/mL',
    Unit.gPerMl: 'g/mL',
    Unit.unitsPerMl: 'units/mL',
  }[u]!;

  String _buildSummary() {
    final parts = <String>['Pre Filled Syringe'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      final unit = _unitLabel(_strengthUnit);
      if (_isPerMl && _perMlCtrl.text.isNotEmpty) {
        parts.add(
          '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unit, ${fmt2(double.tryParse(_perMlCtrl.text) ?? 0)} mL',
        );
      } else {
        parts.add(
          '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unit',
        );
      }
    }
    if (_stockValueCtrl.text.isNotEmpty)
      parts.add(
        '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} pre filled syringes in stock',
      );
    if (_manufacturerCtrl.text.isNotEmpty) parts.add(_manufacturerCtrl.text);
    if (_requiresFridge) parts.add('Keep refrigerated');
    if (_expiry != null)
      parts.add('Expires - ${DateFormat.yMd().format(_expiry!)}');
    if (_notesCtrl.text.isNotEmpty) parts.add(_notesCtrl.text);
    return parts.join('. ');
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

    return Column(
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
                text: ' PFS.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        if (_strengthValueCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)}${_isPerMl && _perMlCtrl.text.isNotEmpty ? ', ${fmt2(double.tryParse(_perMlCtrl.text) ?? 0)} mL' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
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
      form: MedicationForm.injectionPreFilledSyringe,
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
      perMlValue: _isPerMl && _perMlCtrl.text.isNotEmpty
          ? double.parse(_perMlCtrl.text)
          : null,
      stockValue: stock,
      stockUnit: StockUnit.preFilledSyringes,
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
        if (_keepFrozen && !parts.any((p) => p.toLowerCase().contains('frozen')))
          parts.add('Keep frozen');
        if (_lightSensitive && !parts.any((p) => p.toLowerCase().contains('light')))
          parts.add('Protect from light');
        return parts.isEmpty ? null : parts.join('. ');
      })(),
      initialStockValue: initialStock,
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Center(child: Text('Confirm Medication', textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        content: SingleChildScrollView(child: Text(_buildSummary())),
        actionsAlignment: MainAxisAlignment.center,
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

  // Match Capsule/Tablet input decoration (fill, borders, padding, fonts)
  InputDecoration _dec({
    required BuildContext context,
    required String label,
    String? hint,
    String? helper,
  }) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null
            ? 'Add Medication - Pre-Filled Syringe'
            : 'Edit Medication - Pre-Filled Syringe',
        forceBackButton: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 140,
        child: FilledButton.icon(
          onPressed:
              (() {
                final nameOk = _nameCtrl.text.trim().isNotEmpty;
                final a = double.tryParse(_strengthValueCtrl.text.trim());
                final amtOk = a != null && a > 0;
                final s = double.tryParse(_stockValueCtrl.text.trim());
                final stockOk = s != null && s >= 0;
                return nameOk && amtOk && stockOk;
              })()
              ? _submit
              : null,
          icon: const Icon(Icons.save),
          label: Text(widget.initial == null ? 'Save' : 'Update'),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
children: [
              SizedBox(height: _summaryHeight + 10),
              const SizedBox(height: 8),
              SectionFormCard(
                title: 'General',
                children: [
                  LabelFieldRow(
                    label: 'Name *',
                    field: Field36(
                      child: TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec(
                          context: context,
                          label: 'Name *',
                          hint: 'eg. AcmeTab-500',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Manufacturer',
                    field: Field36(
                      child: TextFormField(
                        controller: _manufacturerCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec(
                          context: context,
                          label: 'Manufacturer',
                          hint: 'eg. Contoso Pharma',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Description',
                    field: Field36(
                      child: TextFormField(
                        controller: _descriptionCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec(
                          context: context,
                          label: 'Description',
                          hint: 'eg. Pain relief',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Notes',
                    field: Field36(
                      child: TextFormField(
                        controller: _notesCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dec(
                          context: context,
                          label: 'Notes',
                          hint: 'eg. Take with food',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Strength card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strength',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _rowLabelField(
                      label: 'Strength *',
                      field: Row(
                        children: [
                          _pillBtn(context, '−', () {
                            final v =
                                int.tryParse(_strengthValueCtrl.text) ?? 0;
                            final nv = (v - 1).clamp(0, 1000000);
                            setState(
                              () => _strengthValueCtrl.text = nv.toString(),
                            );
                          }),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: Field36(
                              child: TextFormField(
                                controller: _strengthValueCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: _dec(
                                  context: context,
                                  label: 'Strength amount *',
                                  hint: '0',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _pillBtn(context, '+', () {
                            final v =
                                int.tryParse(_strengthValueCtrl.text) ?? 0;
                            final nv = (v + 1).clamp(0, 1000000);
                            setState(
                              () => _strengthValueCtrl.text = nv.toString(),
                            );
                          }),
                        ],
                      ),
                    ),
                    _rowLabelField(
                      label: 'Unit *',
                      field: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: kFieldHeight,
                          width: 120,
                          child: DropdownButtonFormField<Unit>(
                            value: _strengthUnit,
                            isExpanded: false,
                            alignment: AlignmentDirectional.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                            items: const [
                              DropdownMenuItem(
                                value: Unit.mcg,
                                child: Center(child: Text('mcg')),
                              ),
                              DropdownMenuItem(
                                value: Unit.mg,
                                child: Center(child: Text('mg')),
                              ),
                              DropdownMenuItem(
                                value: Unit.g,
                                child: Center(child: Text('g')),
                              ),
                              DropdownMenuItem(
                                value: Unit.units,
                                child: Center(child: Text('units')),
                              ),
                              DropdownMenuItem(
                                value: Unit.mcgPerMl,
                                child: Center(child: Text('mcg/mL')),
                              ),
                              DropdownMenuItem(
                                value: Unit.mgPerMl,
                                child: Center(child: Text('mg/mL')),
                              ),
                              DropdownMenuItem(
                                value: Unit.gPerMl,
                                child: Center(child: Text('g/mL')),
                              ),
                              DropdownMenuItem(
                                value: Unit.unitsPerMl,
                                child: Center(child: Text('units/mL')),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _strengthUnit = v!);
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                            ),
                            menuMaxHeight: 320,
                          ),
                        ),
                      ),
                    ),
                    if (_isPerMl)
                      _rowLabelField(
                        label: 'Per mL',
                        field: SizedBox(
                          width: 160,
                          child: TextFormField(
                            controller: _perMlCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Per mL',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 120 + 8),
                      child: Text(
                        'Specify the amount per dose and its unit of measurement.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Inventory card (with Expiry + Low Stock inside)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _rowLabelField(
                      label: 'Stock quantity *',
                      field: Row(
                        children: [
                          _pillBtn(context, '−', () {
                            final v = int.tryParse(_stockValueCtrl.text) ?? 0;
                            final nv = (v - 1).clamp(0, 1000000);
                            setState(
                              () => _stockValueCtrl.text = nv.toString(),
                            );
                          }),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: Field36(
                              child: TextFormField(
                                controller: _stockValueCtrl,
                                textAlign: TextAlign.center,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: false,
                                    ),
                                decoration: _dec(
                                  context: context,
                                  label: 'Stock amount *',
                                  hint: '0',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _pillBtn(context, '+', () {
                            final v = int.tryParse(_stockValueCtrl.text) ?? 0;
                            final nv = (v + 1).clamp(0, 1000000);
                            setState(
                              () => _stockValueCtrl.text = nv.toString(),
                            );
                          }),
                        ],
                      ),
                    ),
                    _rowLabelField(
                      label: 'Quantity unit',
                      field: Align(
                        alignment: Alignment.centerLeft,
                        child: SmallDropdown36<StockUnit>(
                          value: _stockUnit,
                          items: const [
                            DropdownMenuItem(
                              value: StockUnit.preFilledSyringes,
                              child: Center(child: Text('pre filled syringes')),
                            ),
                          ],
                          onChanged: (v) => setState(() => _stockUnit = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 120 + 8),
                      child: Text(
                        'Get notified when stock is low',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Low Stock Alerts',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Get notified when stock is low',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            value: _lowStockEnabled,
                            onChanged: (v) =>
                                setState(() => _lowStockEnabled = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: _lowStockEnabled
                              ? SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    key: const ValueKey('lowStockField'),
                                    controller: _lowStockCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Threshold',
                                      hintText: '0',
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('lowStockPlaceholder'),
                                  width: 120,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _rowLabelField(
                      label: 'Expiry date',
                      field: Align(
                        alignment: Alignment.centerLeft,
child: DateButton36(
                          label: _expiry == null
                              ? 'Select date'
                              : MaterialLocalizations.of(context).formatCompactDate(_expiry!),
                          onPressed: () async { await _pickExpiry(); },
                          width: kSmallControlWidth,
                          selected: _expiry != null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Storage card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _rowLabelField(
                      label: 'Batch No.',
                      field: Field36(
                        child: TextFormField(
                          controller: _batchCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            context: context,
                            label: 'Batch No.',
                            hint: 'Enter batch number',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _rowLabelField(
                      label: 'Location',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            context: context,
                            label: 'Location',
                            hint: 'eg. Bathroom cabinet',
                          ),
                        ),
                      ),
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
                                : (v) => setState(() => _requiresFridge = v ?? false),
                          ),
                          Text(
                            'Refrigerate',
                            style: _keepFrozen
                                ? Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)
                                : Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
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
                          Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    _rowLabelField(
                      label: 'Keep in dark',
                      field: Row(
                        children: [
                          Checkbox(
                            value: _lightSensitive,
                            onChanged: (v) => setState(() => _lightSensitive = v ?? false),
                          ),
                          Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    _rowLabelField(
                      label: 'Storage instructions',
                      field: Field36(
                        child: TextFormField(
                          controller: _storageNotesCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _dec(
                            context: context,
                            label: 'Storage instructions',
                            hint: 'Enter storage instructions',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
          // Floating summary pinned below app bar
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            child: IgnorePointer(child: _floatingSummaryCard()),
          ),
        ],
      ),
    );
  }
}
