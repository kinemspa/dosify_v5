import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

class AddEditTabletDetailsStylePage extends StatefulWidget {
  const AddEditTabletDetailsStylePage({super.key, this.initial});
  final Medication? initial;

  @override
  State<AddEditTabletDetailsStylePage> createState() =>
      _AddEditTabletDetailsStylePageState();
}

class _AddEditTabletDetailsStylePageState
    extends State<AddEditTabletDetailsStylePage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _manufacturer = '';
  String _description = '';
  String _notes = '';

  double? _strengthValue;
  Unit _strengthUnit = Unit.mg;

  double? _stockValue;
  StockUnit _stockUnit = StockUnit.tablets;

  bool _lowStockEnabled = false;
  double? _lowStockThreshold;

  DateTime? _expiry;
  String _batch = '';
  String _storageLocation = '';
  bool _requiresFridge = false;
  String _storageInstructions = '';

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _name = m.name;
      _manufacturer = m.manufacturer ?? '';
      _description = m.description ?? '';
      _notes = m.notes ?? '';
      _strengthValue = m.strengthValue;
      _strengthUnit = m.strengthUnit;
      _stockValue = m.stockValue;
      _stockUnit = m.stockUnit;
      _lowStockEnabled = m.lowStockEnabled;
      _lowStockThreshold = m.lowStockThreshold;
      _expiry = m.expiry;
      _batch = m.batchNumber ?? '';
      _storageLocation = m.storageLocation ?? '';
      _requiresFridge = m.requiresRefrigeration;
      _storageInstructions = m.storageInstructions ?? '';
    }
  }

  Future<void> _save() async {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (_strengthValue == null || _strengthValue! <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter strength value')));
      return;
    }
    if (_stockValue == null || _stockValue! < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter stock value')));
      return;
    }

    final med = Medication(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      form: MedicationForm.tablet,
      name: _name.trim(),
      manufacturer: _manufacturer.trim().isEmpty ? null : _manufacturer.trim(),
      description: _description.trim().isEmpty ? null : _description.trim(),
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
      strengthValue: _strengthValue!,
      strengthUnit: _strengthUnit,
      perMlValue: null,
      stockValue: _stockValue!,
      stockUnit: _stockUnit,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled ? _lowStockThreshold : null,
      expiry: _expiry,
      batchNumber: _batch.trim().isEmpty ? null : _batch.trim(),
      storageLocation: _storageLocation.trim().isEmpty
          ? null
          : _storageLocation.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageInstructions.trim().isEmpty
          ? null
          : _storageInstructions.trim(),
    );

    final box = Hive.box<Medication>('medications');
    await box.put(med.id, med);
    if (!mounted) return;
    context.go('/medications');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.initial == null
              ? 'Added "${med.name}"'
              : 'Updated "${med.name}"',
        ),
      ),
    );
  }

  Future<void> _editText({
    required String title,
    required String initial,
    required ValueChanged<String> onSaved,
    TextInputType? keyboardType,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: const InputDecoration(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) setState(() => onSaved(ctrl.text));
  }

  Future<void> _editNumber({
    required String title,
    required double? initial,
    required ValueChanged<double?> onSaved,
  }) async {
    final ctrl = TextEditingController(
      text: initial != null
          ? (initial == initial.roundToDouble()
                ? initial.toStringAsFixed(0)
                : initial.toString())
          : '',
    );
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) setState(() => onSaved(double.tryParse(ctrl.text.trim())));
  }

  Future<void> _editEnum<T>({
    required String title,
    required T selected,
    required List<(T, String)> options,
    required ValueChanged<T> onSaved,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in options)
              ListTile(
                title: Text(label, textAlign: TextAlign.center),
                selected: value == selected,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => onSaved(result));
  }

  Future<void> _pickDate({
    required String title,
    required DateTime? initial,
    required ValueChanged<DateTime?> onSaved,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      initialDate: initial ?? now,
      helpText: title,
    );
    if (picked != null) setState(() => onSaved(picked));
  }

  Widget _row(String label, String value, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (onTap != null) const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String fmt2(double? v) {
      if (v == null) return '-';
      return v == v.roundToDouble()
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(2);
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null
            ? 'Add Medication (Details-style)'
            : 'Edit Medication (Details-style)',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'standard') {
                if (widget.initial == null) {
                  context.push('/medications/add/tablet');
                } else {
                  context.push(
                    '/medications/edit/tablet/${widget.initial!.id}',
                  );
                }
              } else if (value == 'hybrid') {
                if (widget.initial == null) {
                  context.push('/medications/add/tablet/hybrid');
                } else {
                  context.push(
                    '/medications/edit/tablet/hybrid/${widget.initial!.id}',
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'standard',
                child: Text('Open standard editor'),
              ),
              const PopupMenuItem<String>(
                value: 'hybrid',
                child: Text('Open hybrid editor'),
              ),
            ],
          ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(context, 'General', [
              _row(
                'Name',
                _name,
                onTap: () => _editText(
                  title: 'Name',
                  initial: _name,
                  onSaved: (v) => _name = v,
                ),
              ),
              _row('Medication Type', 'Tablet'),
              _row(
                'Manufacturer',
                _manufacturer,
                onTap: () => _editText(
                  title: 'Manufacturer',
                  initial: _manufacturer,
                  onSaved: (v) => _manufacturer = v,
                ),
              ),
              _row(
                'Description',
                _description,
                onTap: () => _editText(
                  title: 'Description',
                  initial: _description,
                  onSaved: (v) => _description = v,
                ),
              ),
              _row(
                'Notes',
                _notes,
                onTap: () => _editText(
                  title: 'Notes',
                  initial: _notes,
                  onSaved: (v) => _notes = v,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Strength & Composition', [
              _row(
                'Strength Value',
                fmt2(_strengthValue),
                onTap: () => _editNumber(
                  title: 'Strength Value',
                  initial: _strengthValue,
                  onSaved: (v) => _strengthValue = v,
                ),
              ),
              _row(
                'Strength Unit',
                switch (_strengthUnit) {
                  Unit.mcg => 'mcg',
                  Unit.mg => 'mg',
                  Unit.g => 'g',
                  Unit.units => 'units',
                  Unit.mcgPerMl => 'mcg/mL',
                  Unit.mgPerMl => 'mg/mL',
                  Unit.gPerMl => 'g/mL',
                  Unit.unitsPerMl => 'units/mL',
                },
                onTap: () => _editEnum<Unit>(
                  title: 'Strength Unit',
                  selected: _strengthUnit,
                  options: const [
                    (Unit.mcg, 'mcg'),
                    (Unit.mg, 'mg'),
                    (Unit.g, 'g'),
                  ],
                  onSaved: (u) => _strengthUnit = u,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Inventory', [
              _row(
                'Stock Value',
                fmt2(_stockValue),
                onTap: () => _editNumber(
                  title: 'Stock Value',
                  initial: _stockValue,
                  onSaved: (v) => _stockValue = v,
                ),
              ),
              _row(
                'Stock Unit',
                switch (_stockUnit) {
                  StockUnit.tablets => 'tablets',
                  StockUnit.capsules => 'capsules',
                  StockUnit.preFilledSyringes => 'pre filled syringes',
                  StockUnit.singleDoseVials => 'single dose vials',
                  StockUnit.multiDoseVials => 'multi dose vials',
                  StockUnit.mcg => 'mcg',
                  StockUnit.mg => 'mg',
                  StockUnit.g => 'g',
                },
                onTap: () => _editEnum<StockUnit>(
                  title: 'Stock Unit',
                  selected: _stockUnit,
                  options: const [
                    (StockUnit.tablets, 'tablets'),
                    (StockUnit.mcg, 'mcg'),
                    (StockUnit.mg, 'mg'),
                    (StockUnit.g, 'g'),
                  ],
                  onSaved: (v) => _stockUnit = v,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Low stock alerts'),
                value: _lowStockEnabled,
                onChanged: (v) => setState(() => _lowStockEnabled = v),
              ),
              if (_lowStockEnabled)
                _row(
                  'Low stock threshold',
                  fmt2(_lowStockThreshold),
                  onTap: () => _editNumber(
                    title: 'Low stock threshold',
                    initial: _lowStockThreshold,
                    onSaved: (v) => _lowStockThreshold = v,
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Storage', [
              _row(
                'Expiry',
                _expiry != null ? DateFormat('dd/MM/yy').format(_expiry!) : '-',
                onTap: () => _pickDate(
                  title: 'Expiry',
                  initial: _expiry,
                  onSaved: (d) => _expiry = d,
                ),
              ),
              _row(
                'Batch',
                _batch,
                onTap: () => _editText(
                  title: 'Batch',
                  initial: _batch,
                  onSaved: (v) => _batch = v,
                ),
              ),
              _row(
                'Storage location',
                _storageLocation,
                onTap: () => _editText(
                  title: 'Storage location',
                  initial: _storageLocation,
                  onSaved: (v) => _storageLocation = v,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Requires refrigeration'),
                value: _requiresFridge,
                onChanged: (v) => setState(() => _requiresFridge = v),
              ),
              _row(
                'Storage instructions',
                _storageInstructions,
                onTap: () => _editText(
                  title: 'Storage instructions',
                  initial: _storageInstructions,
                  onSaved: (v) => _storageInstructions = v,
                ),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ),
    );
  }
}

Widget _section(BuildContext context, String title, List<Widget> children) {
  final theme = Theme.of(context);
  return Card(
    elevation: 0,
    color: theme.colorScheme.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );
}
