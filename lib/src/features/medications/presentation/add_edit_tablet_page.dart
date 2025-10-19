// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:dosifi_v5/src/core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class AddEditTabletPage extends ConsumerStatefulWidget {
  const AddEditTabletPage({super.key, this.initial});

  final Medication? initial;

  @override
  ConsumerState<AddEditTabletPage> createState() => _AddEditTabletPageState();
}

class _AddEditTabletPageState extends ConsumerState<AddEditTabletPage>
    with TickerProviderStateMixin {
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

  DateTime? _expiry;
  final _batchCtrl = TextEditingController();
  final _storageCtrl = TextEditingController();
  bool _requiresFridge = false;
  final _storageNotesCtrl = TextEditingController();

  Future<void> _loadStylePrefs() async {
    await UserPrefs.getStrengthInputStyle();
    await UserPrefs.getFormFieldStyle();
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ),
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
      form: MedicationForm.tablet,
      name: _nameCtrl.text.trim(),
      manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      strengthValue: double.parse(_strengthValueCtrl.text),
      strengthUnit: _strengthUnit,
      stockValue: stock,
      stockUnit: _stockUnit,
      lowStockEnabled: _lowStockEnabled,
      lowStockThreshold: _lowStockEnabled && _lowStockCtrl.text.isNotEmpty
          ? double.parse(_lowStockCtrl.text)
          : null,
      expiry: _expiry,
      batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
      storageLocation: _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      requiresRefrigeration: _requiresFridge,
      storageInstructions: _storageNotesCtrl.text.trim().isEmpty
          ? null
          : _storageNotesCtrl.text.trim(),
      initialStockValue: initialStock,
    );

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            if (_manufacturerCtrl.text.trim().isNotEmpty)
              _detailRow('Manufacturer', _manufacturerCtrl.text.trim()),
            _detailRow(
              'Strength',
              '${fmt2(double.tryParse(_strengthValueCtrl.text) ?? 0)} ${_unitLabel(_strengthUnit)}',
            ),
            _detailRow(
              'Stock',
              '${fmt2(double.tryParse(_stockValueCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
            ),
            if (_lowStockEnabled && _lowStockCtrl.text.isNotEmpty)
              _detailRow(
                'Low stock at',
                '${fmt2(double.tryParse(_lowStockCtrl.text) ?? 0)} ${_stockUnitLabel(_stockUnit)}',
              ),
            _detailRow(
              'Expiry',
              _expiry != null
                  ? DateTime.now().isAfter(_expiry!)
                        ? 'Expired'
                        : '${_expiry!.day}/${_expiry!.month}/${_expiry!.year}'
                  : 'No expiry',
            ),
            if (_batchCtrl.text.trim().isNotEmpty) _detailRow('Batch #', _batchCtrl.text.trim()),
            if (_storageCtrl.text.trim().isNotEmpty)
              _detailRow('Storage', _storageCtrl.text.trim()),
            _detailRow('Requires refrigeration', _requiresFridge ? 'Yes' : 'No'),
            if (_storageNotesCtrl.text.trim().isNotEmpty)
              _detailRow('Storage notes', _storageNotesCtrl.text.trim()),
            if (_descriptionCtrl.text.trim().isNotEmpty)
              _detailRow('Description', _descriptionCtrl.text.trim()),
            if (_notesCtrl.text.trim().isNotEmpty) _detailRow('Notes', _notesCtrl.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await repo.upsert(med);
      if (!mounted) return;
      context.go('/medications');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[TABLET] build() called, initial=${widget.initial != null}');
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        appBar: GradientAppBar(
          title: widget.initial == null
              ? 'Add Medication - Tablet [HYBRID]'
              : 'Edit Medication - Tablet [HYBRID]',
          forceBackButton: true,
        ),
        body: Container(
          color: Colors.red.shade100,
          alignment: Alignment.center,
          child: const Text(
            'DEBUG: BODY AREA VISIBLE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.red),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Center(
              child: SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: _nameCtrl.text.trim().isNotEmpty ? _submit : null,
                  icon: const Icon(Icons.save),
                  label: Text(widget.initial == null ? 'Save' : 'Update'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
