import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format.dart';
import '../../../widgets/app_header.dart';
import '../domain/medication.dart';
import '../domain/enums.dart';
import '../../../widgets/summary_header_card.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

enum _MedView { list, compact, large }

enum _SortBy { name, stock, strength, expiry }

enum _FilterBy { all, lowStock, expiringSoon, refrigerated }

const double _kLargeCardHeight = 140.0;

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
      double? nextInit = init;
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
          var items = _getFilteredAndSortedMedications(
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
          return Column(
            children: [
              _buildToolbar(context),
              Expanded(child: _buildMedList(context, items)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Search section - expands to layout button when activated
          if (_searchExpanded)
            Expanded(
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search medications',
                  isDense: true,
                  // No background fill or borders in toolbar
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ).copyWith(
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
              icon: Icon(Icons.search, color: kTextLightGrey(context)),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search medications',
            ),

          // When search is expanded, only show layout button
          if (_searchExpanded) const SizedBox(width: 8),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: kTextLightGrey(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),

          // Layout toggle as popup menu
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: Colors.grey.shade400),
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
                    : kTextLightGrey(context),
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
              icon: Icon(Icons.sort, color: kTextLightGrey(context)),
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
                      Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
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
        break;
      case _FilterBy.expiringSoon:
        final now = DateTime.now();
        final soon = now.add(const Duration(days: 30));
        items = items
            .where((m) => m.expiry != null && m.expiry!.isBefore(soon))
            .toList();
        break;
      case _FilterBy.refrigerated:
        items = items.where((m) => m.requiresRefrigeration == true).toList();
        break;
    }

    // Apply sorting
    int dir(int v) => _sortAsc ? v : -v;
    switch (_sortBy) {
      case _SortBy.name:
        items.sort((a, b) => dir(a.name.compareTo(b.name)));
        break;
      case _SortBy.stock:
        items.sort((a, b) => dir(a.stockValue.compareTo(b.stockValue)));
        break;
      case _SortBy.strength:
        items.sort((a, b) => dir(a.strengthValue.compareTo(b.strengthValue)));
        break;
      case _SortBy.expiry:
        items.sort((a, b) {
          if (a.expiry == null && b.expiry == null) return 0;
          if (a.expiry == null) return dir(1);
          if (b.expiry == null) return dir(-1);
          return dir(a.expiry!.compareTo(b.expiry!));
        });
        break;
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

  // Icon per medication form for list tiles
  IconData _iconForForm(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication;
      case MedicationForm.capsule:
        return Icons.bubble_chart;
      case MedicationForm.injectionPreFilledSyringe:
        return Icons.vaccines;
      case MedicationForm.injectionSingleDoseVial:
        return Icons.biotech;
      case MedicationForm.injectionMultiDoseVial:
        return Icons.science;
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
      case MedicationForm.injectionPreFilledSyringe:
        return 'Pre-Filled Syringes';
      case MedicationForm.injectionSingleDoseVial:
        return 'Single Dose Vials';
      case MedicationForm.injectionMultiDoseVial:
        return 'Multi Dose Vials';
    }
  }

  String _stockStatusShortTextFor(Medication m) {
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
      return '$current/$total ${_stockUnitLabel(m.stockUnit)}';
    }
    return '${fmt2(m.stockValue)} ${_stockUnitLabel(m.stockUnit)}';
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

  String _formatDateDdMmYy(DateTime d) => DateFormat('dd/MM/yy').format(d);
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                    if (m.manufacturer?.isNotEmpty == true)
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final theme = Theme.of(context);
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
              height: 1.0,
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
            height: 1.0,
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
        child: Padding(
          padding: const EdgeInsets.all(8),
child: SummaryHeaderCard.fromMedication(m, neutral: true, outlined: true),
        ),
      );
    }

    // Fallback: keep existing dense implementation
    final theme = Theme.of(context);
    final isLowStock =
        m.lowStockEnabled && m.stockValue <= (m.lowStockThreshold ?? 0);
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
                  height: 1.0,
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
                        height: 1.0,
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
                  height: 1.0,
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

  String _getFormLabel(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Tablet';
      case MedicationForm.capsule:
        return 'Capsule';
      case MedicationForm.injectionPreFilledSyringe:
        return 'Pre-Filled Syringe';
      case MedicationForm.injectionSingleDoseVial:
        return 'Single Dose Vial';
      case MedicationForm.injectionMultiDoseVial:
        return 'Multi Dose Vial';
    }
  }

  // Plural label for strength line
  String _getFormLabelPlural(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Tablets';
      case MedicationForm.capsule:
        return 'Capsules';
      case MedicationForm.injectionPreFilledSyringe:
        return 'Pre-Filled Syringes';
      case MedicationForm.injectionSingleDoseVial:
        return 'Single Dose Vials';
      case MedicationForm.injectionMultiDoseVial:
        return 'Multi Dose Vials';
    }
  }

  // Abbreviated form label for dense tiles
  String _getFormAbbr(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Tab';
      case MedicationForm.capsule:
        return 'Cap';
      case MedicationForm.injectionPreFilledSyringe:
        return 'PFS';
      case MedicationForm.injectionSingleDoseVial:
        return 'SDV';
      case MedicationForm.injectionMultiDoseVial:
        return 'MDV';
    }
  }

  // Icon per medication form
  IconData _getFormIcon(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication;
case MedicationForm.capsule:
        return MdiIcons.pill;
      case MedicationForm.injectionPreFilledSyringe:
        return Icons.vaccines;
      case MedicationForm.injectionSingleDoseVial:
        return Icons.biotech;
      case MedicationForm.injectionMultiDoseVial:
        return Icons.science;
    }
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

  String _formatExpiryDate(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now).inDays;
    if (difference <= 0) return 'today';
    if (difference == 1) return 'tomorrow';
    if (difference <= 7) return 'in $difference days';
    return '${expiry.month}/${expiry.day}';
  }

  // Schedule summary single line with actions (all forms)
  Widget _buildScheduleLine(BuildContext context) {
    final theme = Theme.of(context);
    final box = Hive.box<Schedule>('schedules');
    final linked = box.values
        .where((s) => s.active && s.medicationId == m.id)
        .toList(growable: false);

    DateTime? next;
    DateTime? last;
    int? daysLeft;
    int? dosesLeft;

    final now = DateTime.now();
    // Next within 60 days
    for (final s in linked) {
      final times = s.timesOfDay ?? [s.minutesOfDay];
      for (int d = 0; d < 60; d++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: d));
        final onDay = s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
            ? (() {
                final anchor = s.cycleAnchorDate ?? now;
                final a = DateTime(anchor.year, anchor.month, anchor.day);
                final d0 = DateTime(date.year, date.month, date.day);
                final diff = d0.difference(a).inDays;
                return diff >= 0 && diff % s.cycleEveryNDays! == 0;
              })()
            : s.daysOfWeek.contains(date.weekday);
        if (onDay) {
          for (final minutes in times) {
            final dt = DateTime(
              date.year,
              date.month,
              date.day,
              minutes ~/ 60,
              minutes % 60,
            );
            if (dt.isAfter(now) && (next == null || dt.isBefore(next!)))
              next = dt;
          }
        }
      }
    }
    // Last within previous 60 days
    for (final s in linked) {
      final times = s.timesOfDay ?? [s.minutesOfDay];
      for (int d = 0; d < 60; d++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: d));
        final onDay = s.cycleEveryNDays != null && s.cycleEveryNDays! > 0
            ? (() {
                final anchor = s.cycleAnchorDate ?? now;
                final a = DateTime(anchor.year, anchor.month, anchor.day);
                final d0 = DateTime(date.year, date.month, date.day);
                final diff = d0.difference(a).inDays;
                return diff >= 0 && diff % s.cycleEveryNDays! == 0;
              })()
            : s.daysOfWeek.contains(date.weekday);
        if (onDay) {
          for (final minutes in times) {
            final dt = DateTime(
              date.year,
              date.month,
              date.day,
              minutes ~/ 60,
              minutes % 60,
            );
            if (dt.isBefore(now) && (last == null || dt.isAfter(last!)))
              last = dt;
          }
        }
      }
    }

    // Estimate daysLeft
    if (linked.isNotEmpty) {
      double occPerWeek = 0;
      for (final s in linked) {
        final times = (s.timesOfDay?.isNotEmpty == true)
            ? s.timesOfDay!.length
            : 1;
        if (s.cycleEveryNDays != null && s.cycleEveryNDays! > 0) {
          occPerWeek += (7 / s.cycleEveryNDays!) * times;
        } else {
          occPerWeek += s.daysOfWeek.length * times;
        }
      }
      if (occPerWeek > 0) {
        final dosePerOcc = 1.0; // heuristic for now (1 unit per occurrence)
        final dailyUse = (occPerWeek * dosePerOcc) / 7.0;
        if (dailyUse > 0) {
          daysLeft = (m.stockValue / dailyUse).floor();
          if (daysLeft < 1) daysLeft = 1;
          // For count-based units, estimate doses left ~ current stock
          final isCountUnit =
              m.stockUnit == StockUnit.tablets ||
              m.stockUnit == StockUnit.capsules ||
              m.stockUnit == StockUnit.preFilledSyringes ||
              m.stockUnit == StockUnit.singleDoseVials ||
              m.stockUnit == StockUnit.multiDoseVials;
          if (isCountUnit) {
            dosesLeft = m.stockValue.floor();
          }
        }
      }
    }

    String fmtWhen(DateTime dt) {
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final time = DateFormat('HH:mm').format(dt);
      if (isToday) return 'Today $time';
      final tomorrow = now.add(const Duration(days: 1));
      final isTomorrow =
          dt.year == tomorrow.year &&
          dt.month == tomorrow.month &&
          dt.day == tomorrow.day;
      if (isTomorrow) return 'Tomorrow $time';
      return DateFormat('dd MMM, HH:mm').format(dt);
    }

    String fmtDur(int d) {
      if (d < 14) return '$d days';
      final w = (d / 7).toStringAsFixed(1);
      return '$w weeks';
    }

    final lastStr = last != null ? fmtWhen(last!) : '—';
    final nextStr = next != null ? fmtWhen(next!) : '—';
    final lastsStr = daysLeft != null ? fmtDur(daysLeft!) : '—';

    final runOutDate = daysLeft != null
        ? DateFormat('dd MMM').format(now.add(Duration(days: daysLeft!)))
        : '—';
    final dosesStr = dosesLeft != null ? '~$dosesLeft left' : '~$lastsStr left';
    final summaryText = 'Last: $lastStr  •  Next: $nextStr';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        summaryText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: kTextLightGrey(context),
                  height: 1.0,
                ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Date format helpers (TODO: read from Settings later)
  String _formatDateDdMmYy(DateTime d) => DateFormat('dd/MM/yy').format(d);
  String _formatDateDayMonth(DateTime d) => DateFormat('d/M').format(d);

  // Stock status helpers
  String _stockStatusText() {
    // For count-based units, express as X out of Y remaining; Y = originally entered amount when available
    String baseUnit = _getStockUnitLabel(m.stockUnit);
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
          : current; // fallback to current if unknown
      return '$current/$total $baseUnit remaining';
    }
    return '${fmt2(m.stockValue)} $baseUnit remaining';
  }

  String _stockStatusShortText() {
    // Shorter form for dense tiles; Y = originally entered amount when available
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
      return '$current/$total ${_getStockUnitLabel(m.stockUnit)}';
    }
    return '${fmt2(m.stockValue)} ${_getStockUnitLabel(m.stockUnit)}';
  }

  Color _stockStatusColor(ThemeData theme) {
    // Color by percentage of baseline when available
    double? baseline = m.lowStockThreshold;
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

  Future<void> _onTake(BuildContext context) async {
    final box = Hive.box<Medication>('medications');
    // Decrement by 1 for count-based units; otherwise decrement by 1.0 generically
    final isCountUnit =
        m.stockUnit == StockUnit.tablets ||
        m.stockUnit == StockUnit.capsules ||
        m.stockUnit == StockUnit.preFilledSyringes ||
        m.stockUnit == StockUnit.singleDoseVials ||
        m.stockUnit == StockUnit.multiDoseVials;
    final dec = 1.0;
    final newValue = m.stockValue - dec;
    final updated = m.copyWith(stockValue: newValue < 0 ? 0 : newValue);
    await box.put(updated.id, updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recorded dose. Stock: ${newValue < 0 ? 0 : newValue} ${_getStockUnitLabel(m.stockUnit)}',
        ),
      ),
    );
  }

  void _onDoseAction(
    BuildContext context,
    String action,
    DateTime scheduledAt,
  ) {
    // Placeholder: integrate with schedules/logging later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${action[0].toUpperCase()}${action.substring(1)} dose @ ${DateFormat('dd MMM, HH:mm').format(scheduledAt)}',
        ),
      ),
    );
  }
}
