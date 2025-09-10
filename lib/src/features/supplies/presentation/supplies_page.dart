import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../domain/supply.dart';
import '../domain/stock_movement.dart';
import '../data/supply_repository.dart';

class SuppliesPage extends StatelessWidget {
  const SuppliesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final suppliesBox = Hive.box<Supply>(SupplyRepository.suppliesBoxName);
    final movementsBox = Hive.box<StockMovement>(SupplyRepository.movementsBoxName);

    return Scaffold(
      appBar: AppBar(title: const Text('Supplies')),
      body: ValueListenableBuilder(
        valueListenable: suppliesBox.listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: movementsBox.listenable(),
            builder: (context, __, ___) {
              final repo = SupplyRepository();
              final items = repo.allSupplies();
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2, size: 48),
                      const SizedBox(height: 12),
                      const Text('Add your first supply to begin tracking'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.push('/supplies/add'),
                        child: const Text('Add Supply'),
                      )
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = items[i];
                  final cur = repo.currentStock(s.id);
                  final low = repo.isLowStock(s);
                  final unit = _unitLabel(s.unit);
                  return ListTile(
                    title: Text(s.name),
                    subtitle: Text('Stock: ${cur.toStringAsFixed(2)} $unit' + (s.reorderThreshold != null ? ' • Low if ≤ ${s.reorderThreshold!.toStringAsFixed(2)} $unit' : '')),
                    leading: Icon(low ? Icons.warning_amber_rounded : Icons.inventory_2, color: low ? Colors.orange : null),
                    trailing: PopupMenuButton<String>(
                      onSelected: (choice) async {
                        if (choice == 'adjust') {
                          await showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            builder: (_) => StockAdjustSheet(supply: s),
                          );
                        } else if (choice == 'edit') {
                          context.push('/supplies/edit/${s.id}');
                        } else if (choice == 'delete') {
                          final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete supply?'),
                                  content: Text('Delete "${s.name}" and its movements?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                  ],
                                ),
                              ) ??
                              false;
                          if (ok) await SupplyRepository().delete(s.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'adjust', child: Text('Adjust stock')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (_) => StockAdjustSheet(supply: s),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/supplies/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _unitLabel(SupplyUnit u) => switch (u) {
        SupplyUnit.pcs => 'pcs',
        SupplyUnit.ml => 'mL',
        SupplyUnit.l => 'L',
      };
}

class AddEditSupplyPage extends StatefulWidget {
  const AddEditSupplyPage({super.key, this.initial});
  final Supply? initial;

  @override
  State<AddEditSupplyPage> createState() => _AddEditSupplyPageState();
}

class _AddEditSupplyPageState extends State<AddEditSupplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  SupplyType _type = SupplyType.item;
  final _category = TextEditingController();
  SupplyUnit _unit = SupplyUnit.pcs;
  final _threshold = TextEditingController();
  DateTime? _expiry;
  final _storage = TextEditingController();
  final _notes = TextEditingController();
  final _initialQty = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      _name.text = s.name;
      _type = s.type;
      _category.text = s.category ?? '';
      _unit = s.unit;
      _threshold.text = s.reorderThreshold?.toString() ?? '';
      _expiry = s.expiry;
      _storage.text = s.storageLocation ?? '';
      _notes.text = s.notes ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _threshold.dispose();
    _storage.dispose();
    _notes.dispose();
    _initialQty.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.initial?.id ?? (DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(9999).toString().padLeft(4, '0'));
    final s = Supply(
      id: id,
      name: _name.text.trim(),
      type: _type,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      unit: _unit,
      reorderThreshold: _threshold.text.trim().isEmpty ? null : double.parse(_threshold.text.trim()),
      expiry: _expiry,
      storageLocation: _storage.text.trim().isEmpty ? null : _storage.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    final repo = SupplyRepository();
    await repo.upsert(s);

    // If creating new and initial quantity > 0, add a purchase movement
    if (widget.initial == null) {
      final init = double.tryParse(_initialQty.text.trim()) ?? 0;
      if (init > 0) {
        final m = StockMovement(
          id: DateTime.now().microsecondsSinceEpoch.toString() + '_init',
          supplyId: id,
          delta: init,
          reason: MovementReason.purchase,
          note: 'Initial stock',
        );
        await repo.addMovement(m);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.initial == null ? 'Add Supply' : 'Edit Supply'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SupplyType>(
              value: _type,
              items: const [
                DropdownMenuItem(value: SupplyType.item, child: Text('Item')),
                DropdownMenuItem(value: SupplyType.fluid, child: Text('Fluid')),
              ],
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Type *'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category (optional)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SupplyUnit>(
              value: _unit,
              items: const [
                DropdownMenuItem(value: SupplyUnit.pcs, child: Text('pcs')),
                DropdownMenuItem(value: SupplyUnit.ml, child: Text('mL')),
                DropdownMenuItem(value: SupplyUnit.l, child: Text('L')),
              ],
              onChanged: (v) => setState(() => _unit = v!),
              decoration: const InputDecoration(labelText: 'Unit *'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _threshold,
              decoration: const InputDecoration(labelText: 'Low stock threshold (optional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry'),
              subtitle: Text(_expiry == null ? 'No expiry' : _expiry!.toLocal().toString()),
              trailing: TextButton(onPressed: _pickExpiry, child: const Text('Pick')),
            ),
            TextFormField(
              controller: _storage,
              decoration: const InputDecoration(labelText: 'Storage / Lot (optional)'),
            ),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            if (widget.initial == null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialQty,
                decoration: const InputDecoration(labelText: 'Initial quantity'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StockAdjustSheet extends StatefulWidget {
  const StockAdjustSheet({super.key, required this.supply});
  final Supply supply;

  @override
  State<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<StockAdjustSheet> {
  final _amount = TextEditingController(text: '1');
  MovementReason _reason = MovementReason.used;
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final val = double.tryParse(_amount.text.trim()) ?? 0;
    if (val == 0) return;
    final delta = (_reason == MovementReason.used) ? -val : val;
    final m = StockMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      supplyId: widget.supply.id,
      delta: delta,
      reason: _reason,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    await SupplyRepository().addMovement(m);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adjust stock: ${widget.supply.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<MovementReason>(
                value: _reason,
                items: const [
                  DropdownMenuItem(value: MovementReason.used, child: Text('Used')),
                  DropdownMenuItem(value: MovementReason.purchase, child: Text('Purchase/Add')),
                  DropdownMenuItem(value: MovementReason.correction, child: Text('Correction')),
                  DropdownMenuItem(value: MovementReason.other, child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _reason = v!),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton(onPressed: _apply, child: const Text('Apply')),
            ),
          ]),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

