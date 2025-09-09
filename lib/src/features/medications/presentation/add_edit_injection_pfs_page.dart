import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditInjectionPfsPage extends ConsumerStatefulWidget {
  const AddEditInjectionPfsPage({super.key});

  @override
  ConsumerState<AddEditInjectionPfsPage> createState() => _AddEditInjectionPfsPageState();
}

class _AddEditInjectionPfsPageState extends ConsumerState<AddEditInjectionPfsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;
  final _perMlCtrl = TextEditingController();

  final _stockValueCtrl = TextEditingController();

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();

  bool _summaryExpanded = true;

  bool get _isPerMl => {
        Unit.mcgPerMl,
        Unit.mgPerMl,
        Unit.gPerMl,
        Unit.unitsPerMl,
      }.contains(_strengthUnit);

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
    super.dispose();
  }

  String _unitLabel(Unit u) =>
      {Unit.mcg: 'mcg', Unit.mg: 'mg', Unit.g: 'g', Unit.units: 'units', Unit.mcgPerMl: 'mcg/mL', Unit.mgPerMl: 'mg/mL', Unit.gPerMl: 'g/mL', Unit.unitsPerMl: 'units/mL'}[u]!;

  String _buildSummary() {
    final parts = <String>['Pre Filled Syringe'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      final unit = _unitLabel(_strengthUnit);
      if (_isPerMl && _perMlCtrl.text.isNotEmpty) {
        parts.add('${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unit, ${fmt2(double.tryParse(_perMlCtrl.text) ?? 0)} mL');
      } else {
        parts.add('${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unit');
      }
    }
    if (_stockValueCtrl.text.isNotEmpty) parts.add('${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} pre filled syringes in stock');
    if (_manufacturerCtrl.text.isNotEmpty) parts.add(_manufacturerCtrl.text);
    if (_requiresFridge) parts.add('Keep refrigerated');
    if (_expiry != null) parts.add('Expires - ${DateFormat.yMd().format(_expiry!)}');
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(medicationRepositoryProvider);
    final id = DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0');

    final med = Medication(
      id: id,
      form: MedicationForm.injectionPreFilledSyringe,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      strengthValue: double.parse(_strengthValueCtrl.text),
      strengthUnit: _strengthUnit,
      perMlValue: _isPerMl && _perMlCtrl.text.isNotEmpty ? double.parse(_perMlCtrl.text) : null,
      stockValue: double.parse(_stockValueCtrl.text),
      stockUnit: StockUnit.preFilledSyringes,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty ? double.parse(_lowStockCtrl.text) : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageNotesCtrl.text.trim().isEmpty ? null : _storageNotesCtrl.text.trim(),
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Medication'),
        content: Text(_buildSummary()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.upsert(med);
      if (!mounted) return;
      context.go('/medications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Add Medication - Pre Filled Syringe')),
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
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *'), validator: (v) => (v==null||v.trim().isEmpty)?'Required':null, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextFormField(controller: _manufacturerCtrl, decoration: const InputDecoration(labelText: 'Manufacturer'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 8),
                  TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), onChanged: (_) => setState(() {})),

                  const SizedBox(height: 16),
                  Text('Strength', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _strengthValueCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Strength *'), validator: (v){ final d=double.tryParse(v??''); if(d==null||d<=0) return 'Enter > 0'; return null;}, onChanged: (_)=>setState((){}))),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<Unit>(value: _strengthUnit, items: const [
                      DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                      DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                      DropdownMenuItem(value: Unit.g, child: Text('g')),
                      DropdownMenuItem(value: Unit.units, child: Text('units')),
                      DropdownMenuItem(value: Unit.mcgPerMl, child: Text('mcg/mL')),
                      DropdownMenuItem(value: Unit.mgPerMl, child: Text('mg/mL')),
                      DropdownMenuItem(value: Unit.gPerMl, child: Text('g/mL')),
                      DropdownMenuItem(value: Unit.unitsPerMl, child: Text('units/mL')),
                    ], onChanged: (v){ setState(()=>_strengthUnit=v!);}, decoration: const InputDecoration(labelText: 'Unit *'))),
                  ]),
                  if (_isPerMl)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(controller: _perMlCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Per mL'), validator: (v){ if(!_isPerMl) return null; final d=double.tryParse(v??''); if(d==null||d<=0) return 'Enter > 0'; return null; }),
                    ),

                  const SizedBox(height: 16),
                  Text('Inventory', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _stockValueCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: false), decoration: const InputDecoration(labelText: 'Syringes in stock *'), validator: (v){ final d=double.tryParse(v??''); if(d==null||d<=0) return 'Enter > 0'; if(d!=d.roundToDouble()) return 'Must be whole numbers'; return null; })),
                    const SizedBox(width: 12),
                    const Expanded(child: TextField(enabled: false, decoration: InputDecoration(labelText: 'Unit', hintText: 'pre filled syringes'))),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Tip: Long explanations show here below the field so they don\'t get truncated.'),

                  SwitchListTile(title: const Text('Low Stock - Enabled/Disabled'), value: _lowStockEnabled, onChanged: (v)=>setState(()=>_lowStockEnabled=v)),
                  if (_lowStockEnabled)
                    TextFormField(controller: _lowStockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Low Stock *')),

                  const SizedBox(height: 16),
                  Text('Storage Information', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(controller: _batchCtrl, decoration: const InputDecoration(labelText: 'Batch No.')),
TextFormField(controller: _storageCtrl, decoration: const InputDecoration(labelText: 'Lot / Storage Location')),
                  SwitchListTile(title: const Text('Requires Refrigeration - Enabled/Disabled'), value: _requiresFridge, onChanged: (v)=>setState(()=>_requiresFridge=v)),
                  TextFormField(controller: _storageNotesCtrl, decoration: const InputDecoration(labelText: 'Storage Instructions')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(onPressed: _pickExpiry, icon: const Icon(Icons.calendar_month), label: Text(_expiry==null? 'No Expiry' : 'Expiry: ${DateFormat.yMd().format(_expiry!)}')),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor)), boxShadow: const [BoxShadow(blurRadius: 4, offset: Offset(0,-2), color: Colors.black12)]),
              padding: const EdgeInsets.fromLTRB(16,12,16,16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('Summary', style: Theme.of(context).textTheme.titleMedium)), IconButton(onPressed: ()=>setState(()=>_summaryExpanded=!_summaryExpanded), icon: Icon(_summaryExpanded? Icons.expand_more: Icons.expand_less))]),
                if (_summaryExpanded) Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(_buildSummary())),
                Row(children: [Expanded(child: FilledButton(onPressed: _submit, child: const Text('Submit')))]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

