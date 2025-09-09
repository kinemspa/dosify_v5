import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditCapsulePage extends ConsumerStatefulWidget {
  const AddEditCapsulePage({super.key});

  @override
  ConsumerState<AddEditCapsulePage> createState() => _AddEditCapsulePageState();
}

class _AddEditCapsulePageState extends ConsumerState<AddEditCapsulePage> {
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
  final _storageNotesCtrl = TextEditingController();

  bool _summaryExpanded = true;

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
    final parts = <String>['Capsules'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      parts.add('${_strengthValueCtrl.text}$unitLabel per capsule');
    }
    if (_stockValueCtrl.text.isNotEmpty) {
      parts.add('${_stockValueCtrl.text} $stockLabel in stock');
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

  bool _isWhole(num v) => v == v.roundToDouble();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(medicationRepositoryProvider);
    final id = DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0');

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

    await repo.upsert(med);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medication added'),
        content: Text(_buildSummary()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication - Capsule'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      hintText: 'Enter the Medication Name',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _manufacturerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer',
                      hintText: 'Enter the Medication Manufacturer Brand Name',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter the Medication Description',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Enter Notes about the Medication',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),
                  Text('Strength', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _strengthValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Strength *',
                            hintText: 'Enter strength per capsule',
                          ),
                          validator: (v) {
                            final d = double.tryParse(v ?? '');
                            if (d == null) return 'Enter a number';
                            if (d <= 0) return 'Must be > 0';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<Unit>(
                          value: _strengthUnit,
                          items: const [
                            DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                            DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                            DropdownMenuItem(value: Unit.g, child: Text('g')),
                          ],
                          onChanged: (v) => setState(() => _strengthUnit = v!),
                          decoration: const InputDecoration(labelText: 'Unit *'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text('Inventory', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          decoration: const InputDecoration(
                            labelText: 'Stock *',
                            hintText: 'Enter the number in stock',
                          ),
                          validator: (v) {
                            final d = double.tryParse(v ?? '');
                            if (d == null) return 'Enter a number';
                            if (d <= 0) return 'Must be > 0';
                            if (_stockUnit == StockUnit.capsules && !_isWhole(d)) {
                              return 'Capsules must be whole numbers';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<StockUnit>(
                          value: _stockUnit,
                          items: const [
                            DropdownMenuItem(value: StockUnit.capsules, child: Text('capsules')),
                            DropdownMenuItem(value: StockUnit.mcg, child: Text('mcg')),
                            DropdownMenuItem(value: StockUnit.mg, child: Text('mg')),
                            DropdownMenuItem(value: StockUnit.g, child: Text('g')),
                          ],
                          onChanged: (v) => setState(() => _stockUnit = v!),
                          decoration: const InputDecoration(labelText: 'Unit *'),
                        ),
                      ),
                    ],
                  ),

                  SwitchListTile(
                    title: const Text('Low Stock - Enabled/Disabled'),
                    value: _lowStockEnabled,
                    onChanged: (v) => setState(() => _lowStockEnabled = v),
                  ),
                  if (_lowStockEnabled)
                    TextFormField(
                      controller: _lowStockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Low Stock *',
                        hintText: 'Enter the low stock threshold',
                      ),
                      validator: (v) {
                        if (!_lowStockEnabled) return null;
                        final d = double.tryParse(v ?? '');
                        if (d == null) return 'Enter a number';
                        if (d <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),

                  const SizedBox(height: 16),
                  Text('Storage Information', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _batchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Batch No.',
                      hintText: 'Enter the Medication Batch Number',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _storageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Storage',
                      hintText: 'Enter the Storage Location',
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Requires Refrigeration - Enabled/Disabled'),
                    value: _requiresFridge,
                    onChanged: (v) => setState(() => _requiresFridge = v),
                  ),
                  TextFormField(
                    controller: _storageNotesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Storage Instructions',
                      hintText: 'Enter storage instructions',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickExpiry,
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            _expiry == null
                                ? 'No Expiry'
                                : 'Expiry: ${DateFormat.yMd().format(_expiry!)}',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, offset: Offset(0, -2), color: Colors.black12),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _summaryExpanded = !_summaryExpanded),
                        icon: Icon(_summaryExpanded ? Icons.expand_more : Icons.expand_less),
                      ),
                    ],
                  ),
                  if (_summaryExpanded)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_buildSummary()),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

