import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/form_field_styler.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import '../../../core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/med_editor_template.dart';

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
    // Ensure Per mL has a sensible default when using */mL
    if (_isPerMl && _perMlCtrl.text.trim().isEmpty) {
      _perMlCtrl.text = '1';
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

  // Match Tablet _dec exactly: padding, height, fill, borders, and suppressed error line
  InputDecoration _dec({
    required BuildContext context,
    required String label,
    String? hint,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      helperText: helper,
      // Render errors in helper area; suppress default error line to avoid height changes
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
    );
  }

  // Dropdown decoration matching Tablet’s _decDrop
  InputDecoration _decDrop({
    required BuildContext context,
    required String label,
    String? hint,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      helperText: helper,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        color: cs.onSurfaceVariant.withOpacity(0.60),
      ),
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
      labelText: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveEnabled = (() {
      final nameOk = _nameCtrl.text.trim().isNotEmpty;
      final a = double.tryParse(_strengthValueCtrl.text.trim());
      final amtOk = a != null && a > 0;
      final s = double.tryParse(_stockValueCtrl.text.trim());
      final stockOk = s != null && s >= 0;
      return nameOk && amtOk && stockOk;
    })();

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
          onPressed: saveEnabled ? _submit : null,
          icon: const Icon(Icons.save),
          label: Text(widget.initial == null ? 'Save' : 'Update'),
        ),
      ),
      body: MedEditorTemplate(
        appBarTitle: widget.initial == null ? 'Add Pre-Filled Syringe' : 'Edit Pre-Filled Syringe',
        summaryBuilder: (key) {
          final name = _nameCtrl.text.trim();
          final manufacturer = _manufacturerCtrl.text.trim();
          final strengthVal = double.tryParse(_strengthValueCtrl.text.trim());
          final stockVal = double.tryParse(_stockValueCtrl.text.trim());
          final unitLabel = _unitLabel(_strengthUnit);
          final perMlVal = _isPerMl ? double.tryParse(_perMlCtrl.text.trim()) : null;
          return SummaryHeaderCard(
            key: key,
            title: name.isEmpty ? 'Pre-Filled Syringes' : name,
            manufacturer: manufacturer.isEmpty ? null : manufacturer,
            strengthValue: strengthVal,
            strengthUnitLabel: unitLabel,
            perMlValue: perMlVal,
            stockCurrent: stockVal,
            stockInitial: widget.initial?.initialStockValue ?? stockVal ?? 0,
            stockUnitLabel: 'syringes',
            expiryDate: _expiry,
            showRefrigerate: _requiresFridge,
            showDark: (_storageNotesCtrl.text.toLowerCase().contains('light')),
            lowStockEnabled: _lowStockEnabled,
            lowStockThreshold: double.tryParse(_lowStockCtrl.text.trim()),
            includeNameInStrengthLine: false,
            perTabletLabel: false,
            perUnitLabel: 'Syringe',
          );
        },

        // General
        nameField: Field36(
          child: TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Name *', hint: 'eg. DosifiTab-500'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        manufacturerField: Field36(
          child: TextFormField(
            controller: _manufacturerCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Manufacturer', hint: 'eg. Dosifi Labs'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        descriptionField: Field36(
          child: TextFormField(
            controller: _descriptionCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Description', hint: 'eg. Pain relief'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        notesField: Field36(
          child: TextFormField(
            controller: _notesCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Notes', hint: 'eg. Take with water'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        nameHelp: 'Enter the medication name',
        manufacturerHelp: 'Enter the brand or company name',
        descriptionHelp: 'Optional short description',
        notesHelp: 'Optional notes',

        // Strength
        strengthStepper: StepperRow36(
          controller: _strengthValueCtrl,
          onDec: () {
            final v = int.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            setState(() => _strengthValueCtrl.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_strengthValueCtrl.text.trim()) ?? 0;
            setState(() => _strengthValueCtrl.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        unitDropdown: SmallDropdown36<Unit>(
          value: _strengthUnit,
          width: kSmallControlWidth,
          items: const [
            DropdownMenuItem(value: Unit.mcg, child: Center(child: Text('mcg'))),
            DropdownMenuItem(value: Unit.mg, child: Center(child: Text('mg'))),
            DropdownMenuItem(value: Unit.g, child: Center(child: Text('g'))),
            DropdownMenuItem(value: Unit.units, child: Center(child: Text('units'))),
            DropdownMenuItem(value: Unit.mcgPerMl, child: Center(child: Text('mcg/mL'))),
            DropdownMenuItem(value: Unit.mgPerMl, child: Center(child: Text('mg/mL'))),
            DropdownMenuItem(value: Unit.gPerMl, child: Center(child: Text('g/mL'))),
            DropdownMenuItem(value: Unit.unitsPerMl, child: Center(child: Text('units/mL'))),
          ],
          onChanged: (v) => setState(() {
            _strengthUnit = v ?? _strengthUnit;
            if (_isPerMl && _perMlCtrl.text.trim().isEmpty) {
              _perMlCtrl.text = '1';
            }
          }),
        ),
        perMlStepper: _isPerMl
            ? StepperRow36(
                controller: _perMlCtrl,
                onDec: () {
                  final v = double.tryParse(_perMlCtrl.text.trim()) ?? 1;
                  setState(() => _perMlCtrl.text = (v - 1).clamp(1, 1000000).toStringAsFixed(0));
                },
                onInc: () {
                  final v = double.tryParse(_perMlCtrl.text.trim()) ?? 1;
                  setState(() => _perMlCtrl.text = (v + 1).clamp(1, 1000000).toStringAsFixed(0));
                },
                decoration: const InputDecoration(
                  hintText: '1',
                  isDense: false,
                  isCollapsed: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                ),
              )
            : null,
        strengthHelp: 'Specify the amount and unit; if using */mL, volume defaults to 1 mL.',
        perMlHelp: _isPerMl ? 'Volume (mL) for the concentration; defaults to 1 mL.' : null,

        // Inventory
        stockStepper: StepperRow36(
          controller: _stockValueCtrl,
          onDec: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(() => _stockValueCtrl.text = (v - 1).clamp(0, 1000000).toString());
          },
          onInc: () {
            final v = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
            setState(() => _stockValueCtrl.text = (v + 1).clamp(0, 1000000).toString());
          },
          decoration: const InputDecoration(
            hintText: '0',
            isDense: false,
            isCollapsed: false,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(minHeight: kFieldHeight),
          ),
        ),
        stockHelp: 'Enter the amount currently in stock',
        lowStockRow: Row(
          children: [
            Checkbox(value: _lowStockEnabled, onChanged: (v) => setState(() => _lowStockEnabled = v ?? false)),
            Expanded(child: Text('Enable alert when stock is low', style: kCheckboxLabelStyle(context), maxLines: 2, softWrap: true)),
          ],
        ),
        lowStockThresholdField: _lowStockEnabled
            ? StepperRow36(
                controller: _lowStockCtrl,
                onDec: () {
                  final v = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                  setState(() => _lowStockCtrl.text = (v - 1).clamp(0, 1000000).toString());
                },
                onInc: () {
                  final v = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                  final maxStock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                  setState(() => _lowStockCtrl.text = (v + 1).clamp(0, maxStock).toString());
                },
                decoration: const InputDecoration(
                  hintText: '0',
                  isDense: false,
                  isCollapsed: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(minHeight: kFieldHeight),
                ),
                compact: true,
              )
            : null,
        lowStockHelp: _lowStockEnabled
            ? (() {
                final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
                final thr = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
                if (stock > 0 && thr >= stock) {
                  return 'Max threshold cannot exceed stock count.';
                }
                return 'Set the stock level that triggers a low stock alert';
              })()
            : null,
        lowStockHelpColor: (() {
          if (!_lowStockEnabled) return null;
          final stock = int.tryParse(_stockValueCtrl.text.trim()) ?? 0;
          final thr = int.tryParse(_lowStockCtrl.text.trim()) ?? 0;
          return (stock > 0 && thr >= stock) ? Colors.orange : null;
        })(),
        quantityDropdown: SmallDropdown36<StockUnit>(
          value: _stockUnit,
          width: kSmallControlWidth,
          items: const [
            DropdownMenuItem(value: StockUnit.preFilledSyringes, child: Center(child: Text('syringes'))),
          ],
          onChanged: (v) => setState(() => _stockUnit = v ?? _stockUnit),
        ),
        expiryDateButton: DateButton36(
          label: _expiry == null ? 'Select date' : MaterialLocalizations.of(context).formatCompactDate(_expiry!),
          onPressed: () async { await _pickExpiry(); },
          width: kSmallControlWidth,
          selected: _expiry != null,
        ),

        // Storage
        batchField: Field36(
          child: TextFormField(
            controller: _batchCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Batch No.', hint: 'Enter batch number'),
          ),
        ),
        locationField: Field36(
          child: TextFormField(
            controller: _storageCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Location', hint: 'eg. Bathroom cabinet'),
          ),
        ),
        refrigerateRow: Opacity(
          opacity: _keepFrozen ? 0.5 : 1.0,
          child: Row(children: [
            Checkbox(value: _requiresFridge, onChanged: _keepFrozen ? null : (v) => setState(() => _requiresFridge = v ?? false)),
            Text('Refrigerate', style: _keepFrozen ? kMutedLabelStyle(context) : Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        freezeRow: Row(children: [
          Checkbox(value: _keepFrozen, onChanged: (v) => setState(() { _keepFrozen = v ?? false; if (_keepFrozen) _requiresFridge = false; })),
          Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
        ]),
        darkRow: Row(children: [
          Checkbox(value: _lightSensitive, onChanged: (v) => setState(() => _lightSensitive = v ?? false)),
          Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
        ]),
        storageInstructionsField: Field36(
          child: TextFormField(
            controller: _storageNotesCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context: context, label: 'Storage instructions', hint: 'Enter storage instructions'),
          ),
        ),
      ),
    );
  }
}
