import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/strength_input.dart';
import '../../../widgets/form_field_styler.dart';
import '../../../core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditCapsulePage extends ConsumerStatefulWidget {
  const AddEditCapsulePage({super.key, this.initial});
  
  final Medication? initial;

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

  int _formStyleIndex = 0;

  Future<void> _loadStylePrefs() async {
    final f = await UserPrefs.getFormFieldStyle();
    if (mounted) setState(() => _formStyleIndex = f);
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
    final parts = <String>['Capsules'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      parts.add('${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unitLabel per capsule');
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  children: [
                    TextSpan(
                      text: _nameCtrl.text,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (_manufacturerCtrl.text.isNotEmpty)
                      TextSpan(text: ' from ${_manufacturerCtrl.text}', style: const TextStyle(color: Colors.white)),
                    const TextSpan(text: '.', style: TextStyle(color: Colors.white)),
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
            child: Icon(
              Icons.ac_unit,
              size: 20,
              color: Colors.blue.shade700,
            ),
          ),
      ],
    );
  }

  bool _isWhole(num v) => v == v.roundToDouble();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(medicationRepositoryProvider);
    final id = widget.initial?.id ?? (DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0'));

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
        title: widget.initial == null ? 'Add Medication - Capsule' : 'Edit Medication - Capsule',
        forceBackButton: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
        backgroundColor: _nameCtrl.text.trim().isNotEmpty ? const Color(0xFF09A8BD) : Colors.grey,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: Text(widget.initial == null ? 'Save' : 'Update'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.all(16),
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
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                    StrengthInput(
                      controller: _strengthValueCtrl,
                      unit: _strengthUnit,
                      onUnitChanged: (u) => setState(() => _strengthUnit = u),
                      styleIndex: 6,
                      labelAmount: 'Amount *',
                      labelUnit: 'Unit *',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the strength per capsule and select the appropriate unit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Inventory card
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
                    Row(
                      children: [
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
                                value: StockUnit.capsules,
                                alignment: AlignmentDirectional.center,
                                child: Center(child: Text('capsules', textAlign: TextAlign.center)),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter current stock quantity and select the unit of measurement',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Expiry inside Inventory
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(_expiry == null ? 'No Expiry' : 'Expiry: ${DateFormat.yMd().format(_expiry!)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: _pickExpiry,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 8),
                    // Low Stock inside Inventory
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Storage Information card
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

