// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class SuppliesPage extends StatefulWidget {
  const SuppliesPage({super.key});
  @override
  State<SuppliesPage> createState() => _SuppliesPageState();
}

enum _SuppliesView { list, compact, large }

enum _SuppliesSortBy { name, stock, expiry }

enum _SuppliesFilterBy { all, lowStock, expiringSoon }

class _SuppliesPageState extends State<SuppliesPage> {
  _SuppliesView _view = _SuppliesView.large;
  _SuppliesSortBy _sortBy = _SuppliesSortBy.name;
  _SuppliesFilterBy _filterBy = _SuppliesFilterBy.all;
  String _query = '';
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedView();
  }

  Future<void> _loadSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('supplies_list_view') ?? 'large';
    setState(() {
      _view = _SuppliesView.values.firstWhere(
        (v) => v.name == saved,
        orElse: () => _SuppliesView.large,
      );
    });
  }

  Future<void> _saveView(_SuppliesView v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supplies_list_view', v.name);
    setState(() => _view = v);
  }

  void _cycleView() {
    final order = [
      _SuppliesView.large,
      _SuppliesView.compact,
      _SuppliesView.list,
    ];
    final idx = order.indexOf(_view);
    final next = order[(idx + 1) % order.length];
    _saveView(next);
  }

  @override
  Widget build(BuildContext context) {
    final suppliesBox = Hive.box<Supply>(SupplyRepository.suppliesBoxName);
    final movementsBox = Hive.box<StockMovement>(
      SupplyRepository.movementsBoxName,
    );

    return Scaffold(
      appBar: const GradientAppBar(title: 'Supplies', forceBackButton: true),
      body: ValueListenableBuilder(
        valueListenable: suppliesBox.listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: movementsBox.listenable(),
            builder: (context, __, ___) {
              final repo = SupplyRepository();
              var items = repo.allSupplies();

              // Search
              if (_query.isNotEmpty) {
                items = items
                    .where(
                      (s) =>
                          s.name.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList();
              }
              // Filter
              switch (_filterBy) {
                case _SuppliesFilterBy.all:
                  break;
                case _SuppliesFilterBy.lowStock:
                  items = items.where(repo.isLowStock).toList();
                case _SuppliesFilterBy.expiringSoon:
                  final soon = DateTime.now().add(const Duration(days: 30));
                  items = items
                      .where(
                        (s) => s.expiry != null && s.expiry!.isBefore(soon),
                      )
                      .toList();
              }
              // Sort
              items.sort((a, b) {
                switch (_sortBy) {
                  case _SuppliesSortBy.name:
                    return a.name.compareTo(b.name);
                  case _SuppliesSortBy.stock:
                    final ca = repo.currentStock(a.id);
                    final cb = repo.currentStock(b.id);
                    return ca.compareTo(cb);
                  case _SuppliesSortBy.expiry:
                    final ea = a.expiry ?? DateTime(2100);
                    final eb = b.expiry ?? DateTime(2100);
                    return ea.compareTo(eb);
                }
              });

              if (items.isEmpty) {
                return Column(
                  children: [
                    _buildToolbar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Add your first supply to begin tracking',
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context.push('/supplies/add'),
                              child: const Text('Add Supply'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildToolbar(context),
                  Expanded(child: _buildSupplyList(context, items, repo)),
                ],
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

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (_searchExpanded)
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search supplies',
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _searchExpanded = false;
                      _query = '';
                    }),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: Colors.grey.shade400),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search supplies',
            ),

          if (_searchExpanded) const SizedBox(width: 8),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: Colors.grey.shade400),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),

          if (!_searchExpanded) const Spacer(),
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: Colors.grey.shade400),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const SizedBox(width: 8),

          if (!_searchExpanded)
            PopupMenuButton<_SuppliesFilterBy>(
              icon: Icon(
                Icons.filter_list,
                color: _filterBy != _SuppliesFilterBy.all
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
              ),
              tooltip: 'Filter supplies',
              onSelected: (f) => setState(() => _filterBy = f),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SuppliesFilterBy.all,
                  child: Text('All supplies'),
                ),
                PopupMenuItem(
                  value: _SuppliesFilterBy.lowStock,
                  child: Text('Low stock'),
                ),
                PopupMenuItem(
                  value: _SuppliesFilterBy.expiringSoon,
                  child: Text('Expiring soon'),
                ),
              ],
            ),

          if (!_searchExpanded)
            PopupMenuButton<_SuppliesSortBy>(
              icon: Icon(Icons.sort, color: Colors.grey.shade400),
              tooltip: 'Sort supplies',
              onSelected: (s) => setState(() => _sortBy = s),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _SuppliesSortBy.name,
                  child: Text('Sort by name'),
                ),
                PopupMenuItem(
                  value: _SuppliesSortBy.stock,
                  child: Text('Sort by stock'),
                ),
                PopupMenuItem(
                  value: _SuppliesSortBy.expiry,
                  child: Text('Sort by expiry'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getViewIcon(_SuppliesView v) {
    switch (v) {
      case _SuppliesView.list:
        return Icons.view_list;
      case _SuppliesView.compact:
        return Icons.view_comfy_alt;
      case _SuppliesView.large:
        return Icons.view_comfortable;
    }
  }

  Widget _buildSupplyList(
    BuildContext context,
    List<Supply> items,
    SupplyRepository repo,
  ) {
    switch (_view) {
      case _SuppliesView.list:
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = items[i];
            final cur = repo.currentStock(s.id);
            final low = repo.isLowStock(s);
            return ListTile(
              title: Text(
                s.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      _stockLine(s, cur),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _stockColor(context, s, cur),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (s.expiry != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatDdMm(s.expiry!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: low
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              leading: Icon(
                low ? Icons.warning_amber_rounded : Icons.inventory_2,
                color: low ? Colors.orange : null,
              ),
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => StockAdjustSheet(supply: s),
                );
              },
            );
          },
        );
      case _SuppliesView.compact:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 4
                : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              _SupplyCard(s: items[i], repo: repo, dense: true),
        );
      case _SuppliesView.large:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
            childAspectRatio: 2.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              _SupplyCard(s: items[i], repo: repo, dense: false),
        );
    }
  }

  String _formatDdMm(DateTime d) => DateFormat('dd/MM').format(d);

  String _stockLine(Supply s, double cur) {
    final unit = _unitLabel(s.unit);
    if (s.reorderThreshold != null && s.reorderThreshold! > 0) {
      final total = s.reorderThreshold!;
      return '${cur.toStringAsFixed(0)}/${total.toStringAsFixed(0)} $unit';
    }
    return '${cur.toStringAsFixed(0)} $unit';
  }

  Color _stockColor(BuildContext context, Supply s, double cur) {
    final theme = Theme.of(context);
    if (s.reorderThreshold != null && s.reorderThreshold! > 0) {
      final pct = (cur / s.reorderThreshold!).clamp(0.0, 1.0);
      if (pct <= 0.2) return theme.colorScheme.error;
      if (pct <= 0.5) return Colors.orange;
      return theme.colorScheme.primary;
    }
    if (SupplyRepository().isLowStock(s)) return theme.colorScheme.error;
    return theme.colorScheme.onSurface;
  }

  String _unitLabel(SupplyUnit u) => switch (u) {
    SupplyUnit.pcs => 'pcs',
    SupplyUnit.ml => 'mL',
    SupplyUnit.l => 'L',
  };
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.s, required this.repo, required this.dense});
  final Supply s;
  final SupplyRepository repo;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = repo.currentStock(s.id);
    final low = repo.isLowStock(s);

    return Card(
      elevation: dense ? 1 : 2,
      child: InkWell(
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (_) => StockAdjustSheet(supply: s),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: dense
                  ? const EdgeInsets.fromLTRB(6, 6, 6, 6)
                  : const EdgeInsets.fromLTRB(8, 8, 8, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!dense)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: dense ? 24 : 36,
                          height: dense ? 24 : 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.tertiaryContainer,
                                theme.colorScheme.tertiary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(dense ? 8 : 12),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: dense
                                    ? theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )
                                    : theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!dense &&
                                  (s.category?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 2),
                                Text(
                                  s.category!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (low)
                              Icon(
                                Icons.warning,
                                size: dense ? 12 : 14,
                                color: theme.colorScheme.error,
                              ),
                            if (!dense && s.expiry != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('dd/MM/yy').format(s.expiry!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: low
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (dense)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _stockLine(s, cur),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _stockColor(context, s, cur),
                                    height: 1,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (s.expiry != null)
                                Text(
                                  DateFormat('d/M').format(s.expiry!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      _stockLine(s, cur),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _stockColor(context, s, cur),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (!dense)
              Positioned(
                bottom: 8,
                right: 8,
                child: TextButton(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => StockAdjustSheet(supply: s),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    minimumSize: const Size(0, 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Adjust'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _stockLine(Supply s, double cur) {
    final unit = switch (s.unit) {
      SupplyUnit.pcs => 'pcs',
      SupplyUnit.ml => 'mL',
      SupplyUnit.l => 'L',
    };
    if (s.reorderThreshold != null && s.reorderThreshold! > 0) {
      final total = s.reorderThreshold!;
      return '${cur.toStringAsFixed(0)}/${total.toStringAsFixed(0)} $unit';
    }
    return '${cur.toStringAsFixed(0)} $unit';
  }

  Color _stockColor(BuildContext context, Supply s, double cur) {
    final theme = Theme.of(context);
    if (s.reorderThreshold != null && s.reorderThreshold! > 0) {
      final pct = (cur / s.reorderThreshold!).clamp(0.0, 1.0);
      if (pct <= 0.2) return theme.colorScheme.error;
      if (pct <= 0.5) return Colors.orange;
      return theme.colorScheme.primary;
    }
    if (repo.isLowStock(s)) return theme.colorScheme.error;
    return theme.colorScheme.onSurface;
  }
}

class AddEditSupplyPage extends StatefulWidget {
  const AddEditSupplyPage({super.key, this.initial});
  final Supply? initial;

  @override
  State<AddEditSupplyPage> createState() => _AddEditSupplyPageState();
}

class _AddEditSupplyPageState extends State<AddEditSupplyPage> {
  Widget _qtyBtn(BuildContext context, String label, VoidCallback onTap) {
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }

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
    final id =
        widget.initial?.id ??
        (DateTime.now().microsecondsSinceEpoch.toString() +
            Random().nextInt(9999).toString().padLeft(4, '0'));
    final s = Supply(
      id: id,
      name: _name.text.trim(),
      type: _type,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      unit: _unit,
      reorderThreshold: _threshold.text.trim().isEmpty
          ? null
          : double.parse(_threshold.text.trim()),
      expiry: _expiry,
      storageLocation: _storage.text.trim().isEmpty
          ? null
          : _storage.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    final repo = SupplyRepository();
    await repo.upsert(s);

    // If creating new and initial quantity > 0, add a purchase movement
    if (widget.initial == null) {
      final init = double.tryParse(_initialQty.text.trim()) ?? 0;
      if (init > 0) {
        final m = StockMovement(
          id: '${DateTime.now().microsecondsSinceEpoch}_init',
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
      appBar: GradientAppBar(
        title: widget.initial == null ? 'Add Supply' : 'Edit Supply',
        forceBackButton: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // General card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SupplyType>(
                    initialValue: _type,
                    items: const [
                      DropdownMenuItem(
                        value: SupplyType.item,
                        child: Text('Item'),
                      ),
                      DropdownMenuItem(
                        value: SupplyType.fluid,
                        child: Text('Fluid'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                    decoration: const InputDecoration(labelText: 'Type *'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category (optional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Inventory card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SupplyUnit>(
                          initialValue: _unit,
                          items: const [
                            DropdownMenuItem(
                              value: SupplyUnit.pcs,
                              child: Text('pcs'),
                            ),
                            DropdownMenuItem(
                              value: SupplyUnit.ml,
                              child: Text('mL'),
                            ),
                            DropdownMenuItem(
                              value: SupplyUnit.l,
                              child: Text('L'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _unit = v!),
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.initial == null)
                        Row(
                          children: [
                            _qtyBtn(context, '−', () {
                              final v = double.tryParse(_initialQty.text) ?? 0;
                              final nv = (v - 1).clamp(0, 1e12);
                              setState(
                                () => _initialQty.text = nv.toStringAsFixed(0),
                              );
                            }),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: _initialQty,
                                textAlign: TextAlign.center,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Initial qty',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _qtyBtn(context, '+', () {
                              final v = double.tryParse(_initialQty.text) ?? 0;
                              final nv = v + 1;
                              setState(
                                () => _initialQty.text = nv.toStringAsFixed(0),
                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _threshold,
                    decoration: const InputDecoration(
                      labelText: 'Low stock threshold (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Storage/Notes card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage / Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry'),
                    subtitle: Text(
                      _expiry == null
                          ? 'No expiry'
                          : _expiry!.toLocal().toString(),
                    ),
                    trailing: TextButton(
                      onPressed: _pickExpiry,
                      child: const Text('Pick'),
                    ),
                  ),
                  TextFormField(
                    controller: _storage,
                    decoration: const InputDecoration(
                      labelText: 'Storage / Lot (optional)',
                    ),
                  ),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockAdjustSheet extends StatefulWidget {
  const StockAdjustSheet({required this.supply, super.key});
  final Supply supply;

  @override
  State<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<StockAdjustSheet> {
  final _amount = TextEditingController(text: '1');
  MovementReason _reason = MovementReason.used;
  final _note = TextEditingController();

  // Local qty button helper to match the unified square +/- style
  Widget _qtyBtn(BuildContext context, String label, VoidCallback onTap) {
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
          Text(
            'Adjust stock: ${widget.supply.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _qtyBtn(context, '−', () {
                final v = double.tryParse(_amount.text) ?? 0;
                final nv = (v - 1).clamp(0, 1e12);
                setState(() => _amount.text = nv.toStringAsFixed(0));
              }),
              const SizedBox(width: 6),
              SizedBox(
                width: 96,
                child: TextFormField(
                  controller: _amount,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _qtyBtn(context, '+', () {
                final v = double.tryParse(_amount.text) ?? 0;
                final nv = v + 1;
                setState(() => _amount.text = nv.toStringAsFixed(0));
              }),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<MovementReason>(
                  isExpanded: true,
                  alignment: AlignmentDirectional.center,
                  initialValue: _reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MovementReason.used,
                      child: Text('Used'),
                    ),
                    DropdownMenuItem(
                      value: MovementReason.purchase,
                      child: Text('Purchase/Add'),
                    ),
                    DropdownMenuItem(
                      value: MovementReason.correction,
                      child: Text('Correction'),
                    ),
                    DropdownMenuItem(
                      value: MovementReason.other,
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _reason = v!),
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
