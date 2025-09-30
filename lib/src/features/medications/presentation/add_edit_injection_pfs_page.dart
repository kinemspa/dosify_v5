import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/med_editor_template.dart';
import '../presentation/providers.dart';

class AddEditInjectionPfsPage extends ConsumerStatefulWidget {
  const AddEditInjectionPfsPage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddEditInjectionPfsPage> createState() => _AddEditInjectionPfsPageState();
}

class _AddEditInjectionPfsPageState extends ConsumerState<AddEditInjectionPfsPage> {
  final _formKey = GlobalKey<FormState>();

  // General
  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  // Strength
  final _strength = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMl = TextEditingController(text: '1');
  bool get _isPerMl =>
      _strengthUnit == Unit.mcgPerMl || _strengthUnit == Unit.mgPerMl || _strengthUnit == Unit.gPerMl || _strengthUnit == Unit.unitsPerMl;

  // Inventory
  final _stock = TextEditingController(text: '0');
  StockUnit _stockUnit = StockUnit.preFilledSyringes;
  DateTime? _expiry;
  bool _lowStockAlert = false;
  final _lowStockThreshold = TextEditingController(text: '0');

  // Storage
  final _batch = TextEditingController();
  final _location = TextEditingController();
  final _storageNotes = TextEditingController();
  bool _refrigerate = false;
  bool _keepFrozen = false;
  bool _lightSensitive = false;

  @override
  void initState() {
    super.initState();
    final med = widget.initial;
    if (med != null) {
      _name.text = med.name;
      _manufacturer.text = med.manufacturer ?? '';
      _description.text = med.description ?? '';
      _notes.text = med.notes ?? '';
      _strength.text = med.strengthValue.toString();
      _strengthUnit = med.strengthUnit;
      _perMl.text = med.perMlValue?.toString() ?? '1';
      _stock.text = med.stockValue.toString();
      _stockUnit = med.stockUnit;
      _expiry = med.expiry;
      _lowStockAlert = med.lowStockEnabled;
      _lowStockThreshold.text = med.lowStockThreshold?.toString() ?? '0';
      _batch.text = med.batchNumber ?? '';
      _location.text = med.storageLocation ?? '';
      _refrigerate = med.requiresRefrigeration;
      _storageNotes.text = med.storageInstructions ?? '';
      final si = med.storageInstructions ?? '';
      _lightSensitive = si.toLowerCase().contains('light');
      _keepFrozen = si.toLowerCase().contains('frozen');
    }
    // Ensure Per mL has a sensible default when using */mL
    if (_isPerMl && _perMl.text.trim().isEmpty) {
      _perMl.text = '1';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _manufacturer.dispose();
    _description.dispose();
    _notes.dispose();
    _strength.dispose();
    _perMl.dispose();
    _stock.dispose();
    _lowStockThreshold.dispose();
    _batch.dispose();
    _location.dispose();
    _storageNotes.dispose();
    super.dispose();
  }

  String _unitLabel(Unit u) {
    if (u == Unit.mcg || u == Unit.mcgPerMl) return 'mcg';
    if (u == Unit.mg || u == Unit.mgPerMl) return 'mg';
    if (u == Unit.g || u == Unit.gPerMl) return 'g';
    return 'units';
  }

  InputDecoration _dec(BuildContext context, {String? hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.never,
      isDense: false,
      isCollapsed: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minHeight: kFieldHeight),
      hintText: hint,
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5), width: kOutlineWidth),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(medicationRepositoryProvider);
    final id =
        widget.initial?.id ??
        (DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(9999).toString().padLeft(4, '0'));

    final previous = widget.initial;
    final stock = double.parse(_stock.text);
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue ? stock : (previous.initialStockValue ?? previous.stockValue));

    final med = Medication(
      id: id,
      form: MedicationForm.injectionPreFilledSyringe,
      name: _name.text.trim(),
      manufacturer: _manufacturer.text.trim().isEmpty ? null : _manufacturer.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      strengthValue: double.parse(_strength.text),
      strengthUnit: _strengthUnit,
      perMlValue: _isPerMl && _perMl.text.isNotEmpty ? double.parse(_perMl.text) : null,
      stockValue: stock,
      stockUnit: StockUnit.preFilledSyringes,
      lowStockEnabled: _lowStockAlert,
      lowStockThreshold: _lowStockAlert && _lowStockThreshold.text.isNotEmpty ? double.parse(_lowStockThreshold.text) : null,
      expiry: _expiry,
      batchNumber: _batch.text.trim().isEmpty ? null : _batch.text.trim(),
      storageLocation: _location.text.trim().isEmpty ? null : _location.text.trim(),
      requiresRefrigeration: _refrigerate,
      storageInstructions: (() {
        final parts = <String>[];
        final s = _storageNotes.text.trim();
        if (s.isNotEmpty) parts.add(s);
        if (_keepFrozen && !parts.any((p) => p.toLowerCase().contains('frozen'))) parts.add('Keep frozen');
        if (_lightSensitive && !parts.any((p) => p.toLowerCase().contains('light'))) parts.add('Protect from light');
        return parts.isEmpty ? null : parts.join('. ');
      })(),
      initialStockValue: initialStock,
    );

    await repo.upsert(med);
    if (!mounted) return;
    context.go('/medications');
  }

  @override
  Widget build(BuildContext context) {
    final saveEnabled = (() {
      final nameOk = _name.text.trim().isNotEmpty;
      final a = double.tryParse(_strength.text.trim());
      final amtOk = a != null && a > 0;
      final s = double.tryParse(_stock.text.trim());
      final stockOk = s != null && s >= 0;
      return nameOk && amtOk && stockOk;
    })();

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Medication - Pre-Filled Syringe' : 'Edit Medication - Pre-Filled Syringe',
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
      body: Form(
        key: _formKey,
        child: MedEditorTemplate(
          appBarTitle: widget.initial == null ? 'Add Pre-Filled Syringe' : 'Edit Pre-Filled Syringe',
          summaryBuilder: (key) {
            final name = _name.text.trim();
            final manufacturer = _manufacturer.text.trim();
            final strengthVal = double.tryParse(_strength.text.trim());
            final stockVal = double.tryParse(_stock.text.trim());
            final unitLabel = _unitLabel(_strengthUnit);
            final perMlVal = _isPerMl ? double.tryParse(_perMl.text.trim()) : null;
            return SummaryHeaderCard(
              key: key,
              title: name.isEmpty ? 'Pre-Filled Syringe' : name,
              manufacturer: manufacturer.isEmpty ? null : manufacturer,
              strengthValue: strengthVal,
              strengthUnitLabel: unitLabel,
              perMlValue: perMlVal,
              stockCurrent: stockVal,
              stockInitial: widget.initial?.initialStockValue ?? stockVal ?? 0,
              stockUnitLabel: 'syringes',
              expiryDate: _expiry,
              showRefrigerate: _refrigerate,
              showFrozen: _keepFrozen,
              showDark: _lightSensitive,
              lowStockEnabled: _lowStockAlert,
              lowStockThreshold: double.tryParse(_lowStockThreshold.text.trim()),
              includeNameInStrengthLine: false,
              perTabletLabel: false,
              perUnitLabel: 'Syringe',
            );
          },

          // General
          nameField: Field36(
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'eg. Insulin Aspart'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          manufacturerField: Field36(
            child: TextFormField(
              controller: _manufacturer,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'eg. Novo Nordisk'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          descriptionField: Field36(
            child: TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'eg. Rapid-acting insulin'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          notesField: Field36(
            child: TextFormField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'eg. Inject before meals'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          nameHelp: 'Enter the medication name',
          manufacturerHelp: 'Enter the brand or company name',
          descriptionHelp: 'Optional short description',
          notesHelp: 'Optional notes',

          // Strength
          strengthStepper: StepperRow36(
            controller: _strength,
            onDec: () {
              final v = int.tryParse(_strength.text.trim()) ?? 0;
              setState(() => _strength.text = (v - 1).clamp(0, 1000000).toString());
            },
            onInc: () {
              final v = int.tryParse(_strength.text.trim()) ?? 0;
              setState(() => _strength.text = (v + 1).clamp(0, 1000000).toString());
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
              if (_isPerMl && _perMl.text.trim().isEmpty) {
                _perMl.text = '1';
              }
            }),
          ),
          perMlStepper: _isPerMl
              ? StepperRow36(
                  controller: _perMl,
                  onDec: () {
                    final v = double.tryParse(_perMl.text.trim()) ?? 1;
                    setState(() => _perMl.text = (v - 1).clamp(1, 1000000).toStringAsFixed(0));
                  },
                  onInc: () {
                    final v = double.tryParse(_perMl.text.trim()) ?? 1;
                    setState(() => _perMl.text = (v + 1).clamp(1, 1000000).toStringAsFixed(0));
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
          strengthHelp: 'Specify the amount per dose and its unit of measurement.',
          perMlHelp: _isPerMl ? 'Volume (mL) for the concentration; defaults to 1 mL.' : null,

          // Inventory
          stockStepper: StepperRow36(
            controller: _stock,
            onDec: () {
              final v = int.tryParse(_stock.text.trim()) ?? 0;
              setState(() => _stock.text = (v - 1).clamp(0, 1000000).toString());
            },
            onInc: () {
              final v = int.tryParse(_stock.text.trim()) ?? 0;
              setState(() => _stock.text = (v + 1).clamp(0, 1000000).toString());
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
              Checkbox(value: _lowStockAlert, onChanged: (v) => setState(() => _lowStockAlert = v ?? false)),
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
          lowStockThresholdField: _lowStockAlert
              ? StepperRow36(
                  controller: _lowStockThreshold,
                  onDec: () {
                    final v = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                    setState(() => _lowStockThreshold.text = (v - 1).clamp(0, 1000000).toString());
                  },
                  onInc: () {
                    final v = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                    final maxStock = int.tryParse(_stock.text.trim()) ?? 0;
                    setState(() => _lowStockThreshold.text = (v + 1).clamp(0, maxStock).toString());
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
          lowStockHelp: _lowStockAlert
              ? (() {
                  final stock = int.tryParse(_stock.text.trim()) ?? 0;
                  final thr = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
                  if (stock > 0 && thr >= stock) {
                    return 'Max threshold cannot exceed stock count.';
                  }
                  return 'Set the stock level that triggers a low stock alert';
                })()
              : null,
          lowStockHelpColor: (() {
            if (!_lowStockAlert) return null;
            final stock = int.tryParse(_stock.text.trim()) ?? 0;
            final thr = int.tryParse(_lowStockThreshold.text.trim()) ?? 0;
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
            width: kSmallControlWidth,
            selected: _expiry != null,
          ),
          expiryHelp: 'Enter the expiry date',

          // Storage
          batchField: Field36(
            child: TextFormField(
              controller: _batch,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'Enter batch number'),
            ),
          ),
          batchHelp: 'Enter the printed batch or lot number',
          locationField: Field36(
            child: TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'eg. Refrigerator'),
            ),
          ),
          locationHelp: 'Where it's stored (e.g., Refrigerator)',
          refrigerateRow: Opacity(
            opacity: _keepFrozen ? 0.5 : 1.0,
            child: Row(children: [
              Checkbox(value: _refrigerate, onChanged: _keepFrozen ? null : (v) => setState(() => _refrigerate = v ?? false)),
              Text('Refrigerate', style: _keepFrozen ? kMutedLabelStyle(context) : Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          refrigerateHelp: 'Enable if this medication must be kept refrigerated',
          freezeRow: Row(children: [
            Checkbox(
                value: _keepFrozen,
                onChanged: (v) => setState(() {
                      _keepFrozen = v ?? false;
                      if (_keepFrozen) _refrigerate = false;
                    })),
            Text('Freeze', style: Theme.of(context).textTheme.bodyMedium),
          ]),
          freezeHelp: 'Enable if this medication must be kept frozen',
          darkRow: Row(children: [
            Checkbox(value: _lightSensitive, onChanged: (v) => setState(() => _lightSensitive = v ?? false)),
            Text('Dark storage', style: Theme.of(context).textTheme.bodyMedium),
          ]),
          darkHelp: 'Enable if this medication must be protected from light',
          storageInstructionsField: Field36(
            child: TextFormField(
              controller: _storageNotes,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _dec(context, hint: 'Enter storage instructions'),
            ),
          ),
          storageInstructionsHelp: 'Special handling notes (e.g., Keep upright)',
        ),
      ),
    );
  }
}