import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/format.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/strength_input.dart';
import '../../../core/prefs/user_prefs.dart';
import '../../../widgets/form_field_styler.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

import '../../medications/domain/enums.dart';
import '../../medications/domain/medication.dart';
import '../presentation/providers.dart';

class AddEditTabletPage extends ConsumerStatefulWidget {
  const AddEditTabletPage({super.key, this.initial});
  
  final Medication? initial;

  @override
  ConsumerState<AddEditTabletPage> createState() => _AddEditTabletPageState();
}

class _AddEditTabletPageState extends ConsumerState<AddEditTabletPage> with TickerProviderStateMixin {
  // Dynamically size the gradient header to match summary content
  final GlobalKey _summaryAreaKey = GlobalKey();
  double _headerHeight = kToolbarHeight + 84;

  void _recalcHeaderHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _summaryAreaKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final desired = kToolbarHeight + box.size.height;
      if ((_headerHeight - desired).abs() > 1) {
        setState(() => _headerHeight = desired);
      }
    });
  }
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _strengthValueCtrl = TextEditingController();
  Unit _strengthUnit = Unit.mg;

  final _stockValueCtrl = TextEditingController();
  StockUnit _stockUnit = StockUnit.tablets;

  bool _lowStockEnabled = false;
  final _lowStockCtrl = TextEditingController();
  String? _stockError;

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();


  int _strengthStyleIndex = 0;
  int _formStyleIndex = 0;

  Future<void> _loadStylePrefs() async {
    final s = await UserPrefs.getStrengthInputStyle();
    final f = await UserPrefs.getFormFieldStyle();
    if (mounted) setState(() { _strengthStyleIndex = s; _formStyleIndex = f; });
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
    // Load style prefs
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
    final parts = <String>['Tablets'];
    if (_nameCtrl.text.isNotEmpty) parts.add(_nameCtrl.text);
    if (_strengthValueCtrl.text.isNotEmpty) {
      parts.add('${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)}$unitLabel per tablet');
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

  Widget _buildStyledSummary() {
    if (_nameCtrl.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Fill in medication details to see summary',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main info row with stock on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and manufacturer
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
                      ],
                    ),
                  ),
                  // Strength info
                  if (_strengthValueCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)} per tablet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Description
                  if (_descriptionCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'For ${_descriptionCtrl.text.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
            // Right side with stock info and indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_stockValueCtrl.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                // Refrigeration and expiry indicators
                if (_requiresFridge || _expiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_requiresFridge)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.ac_unit,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        if (_expiry != null && _requiresFridge)
                          const SizedBox(height: 2),
                        if (_expiry != null)
                          Text(
                            DateFormat('MMM yy').format(_expiry!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Additional info if present
        if (_notesCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _notesCtrl.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.white60,
              ),
            ),
          ),
        if (_lowStockEnabled && _lowStockCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  'Low stock alert at ${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
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
        return u.name; // not expected for tablets
    }
  }

  String _stockUnitLabel(StockUnit s) {
    switch (s) {
      case StockUnit.tablets:
        return 'tablets';
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

  bool _isQuarter(double v) {
    final frac = (v * 4).round() / 4.0;
    return (v - frac).abs() < 1e-8;
  }

  bool _isExpiringSoon() {
    if (_expiry == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = _expiry!.difference(now).inDays;
    return daysUntilExpiry <= 30;
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(medicationRepositoryProvider);

    final id = widget.initial?.id ?? (DateTime.now().microsecondsSinceEpoch.toString() +
        Random().nextInt(9999).toString().padLeft(4, '0'));

    final med = Medication(
      id: id,
      form: MedicationForm.tablet,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Confirm Medication',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Styled summary preview block
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF09A8BD), Color(0xFF18537D)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                _buildSummary(),
                style: const TextStyle(color: Colors.white, height: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            // Full details list
            _detailRow('Form', 'Tablet'),
            _detailRow('Name', _nameCtrl.text.trim()),
            if (_manufacturerCtrl.text.trim().isNotEmpty) _detailRow('Manufacturer', _manufacturerCtrl.text.trim()),
            _detailRow('Strength', '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)}'),
            _detailRow('Stock', '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}'),
            if (_lowStockEnabled && _lowStockCtrl.text.isNotEmpty) _detailRow('Low stock at', '${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}'),
            _detailRow('Expiry', _expiry != null ? DateTime.now().isAfter(_expiry!) ? 'Expired' : '${_expiry!.day}/${_expiry!.month}/${_expiry!.year}' : 'No expiry'),
            if (_batchCtrl.text.trim().isNotEmpty) _detailRow('Batch #', _batchCtrl.text.trim()),
            if (_storageCtrl.text.trim().isNotEmpty) _detailRow('Storage', _storageCtrl.text.trim()),
            _detailRow('Requires refrigeration', _requiresFridge ? 'Yes' : 'No'),
            if (_storageNotesCtrl.text.trim().isNotEmpty) _detailRow('Storage notes', _storageNotesCtrl.text.trim()),
            if (_descriptionCtrl.text.trim().isNotEmpty) _detailRow('Description', _descriptionCtrl.text.trim()),
            if (_notesCtrl.text.trim().isNotEmpty) _detailRow('Notes', _notesCtrl.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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
    // Lock layout to avoid vertical shifting of the header while typing
    final headerHeight = kToolbarHeight + 128;
    return Scaffold(
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Medication - Tablet' : 'Edit Medication - Tablet',
        forceBackButton: true,
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
              // General
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
                        hint: 'e.g., Panadol',
                        helper: 'Enter the medication name',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                        hint: 'e.g., GlaxoSmithKline',
                        helper: 'Enter the brand or company name',
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
                        hint: 'e.g., Pain relief',
                        helper: 'What is this medication used for?',
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
                        hint: 'e.g., Take with food',
                        helper: 'Additional notes or instructions',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Strength (hybrid-style controls)
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
                    // Strength Value row with +/- and centered number
                    Row(
                      children: [
                        _pillBtn(context, '−', () {
                          final raw = _strengthValueCtrl.text.trim();
                          final d = double.tryParse(raw);
                          final base = d?.floor() ?? 0;
                          final nv = (base - 1).clamp(0, 1000000000);
                          setState(() => _strengthValueCtrl.text = nv.toString());
                        }),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _strengthValueCtrl,
                            onChanged: (_) => setState(() {}),
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Amount *',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              constraints: const BoxConstraints(minHeight: 40),
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
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pillBtn(context, '+', () {
                          final raw = _strengthValueCtrl.text.trim();
                          final d = double.tryParse(raw);
                          final base = d?.floor() ?? 0;
                          final nv = (base + 1).clamp(0, 1000000000);
                          setState(() => _strengthValueCtrl.text = nv.toString());
                        }),
                        const SizedBox(width: 12),
                        // Strength Unit dropdown
                        Expanded(
                          child: DropdownButtonFormField<Unit>(
                            value: _strengthUnit,
                            isExpanded: true,
                            alignment: AlignmentDirectional.center,
                            items: const [Unit.mcg, Unit.mg, Unit.g]
                                .map((u) => DropdownMenuItem<Unit>(
                                      value: u,
                                      alignment: AlignmentDirectional.center,
                                      child: Center(child: Text(u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'))),
                                    ))
                                .toList(),
                            onChanged: (u) => setState(() => _strengthUnit = u ?? _strengthUnit),
                            decoration: const InputDecoration(labelText: 'Unit *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the strength per tablet and select the appropriate unit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Inventory
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
                        // Pill group style for Stock input
                        _pillBtn(context, '−', () {
                          final v = double.tryParse(_stockValueCtrl.text) ?? 0;
                          final nv = (v - 0.25).clamp(0, 1000000);
                          setState(() => _stockValueCtrl.text = nv.toStringAsFixed(2));
                        }),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _stockValueCtrl,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^$|^\d{0,7}(?:\.\d{0,2})?$'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Stock *',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              constraints: const BoxConstraints(minHeight: 40),
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
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              setState(() {
                                if (d == null || _isQuarter(d)) {
                                  _stockError = null;
                                } else {
                                  _stockError = 'Stock should be .00, .25, .50 or .75';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        _pillBtn(context, '+', () {
                          final v = double.tryParse(_stockValueCtrl.text) ?? 0;
                          final nv = (v + 0.25).clamp(0, 1000000);
                          setState(() => _stockValueCtrl.text = nv.toStringAsFixed(2));
                        }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<StockUnit>(
                            value: StockUnit.tablets,
                            isExpanded: true,
                            alignment: AlignmentDirectional.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                            items: const [
                              DropdownMenuItem(
                                value: StockUnit.tablets,
                                alignment: AlignmentDirectional.center,
                                child: Center(child: Text('tablets', textAlign: TextAlign.center)),
                              ),
                            ],
                            onChanged: null,
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
                    if (_stockError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _stockError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter current stock quantity and select the unit of measurement',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Expiry button (40px tall) with date on button
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiry,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(
                          _expiry == null ? 'Pick expiry date' : DateFormat.yMd().format(_expiry!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Low stock alerts inside the Inventory card
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
              // Storage Info
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // (Expiry moved under Inventory)

              const SizedBox(height: 16),
              // Save button (40px height, not full width)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: Text(widget.initial == null ? 'Save' : 'Update'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

