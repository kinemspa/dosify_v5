// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';

enum _MedView { list, compact, large }

enum _SortBy { name, stock, strength, expiry }

enum _FilterBy { all, lowStock, expiringSoon, refrigerated }

class MedicationListPage extends ConsumerStatefulWidget {
  const MedicationListPage({super.key});

  @override
  ConsumerState<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends ConsumerState<MedicationListPage> {
  _MedView _view = _MedView.large; // Default to large cards
  _SortBy _sortBy = _SortBy.name;
  bool _sortAsc = true;
  _FilterBy _filterBy = _FilterBy.all;
  String _query = '';
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedView();
  }

  Future<void> _loadSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    final savedView = prefs.getString('medication_list_view') ?? 'large';
    setState(() {
      _view = _MedView.values.firstWhere(
        (v) => v.name == savedView,
        orElse: () => _MedView.large,
      );
    });
  }

  Future<void> _saveView(_MedView view) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medication_list_view', view.name);
    setState(() => _view = view);
  }

  // Ensure we have an original stock value for count-based units so that we can
  // display Remaining / Original correctly. This sets it lazily to the first
  // observed value and updates it when the current stock increases (restock).
  void _ensureInitialStockValues(List<Medication> items) {
    final box = Hive.box<Medication>('medications');
    for (final m in items) {
      final isCountUnit =
          m.stockUnit == StockUnit.preFilledSyringes ||
          m.stockUnit == StockUnit.singleDoseVials ||
          m.stockUnit == StockUnit.multiDoseVials ||
          m.stockUnit == StockUnit.tablets ||
          m.stockUnit == StockUnit.capsules;
      if (!isCountUnit) continue;
      final cur = m.stockValue;
      final init = m.initialStockValue;
      var nextInit = init;
      if (init == null || init <= 0) {
        nextInit = cur;
      } else if (cur > init) {
        nextInit = cur; // treat as restock
      }
      if (nextInit != init) {
        final updated = m.copyWith(initialStockValue: nextInit);
        box.put(updated.id, updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Medications', forceBackButton: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> b, _) {
          final items = _getFilteredAndSortedMedications(
            b.values.toList(growable: false),
          );
          // Ensure initial stock values so large cards can show current/initial remain
          _ensureInitialStockValues(items);

          // Show initial state if no medications at all, or filtered state if search has no results
          if (items.isEmpty) {
            if (_query.isEmpty && b.values.isEmpty) {
              // No medications at all - show initial state
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medication, size: 48),
                    const SizedBox(height: 12),
                    const Text('Add a medication to begin tracking'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/medications/select-type'),
                      child: const Text('Add Medication'),
                    ),
                  ],
                ),
              );
            } else {
              // Search has no results - show search state
              return Column(
                children: [
                  _buildToolbar(context),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 48),
                          const SizedBox(height: 12),
                          Text('No medications found for "$_query"'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _query = '';
                              _searchExpanded = false;
                            }),
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }
          return Stack(
            children: [
              _buildMedList(context, items),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildToolbar(context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/select-type'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          // Search section - expands to layout button when activated
          if (_searchExpanded)
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: kTextLighterGrey(context),
                    ),
                    hintText: 'Search medications',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      iconSize: 20,
                      icon: Icon(Icons.close, color: kTextLighterGrey(context)),
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
              icon: Icon(Icons.search, color: kTextLighterGrey(context)),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search medications',
            ),
          // When search is expanded, only show layout button
          if (_searchExpanded) const SizedBox(width: 8),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: kTextLighterGrey(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),

          // Layout toggle as popup menu
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: kTextLighterGrey(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),

          if (!_searchExpanded) const SizedBox(width: 8),

          // Filter button
          if (!_searchExpanded)
            PopupMenuButton<_FilterBy>(
              icon: Icon(
                Icons.filter_list,
                color: _filterBy != _FilterBy.all
                    ? Theme.of(context).colorScheme.primary
                    : kTextLighterGrey(context),
              ),
              tooltip: 'Filter medications',
              onSelected: (filter) => setState(() => _filterBy = filter),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _FilterBy.all,
                  child: Text('All medications'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.lowStock,
                  child: Text('Low stock'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.expiringSoon,
                  child: Text('Expiring soon'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.refrigerated,
                  child: Text('Refrigerated'),
                ),
              ],
            ),

          // Sort button
          if (!_searchExpanded)
            PopupMenuButton<Object>(
              icon: Icon(Icons.sort, color: kTextLighterGrey(context)),
              tooltip: 'Sort medications',
              onSelected: (value) => setState(() {
                if (value is _SortBy) {
                  _sortBy = value;
                } else if (value == 'toggle_dir') {
                  _sortAsc = !_sortAsc;
                }
              }),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _SortBy.name,
                  child: Text('Sort by name'),
                ),
                const PopupMenuItem(
                  value: _SortBy.stock,
                  child: Text('Sort by stock'),
                ),
                const PopupMenuItem(
                  value: _SortBy.strength,
                  child: Text('Sort by strength'),
                ),
                const PopupMenuItem(
                  value: _SortBy.expiry,
                  child: Text('Sort by expiry'),
                ),
                PopupMenuItem(
                  value: 'toggle_dir',
                  child: Row(
                    children: [
                      Icon(
                        _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_sortAsc ? 'Ascending' : 'Descending'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Medication> _getFilteredAndSortedMedications(
    List<Medication> medications,
  ) {
    var items = List<Medication>.from(medications);

    // Apply search filter
    if (_query.isNotEmpty) {
      items = items
          .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    // Apply category filter
    switch (_filterBy) {
      case _FilterBy.all:
        break;
      case _FilterBy.lowStock:
        items = items
            .where(
              (m) =>
                  m.lowStockEnabled &&
                  m.stockValue <= (m.lowStockThreshold ?? 0),
            )
            .toList();
      case _FilterBy.expiringSoon:
        final now = DateTime.now();
        final soon = now.add(const Duration(days: 30));
        items = items
            .where((m) => m.expiry != null && m.expiry!.isBefore(soon))
            .toList();
      case _FilterBy.refrigerated:
        items = items.where((m) => m.requiresRefrigeration == true).toList();
    }

    // Apply sorting
    int dir(int v) => _sortAsc ? v : -v;
    switch (_sortBy) {
      case _SortBy.name:
        items.sort((a, b) => dir(a.name.compareTo(b.name)));
      case _SortBy.stock:
        items.sort((a, b) => dir(a.stockValue.compareTo(b.stockValue)));
      case _SortBy.strength:
        items.sort((a, b) => dir(a.strengthValue.compareTo(b.strengthValue)));
      case _SortBy.expiry:
        items.sort((a, b) {
          if (a.expiry == null && b.expiry == null) return 0;
          if (a.expiry == null) return dir(1);
          if (b.expiry == null) return dir(-1);
          return dir(a.expiry!.compareTo(b.expiry!));
        });
    }

    return items;
  }

  IconData _getViewIcon(_MedView view) {
    switch (view) {
      case _MedView.list:
        return Icons.view_list;
      case _MedView.compact:
        return Icons.view_comfy_alt;
      case _MedView.large:
        return Icons.view_comfortable;
    }
  }

  Future<void> _cycleView() async {
    final order = [_MedView.large, _MedView.compact, _MedView.list];
    final idx = order.indexOf(_view);
    final next = order[(idx + 1) % order.length];
    await _saveView(next);
  }

  // Helpers for list view formatting (duplicated from card helpers)
  String _unitLabel(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'units';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'units/mL';
    }
  }

  String _formLabelPlural(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Tablets';
      case MedicationForm.capsule:
        return 'Capsules';
      case MedicationForm.prefilledSyringe:
        return 'Pre-Filled Syringes';
      case MedicationForm.singleDoseVial:
        return 'Single Dose Vials';
      case MedicationForm.multiDoseVial:
        return 'Multi Dose Vials';
    }
  }

  String _stockUnitLabel(StockUnit unit) {
    switch (unit) {
      case StockUnit.tablets:
        return 'tablets';
      case StockUnit.capsules:
        return 'capsules';
      case StockUnit.preFilledSyringes:
        return 'syringes';
      case StockUnit.singleDoseVials:
        return 'vials';
      case StockUnit.multiDoseVials:
        return 'vials';
      case StockUnit.mcg:
        return 'mcg';
      case StockUnit.mg:
        return 'mg';
      case StockUnit.g:
        return 'g';
    }
  }

  String _formatDateDdMm(DateTime d) => DateFormat('dd/MM').format(d);

  Color _stockStatusColorFor(BuildContext context, Medication m) {
    final theme = Theme.of(context);
    final baseline = m.lowStockThreshold;
    if (baseline != null && baseline > 0) {
      final pct = (m.stockValue / baseline).clamp(0.0, 1.0);
      if (pct <= 0.2) return theme.colorScheme.error;
      if (pct <= 0.5) return Colors.orange;
      return theme.colorScheme.primary;
    }
    if (m.lowStockEnabled && m.stockValue <= (m.lowStockThreshold ?? 0)) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface;
  }

  TextSpan _stockStatusTextSpanFor(BuildContext context, Medication m) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final isCountUnit =
        m.stockUnit == StockUnit.preFilledSyringes ||
        m.stockUnit == StockUnit.singleDoseVials ||
        m.stockUnit == StockUnit.multiDoseVials ||
        m.stockUnit == StockUnit.tablets ||
        m.stockUnit == StockUnit.capsules;
    if (isCountUnit) {
      final current = m.stockValue.floor();
      final total = (m.initialStockValue != null && m.initialStockValue! > 0)
          ? m.initialStockValue!.ceil()
          : current;
      final colored = _stockStatusColorFor(context, m);
      return TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '$current',
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(text: '/$total ${_stockUnitLabel(m.stockUnit)}'),
        ],
      );
    }
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(
          text: fmt2(m.stockValue),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _stockStatusColorFor(context, m),
          ),
        ),
        TextSpan(text: ' ${_stockUnitLabel(m.stockUnit)}'),
      ],
    );
  }

  Widget _buildMedList(BuildContext context, List<Medication> items) {
    switch (_view) {
      case _MedView.list:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = items[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              title: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: m.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    if (m.manufacturer?.isNotEmpty ?? false)
                      TextSpan(
                        text: '  •  ${m.manufacturer!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${fmt2(m.strengthValue)} ${_unitLabel(m.strengthUnit)} ${_formLabelPlural(m.form)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kTextLightGrey(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: _stockStatusTextSpanFor(context, m),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.expiry != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatDateDdMm(m.expiry!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      (m.expiry!.isBefore(
                                        DateTime.now().add(
                                          const Duration(days: 30),
                                        ),
                                      ))
                                      ? Theme.of(context).colorScheme.error
                                      : kTextLightGrey(context),
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => context.push('/medications/${m.id}'),
            );
          },
        );
      case _MedView.compact:
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 4
                : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
            childAspectRatio:
                2.1, // shorter tiles to reduce bottom empty space while avoiding overflow
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _MedCard(m: items[i], dense: true),
        );
      case _MedView.large:
        // Large view uses summary-style neutral cards.
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _MedCard(m: items[i], dense: false),
        );
    }
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({required this.m, required this.dense});
  final Medication m;
  final bool dense;

  TextSpan _stockSpan(BuildContext context) {
    // Count-based units show current/total unit
    final isCountUnit =
        m.stockUnit == StockUnit.preFilledSyringes ||
        m.stockUnit == StockUnit.singleDoseVials ||
        m.stockUnit == StockUnit.multiDoseVials ||
        m.stockUnit == StockUnit.tablets ||
        m.stockUnit == StockUnit.capsules;
    if (isCountUnit) {
      final current = m.stockValue.floor();
      final total = (m.initialStockValue != null && m.initialStockValue! > 0)
          ? m.initialStockValue!.ceil()
          : current;
      final colored = _stockStatusColor(Theme.of(context));
      return TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          height: 1,
          fontSize: 9,
        ),
        children: [
          TextSpan(
            text: '$current',
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(text: '/$total ${_getStockUnitLabel(m.stockUnit)}'),
        ],
      );
    }
    return TextSpan(
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        height: 1,
        fontSize: 9,
      ),
      children: [
        TextSpan(
          text: fmt2(m.stockValue),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _stockStatusColor(Theme.of(context)),
          ),
        ),
        TextSpan(text: ' ${_getStockUnitLabel(m.stockUnit)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!dense) {
      return GestureDetector(
        onTap: () => context.push('/medications/${m.id}'),
        child: SummaryHeaderCard.fromMedication(
          m,
          neutral: true,
          outlined: true,
        ),
      );
    }

    // Fallback: keep existing dense implementation
    final theme = Theme.of(context);
    final isExpiringSoon =
        m.expiry != null &&
        m.expiry!.isBefore(DateTime.now().add(const Duration(days: 30)));

    return Container(
      decoration: softWhiteCardDecoration(context),
      child: InkWell(
        onTap: () => context.push('/medications/${m.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              Text(
                m.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Expiry (trailing) without chip
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (m.expiry != null)
                    Text(
                      _formatDateDayMonth(m.expiry!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isExpiringSoon
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // Strength
              Text(
                '${fmt2(m.strengthValue)} ${_getUnitLabel(m.strengthUnit)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Stock
              RichText(
                text: _stockSpan(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUnitLabel(Unit unit) {
    switch (unit) {
      case Unit.mcg:
        return 'mcg';
      case Unit.mg:
        return 'mg';
      case Unit.g:
        return 'g';
      case Unit.units:
        return 'units';
      case Unit.mcgPerMl:
        return 'mcg/mL';
      case Unit.mgPerMl:
        return 'mg/mL';
      case Unit.gPerMl:
        return 'g/mL';
      case Unit.unitsPerMl:
        return 'units/mL';
    }
  }

  String _getStockUnitLabel(StockUnit unit) {
    switch (unit) {
      case StockUnit.tablets:
        return 'tablets';
      case StockUnit.capsules:
        return 'capsules';
      case StockUnit.preFilledSyringes:
        return 'syringes';
      case StockUnit.singleDoseVials:
        return 'vials';
      case StockUnit.multiDoseVials:
        return 'vials';
      case StockUnit.mcg:
        return 'mcg';
      case StockUnit.mg:
        return 'mg';
      case StockUnit.g:
        return 'g';
    }
  }

  String _formatDateDayMonth(DateTime d) => DateFormat('d/M').format(d);

  Color _stockStatusColor(ThemeData theme) {
    // Color by percentage of baseline when available
    final baseline = m.lowStockThreshold;
    if (baseline != null && baseline > 0) {
      final pct = (m.stockValue / baseline).clamp(0.0, 1.0);
      if (pct <= 0.2) return theme.colorScheme.error;
      if (pct <= 0.5) return Colors.orange;
      return theme.colorScheme.primary;
    }
    // Fall back to lowStock flag
    if (m.lowStockEnabled && m.stockValue <= (m.lowStockThreshold ?? 0)) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface;
  }
}
