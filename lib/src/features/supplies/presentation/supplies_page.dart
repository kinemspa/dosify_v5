// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/utils/id.dart';
import 'package:dosifi_v5/src/features/supplies/data/supply_repository.dart';
import 'package:dosifi_v5/src/features/supplies/domain/stock_movement.dart';
import 'package:dosifi_v5/src/features/supplies/domain/supply.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:dosifi_v5/src/widgets/unified_empty_state.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

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
                        child: UnifiedEmptyState(
                          icon: Icons.inventory_2,
                          title: 'Add your first supply to begin tracking',
                          actionLabel: 'Add Supply',
                          onAction: () => context.push('/supplies/add'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supplies/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Supply'),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: kCompactToolbarPadding,
      child: Row(
        children: [
          if (_searchExpanded)
            Expanded(
              child: Field36(
                child: TextField(
                  autofocus: true,
                  textCapitalization: kTextCapitalizationDefault,
                  decoration: buildFieldDecoration(
                    context,
                    hint: 'Search supplies',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _searchExpanded = false;
                        _query = '';
                      }),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: mutedIconColor(context)),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search supplies',
            ),

          if (_searchExpanded) const SizedBox(width: kSpacingS),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: mutedIconColor(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),

          if (!_searchExpanded) const Spacer(),
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: mutedIconColor(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const SizedBox(width: kSpacingS),

          if (!_searchExpanded)
            PopupMenuButton<_SuppliesFilterBy>(
              icon: Icon(
                Icons.filter_list,
                color: _filterBy != _SuppliesFilterBy.all
                    ? Theme.of(context).colorScheme.primary
                    : mutedIconColor(context),
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
              icon: Icon(Icons.sort, color: mutedIconColor(context)),
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
          padding: kPagePadding,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = items[i];
            final cur = repo.currentStock(s.id);
            final low = repo.isLowStock(s);
            return ListTile(
              title: Text(s.name, style: cardTitleStyle(context)),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      _stockLine(s, cur),
                      style: helperTextStyle(
                        context,
                        color: _stockColor(context, s, cur),
                      )?.copyWith(fontWeight: kFontWeightSemiBold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (s.expiry != null) ...[
                    const SizedBox(width: kSpacingS),
                    Text(
                      _formatDdMm(s.expiry!),
                      style: helperTextStyle(
                        context,
                        color: low
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              leading: Icon(
                low ? Icons.warning_amber_rounded : Icons.inventory_2,
                color: low ? Theme.of(context).colorScheme.secondary : null,
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
          padding: kPagePadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 4
                : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: kSpacingS,
            mainAxisSpacing: kSpacingS,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              _SupplyCard(s: items[i], repo: repo, dense: true),
        );
      case _SuppliesView.large:
        return GridView.builder(
          padding: kPagePadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
            childAspectRatio: 2.35,
            crossAxisSpacing: kSpacingM,
            mainAxisSpacing: kSpacingM,
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
      return stockStatusColorFromRatio(context, pct);
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

    Future<void> openAdjustSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => StockAdjustSheet(supply: s),
      );
    }

    return Card(
      elevation: dense ? kElevationNone : kElevationLow,
      child: InkWell(
        onTap: openAdjustSheet,
        child: Padding(
          padding: dense ? kCompactCardPadding : kStandardCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!dense)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: kScheduleWizardSummaryIconSize,
                      height: kScheduleWizardSummaryIconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.tertiaryContainer,
                            theme.colorScheme.tertiary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: kStandardBorderRadius,
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: theme.colorScheme.onTertiary,
                      ),
                    ),
                    const SizedBox(width: kSpacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: cardTitleStyle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (s.category?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: kSpacingXXS),
                            Text(
                              s.category!,
                              style: microHelperTextStyle(
                                context,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: kOpacityMediumHigh),
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
                            size: kIconSizeXSmall,
                            color: theme.colorScheme.error,
                          ),
                        if (s.expiry != null) ...[
                          const SizedBox(height: kFieldSpacing),
                          Text(
                            DateFormat('dd/MM/yy').format(s.expiry!),
                            style: smallHelperTextStyle(
                              context,
                              color: low
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

              if (!dense) const SizedBox(height: kSpacingXS),

              if (dense) ...[
                Text(
                  s.name,
                  style: bodyTextStyle(context)?.copyWith(
                    fontWeight: kFontWeightBold,
                    height: kLineHeightTight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kSpacingXXS),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _stockLine(s, cur),
                        style: microHelperTextStyle(
                          context,
                          color: _stockColor(context, s, cur),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.expiry != null)
                      Text(
                        DateFormat('d/M').format(s.expiry!),
                        style: microHelperTextStyle(
                          context,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: kOpacityMediumHigh,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                Text(
                  _stockLine(s, cur),
                  style: helperTextStyle(
                    context,
                    color: _stockColor(context, s, cur),
                  )?.copyWith(fontWeight: kFontWeightSemiBold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (!dense) const Spacer(),
              if (!dense)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: openAdjustSheet,
                    style: TextButton.styleFrom(
                      padding: kTightTextButtonPadding,
                      minimumSize: Size.zero,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Adjust'),
                  ),
                ),
            ],
          ),
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
      return stockStatusColorFromRatio(context, pct);
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
    final id = widget.initial?.id ?? IdGen.newId(prefix: 'sup');
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
          id: IdGen.newId(prefix: 'supmv'),
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
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: kPagePaddingNoBottom,
          children: [
            SectionFormCard(
              title: 'General',
              children: [
                Field36(
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: kTextCapitalizationDefault,
                    decoration: buildFieldDecoration(context, label: 'Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Field36(
                  child: DropdownButtonFormField<SupplyType>(
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
                    decoration: buildFieldDecoration(context, label: 'Type *'),
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Field36(
                  child: TextFormField(
                    controller: _category,
                    textCapitalization: kTextCapitalizationDefault,
                    decoration: buildFieldDecoration(
                      context,
                      label: 'Category (optional)',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: kSpacingM),

            SectionFormCard(
              title: 'Inventory',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Field36(
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
                          decoration: buildFieldDecoration(
                            context,
                            label: 'Unit *',
                          ),
                        ),
                      ),
                    ),
                    if (widget.initial == null) ...[
                      const SizedBox(width: kSpacingM),
                      StepperRow36(
                        controller: _initialQty,
                        fixedFieldWidth: kSmallControlWidth,
                        decoration: buildFieldDecoration(
                          context,
                          label: 'Initial qty',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onDec: () {
                          final v = double.tryParse(_initialQty.text) ?? 0;
                          final nv = (v - 1).clamp(0, 1e12);
                          setState(
                            () => _initialQty.text = nv.toStringAsFixed(0),
                          );
                        },
                        onInc: () {
                          final v = double.tryParse(_initialQty.text) ?? 0;
                          final nv = v + 1;
                          setState(
                            () => _initialQty.text = nv.toStringAsFixed(0),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: kSpacingS),
                Field36(
                  child: TextFormField(
                    controller: _threshold,
                    decoration: buildFieldDecoration(
                      context,
                      label: 'Low stock threshold (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: kSpacingM),

            SectionFormCard(
              title: 'Storage / Notes',
              children: [
                ListTile(
                  contentPadding: kNoPadding,
                  title: const Text('Expiry'),
                  subtitle: Text(
                    _expiry == null
                        ? 'No expiry'
                        : DateFormat.yMMMd().format(_expiry!),
                  ),
                  trailing: TextButton(
                    onPressed: _pickExpiry,
                    child: const Text('Pick'),
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Field36(
                  child: TextFormField(
                    controller: _storage,
                    textCapitalization: kTextCapitalizationDefault,
                    decoration: buildFieldDecoration(
                      context,
                      label: 'Storage / Lot (optional)',
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingS),
                Field36(
                  child: TextFormField(
                    controller: _notes,
                    textCapitalization: kTextCapitalizationDefault,
                    decoration: buildFieldDecoration(
                      context,
                      label: 'Notes (optional)',
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
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
      id: IdGen.newId(prefix: 'supmv'),
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
      padding: buildBottomSheetPagePadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adjust stock: ${widget.supply.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: kSpacingM),
          Row(
            children: [
              StepperRow36(
                controller: _amount,
                fixedFieldWidth: kSmallControlWidth,
                decoration: buildFieldDecoration(context, label: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onDec: () {
                  final v = double.tryParse(_amount.text) ?? 0;
                  final nv = (v - 1).clamp(0, 1e12);
                  setState(() => _amount.text = nv.toStringAsFixed(0));
                },
                onInc: () {
                  final v = double.tryParse(_amount.text) ?? 0;
                  final nv = v + 1;
                  setState(() => _amount.text = nv.toStringAsFixed(0));
                },
              ),
              const SizedBox(width: kSpacingM),
              Expanded(
                child: Field36(
                  child: DropdownButtonFormField<MovementReason>(
                    isExpanded: true,
                    alignment: AlignmentDirectional.center,
                    initialValue: _reason,
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
                    decoration: buildFieldDecoration(context, label: 'Reason'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingS),
          Field36(
            child: TextFormField(
              controller: _note,
              textCapitalization: kTextCapitalizationDefault,
              decoration: buildFieldDecoration(
                context,
                label: 'Note (optional)',
              ),
            ),
          ),
          const SizedBox(height: kSpacingM),
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
          const SizedBox(height: kSpacingM),
        ],
      ),
    );
  }
}
