import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'providers.dart';

enum InjectionKind { pfs, single, multi }

class AddEditInjectionUnifiedPage extends ConsumerStatefulWidget {
  const AddEditInjectionUnifiedPage({
    super.key,
    required this.kind,
    this.initial,
  });
  final InjectionKind kind;
  final Medication? initial;

  @override
  ConsumerState<AddEditInjectionUnifiedPage> createState() =>
      _AddEditInjectionUnifiedPageState();
}

class _AddEditInjectionUnifiedPageState
    extends ConsumerState<AddEditInjectionUnifiedPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _manufacturer = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  final _strength = TextEditingController(text: '0');
  Unit _strengthUnit = Unit.mg;
  final _perMl = TextEditingController();

  final _stock = TextEditingController(text: '0');
  StockUnit _stockUnit = StockUnit.preFilledSyringes;

  DateTime? _expiry;
  final _batch = TextEditingController();
  final _location = TextEditingController();
  bool _refrigerate = false;
  final _storageNotes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _name.text = m.name;
      _manufacturer.text = m.manufacturer ?? '';
      _description.text = m.description ?? '';
      _notes.text = m.notes ?? '';
      _strength.text = m.strengthValue.toString();
      _strengthUnit = m.strengthUnit;
      _perMl.text = m.perMlValue?.toString() ?? '';
      _stock.text = m.stockValue.toString();
      _stockUnit = m.stockUnit;
      _expiry = m.expiry;
      _batch.text = m.batchNumber ?? '';
      _location.text = m.storageLocation ?? '';
      _refrigerate = m.requiresRefrigeration;
      _storageNotes.text = m.storageInstructions ?? '';
    } else {
      // Default units per kind
      switch (widget.kind) {
        case InjectionKind.pfs:
          _stockUnit = StockUnit.preFilledSyringes;
          break;
        case InjectionKind.single:
          _stockUnit = StockUnit.singleDoseVials;
          break;
        case InjectionKind.multi:
          _stockUnit = StockUnit.multiDoseVials;
          break;
      }
    }
  }

  InputDecoration _dec(BuildContext context, String label, String? hint) {
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
    final title = switch (widget.kind) {
      InjectionKind.pfs => 'Add Medication - Pre-Filled Syringe',
      InjectionKind.single => 'Add Medication - Single Dose Vial',
      InjectionKind.multi => 'Add Medication - Multi Dose Vial',
    };

    final saveEnabled = (() {
      final nameOk = _name.text.trim().isNotEmpty;
      final a = double.tryParse(_strength.text.trim());
      final amtOk = a != null && a > 0;
      final s = double.tryParse(_stock.text.trim());
      final stockOk = s != null && s >= 0;
      return nameOk && amtOk && stockOk;
    })();

    return Scaffold(
      appBar: GradientAppBar(title: title, forceBackButton: true),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 140,
        child: FilledButton.icon(
          onPressed: saveEnabled ? _submit : null,
          icon: const Icon(Icons.save),
          label: Text(widget.initial == null ? 'Save' : 'Update'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionFormCard(
                title: 'General',
                children: [
                  LabelFieldRow(
                    label: 'Name *',
                    field: Field36(
                      child: TextFormField(
                        controller: _name,
                        decoration: _dec(context, 'Name *', 'eg. AcmeTab-500'),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Manufacturer',
                    field: Field36(
                      child: TextFormField(
                        controller: _manufacturer,
                        decoration: _dec(
                          context,
                          'Manufacturer',
                          'eg. Contoso Pharma',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Description',
                    field: Field36(
                      child: TextFormField(
                        controller: _description,
                        decoration: _dec(
                          context,
                          'Description',
                          'eg. Pain relief',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Notes',
                    field: Field36(
                      child: TextFormField(
                        controller: _notes,
                        decoration: _dec(
                          context,
                          'Notes',
                          'eg. Take with food',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Strength',
                children: [
                  LabelFieldRow(
                    label: 'Strength *',
                    field: StepperRow36(
                      controller: _strength,
                      onDec: () {
                        final v = int.tryParse(_strength.text) ?? 0;
                        _strength.text = (v - 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      onInc: () {
                        final v = int.tryParse(_strength.text) ?? 0;
                        _strength.text = (v + 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      decoration: _dec(context, 'Strength *', '0'),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Unit *',
                    field: SmallDropdown36<Unit>(
                      value: _strengthUnit,
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
                      onChanged: (v) =>
                          setState(() => _strengthUnit = v ?? Unit.mg),
                      decoration: _dec(context, 'Unit *', null),
                    ),
                  ),
                  if (_strengthUnit == Unit.mcgPerMl ||
                      _strengthUnit == Unit.mgPerMl ||
                      _strengthUnit == Unit.gPerMl ||
                      _strengthUnit == Unit.unitsPerMl)
                    LabelFieldRow(
                      label: 'Per mL',
                      field: SizedBox(
                        width: 160,
                        child: Field36(
                          child: TextFormField(
                            controller: _perMl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _dec(context, 'Per mL', '0.0'),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: kLabelColWidth + 8),
                    child: Text(
                      'Specify the amount per dose and its unit of measurement.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Inventory',
                children: [
                  LabelFieldRow(
                    label: 'Stock quantity *',
                    field: StepperRow36(
                      controller: _stock,
                      onDec: () {
                        final v = int.tryParse(_stock.text) ?? 0;
                        _stock.text = (v - 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      onInc: () {
                        final v = int.tryParse(_stock.text) ?? 0;
                        _stock.text = (v + 1).clamp(0, 1000000).toString();
                        setState(() {});
                      },
                      decoration: _dec(context, 'Stock quantity *', '0'),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Quantity unit',
                    field: SmallDropdown36<StockUnit>(
                      value: _stockUnit,
                      items: [
                        DropdownMenuItem(
                          value: StockUnit.preFilledSyringes,
                          child: Center(child: Text('pre filled syringes')),
                        ),
                        DropdownMenuItem(
                          value: StockUnit.singleDoseVials,
                          child: Center(child: Text('single dose vials')),
                        ),
                        DropdownMenuItem(
                          value: StockUnit.multiDoseVials,
                          child: Center(child: Text('multi dose vials')),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _stockUnit = v ?? _stockUnit),
                      decoration: _dec(context, 'Quantity unit', null),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: kLabelColWidth + 8),
                    child: Text(
                      'Get notified when stock is low',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabelFieldRow(
                    label: 'Expiry date',
                    field: DateButton36(
                      label: _expiry == null
                          ? 'Select date'
                          : DateFormat.yMd().format(_expiry!),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SectionFormCard(
                title: 'Storage Information',
                children: [
                  LabelFieldRow(
                    label: 'Batch No.',
                    field: Field36(
                      child: TextFormField(
                        controller: _batch,
                        decoration: _dec(
                          context,
                          'Batch No.',
                          'Enter batch number',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Location',
                    field: Field36(
                      child: TextFormField(
                        controller: _location,
                        decoration: _dec(
                          context,
                          'Location',
                          'eg. Bathroom cabinet',
                        ),
                      ),
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Keep refrigerated',
                    field: Row(
                      children: [
                        Checkbox(
                          value: _refrigerate,
                          onChanged: (v) =>
                              setState(() => _refrigerate = v ?? false),
                        ),
                        const Text('Refrigerate'),
                      ],
                    ),
                  ),
                  LabelFieldRow(
                    label: 'Storage instructions',
                    field: Field36(
                      child: TextFormField(
                        controller: _storageNotes,
                        decoration: _dec(
                          context,
                          'Storage instructions',
                          'Enter storage instructions',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(medicationRepositoryProvider);
    final id =
        widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final stock = double.tryParse(_stock.text.trim()) ?? 0;
    final previous = widget.initial;
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue
              ? stock
              : (previous.initialStockValue ?? previous.stockValue));

    final med = Medication(
      id: id,
      form: switch (widget.kind) {
        InjectionKind.pfs => MedicationForm.injectionPreFilledSyringe,
        InjectionKind.single => MedicationForm.injectionSingleDoseVial,
        InjectionKind.multi => MedicationForm.injectionMultiDoseVial,
      },
      name: _name.text.trim(),
      manufacturer: _manufacturer.text.trim().isEmpty
          ? null
          : _manufacturer.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      strengthValue: double.tryParse(_strength.text) ?? 0,
      strengthUnit: _strengthUnit,
      perMlValue: _perMl.text.trim().isEmpty
          ? null
          : double.tryParse(_perMl.text.trim()),
      stockValue: stock,
      stockUnit: _stockUnit,
      expiry: _expiry,
      batchNumber: _batch.text.trim().isEmpty ? null : _batch.text.trim(),
      storageLocation: _location.text.trim().isEmpty
          ? null
          : _location.text.trim(),
      requiresRefrigeration: _refrigerate,
      storageInstructions: _storageNotes.text.trim().isEmpty
          ? null
          : _storageNotes.text.trim(),
      initialStockValue: initialStock,
    );

    await repo.upsert(med);
    if (!mounted) return;
    context.go('/medications');
  }
}
