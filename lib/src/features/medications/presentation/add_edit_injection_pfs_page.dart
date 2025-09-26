import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/form_field_styler.dart';
import '../../../core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditInjectionPfsPage extends ConsumerStatefulWidget {
  const AddEditInjectionPfsPage({super.key, this.initial});
  
  final Medication? initial;

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
  StockUnit _stockUnit = StockUnit.preFilledSyringes;

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();

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
    }
    _loadStylePrefs();
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            children: [
              TextSpan(
                text: _nameCtrl.text,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (_manufacturerCtrl.text.isNotEmpty)
                TextSpan(text: ' from ${_manufacturerCtrl.text}', style: const TextStyle(color: Colors.white)),
              const TextSpan(text: ' PFS.', style: TextStyle(color: Colors.white)),
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
    final id = widget.initial?.id ?? (DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0'));

    final previous = widget.initial;
    final stock = double.parse(_stockValueCtrl.text);
    final initialStock = previous == null
        ? stock
        : (stock > previous.stockValue ? stock : (previous.initialStockValue ?? previous.stockValue));
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
      stockValue: stock,
      stockUnit: StockUnit.preFilledSyringes,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty ? double.parse(_lowStockCtrl.text) : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageNotesCtrl.text.trim().isEmpty ? null : _storageNotesCtrl.text.trim(),
      initialStockValue: initialStock,
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Medication'),
        content: Text(_buildSummary()),
        actionsAlignment: MainAxisAlignment.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Medication - Pre-Filled Syringe' : 'Edit Medication - Pre-Filled Syringe',
        forceBackButton: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 140,
        child: FilledButton.icon(
          onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
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
              const SizedBox(height: 4),
              Text(
                _buildSummary().isEmpty ? 'Summary will update as you type' : _buildSummary(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // General card
              Container(
                decoration: BoxDecoration(
color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('General', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Name *',
                        hint: 'Enter the Medication Name',
                        helper: '',
                      ),
                      validator: (v) => (v==null||v.trim().isEmpty)?'Required':null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _manufacturerCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Manufacturer',
                        hint: 'Enter the Medication Manufacturer Brand Name',
                        helper: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Description',
                        hint: 'Enter the Medication Description',
                        helper: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Notes',
                        hint: 'Enter Notes about the Medication',
                        helper: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Strength card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strength', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _pillBtn(context, '−', () {
                        final v = int.tryParse(_strengthValueCtrl.text) ?? 0;
                        final nv = (v - 1).clamp(0, 1000000);
                        setState(() => _strengthValueCtrl.text = nv.toString());
                      }),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          controller: _strengthValueCtrl,
                          textAlign: TextAlign.center,
keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Strength *',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _pillBtn(context, '+', () {
                        final v = int.tryParse(_strengthValueCtrl.text) ?? 0;
                        final nv = (v + 1).clamp(0, 1000000);
                        setState(() => _strengthValueCtrl.text = nv.toString());
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<Unit>(
                          value: _strengthUnit,
                          isExpanded: true,
                          alignment: AlignmentDirectional.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                          items: const [
                            DropdownMenuItem(value: Unit.mcg, alignment: AlignmentDirectional.center, child: Center(child: Text('mcg', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.mg, alignment: AlignmentDirectional.center, child: Center(child: Text('mg', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.g, alignment: AlignmentDirectional.center, child: Center(child: Text('g', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.units, alignment: AlignmentDirectional.center, child: Center(child: Text('units', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.mcgPerMl, alignment: AlignmentDirectional.center, child: Center(child: Text('mcg/mL', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.mgPerMl, alignment: AlignmentDirectional.center, child: Center(child: Text('mg/mL', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.gPerMl, alignment: AlignmentDirectional.center, child: Center(child: Text('g/mL', textAlign: TextAlign.center))),
                            DropdownMenuItem(value: Unit.unitsPerMl, alignment: AlignmentDirectional.center, child: Center(child: Text('units/mL', textAlign: TextAlign.center))),
                          ],
                          onChanged: (v){ setState(()=>_strengthUnit=v!);},
                          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          decoration: InputDecoration(
                            labelText: 'Unit *',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                          ),
                          menuMaxHeight: 320,
                        ),
                      ),
                    ]),
                    if (_isPerMl)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          width: 160,
                          child: TextFormField(
                            controller: _perMlCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Per mL'),
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inventory', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _pillBtn(context, '−', () {
                        final v = int.tryParse(_stockValueCtrl.text) ?? 0;
                        final nv = (v - 1).clamp(0, 1000000);
                        setState(() => _stockValueCtrl.text = nv.toString());
                      }),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          controller: _stockValueCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          decoration: InputDecoration(
                            labelText: 'Stock *',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _pillBtn(context, '+', () {
                        final v = int.tryParse(_stockValueCtrl.text) ?? 0;
                        final nv = (v + 1).clamp(0, 1000000);
                        setState(() => _stockValueCtrl.text = nv.toString());
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<StockUnit>(
                          value: _stockUnit,
                          isExpanded: true,
                          alignment: AlignmentDirectional.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                          items: const [
                            DropdownMenuItem(
                              value: StockUnit.preFilledSyringes,
                              alignment: AlignmentDirectional.center,
                              child: Center(child: Text('pre filled syringes', textAlign: TextAlign.center)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _stockUnit = v!),
                          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          decoration: InputDecoration(
                            labelText: 'Unit *',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            filled: true,
                          ),
                          menuMaxHeight: 320,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Low Stock Alerts',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Get notified when stock is low',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            ),
                            value: _lowStockEnabled,
                            onChanged: (v) => setState(() => _lowStockEnabled = v ?? false),
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
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Threshold',
                                      hintText: '0',
                                    ),
                                  ),
                                )
                              : const SizedBox(key: ValueKey('lowStockPlaceholder'), width: 120),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(_expiry==null? 'No Expiry' : 'Expiry: ${DateFormat.yMd().format(_expiry!)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickExpiry,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Storage card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Storage Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _batchCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Batch No.',
                        hint: 'Enter the Medication Batch Number',
                        helper: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storageCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Lot / Storage Location',
                        hint: 'Enter the Storage Location',
                        helper: '',
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
                    TextFormField(
                      controller: _storageNotesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FormFieldStyler.decoration(
                        context: context,
                        styleIndex: _formStyleIndex,
                        label: 'Storage Instructions',
                        hint: 'Enter storage instructions',
                        helper: '',
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),

    );
  }
}

